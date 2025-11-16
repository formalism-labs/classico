
# require 'socket'
require 'tempfile'
require 'open3'
require 'shellwords'

module Bento

#----------------------------------------------------------------------------------------------

CommandLogFile = ENV["HOME"] + "/system.log"

class Command
	include Bento::Class
	
	members :fout, :ferr, :prog, :t0, :done, :status, :out, :err, :when_, :elapsed_sec, :where

	attr_reader :out, :err

	@@last_commands = Hash.new

	# options:
	# :nolog, :outlog, :errlog
	# :nop, :nonop
	def initialize(prog, *opt, at: nil)
		flags binding, [:nolog, :no_outlog, :no_errlog, :nop, :nonop, :async]

		@prog = prog

		nop = Bento.nop?(*opt)

		@no_outlog ||= false
		@no_outlog = true if @nolog
		@no_errlog ||= false
		@no_errlog = true if @nolog

		curdir = Dir.pwd

		@when_ = Time.now.strftime("%y-%m-%d %H:%M:%S")
		@where = Dir.pwd

		@fout = Tempfile.new('sysout.')
		@fout.close
		@ferr = Tempfile.new('syserr.')
		@ferr.close
		Dir.chdir(at) if at
		@t0 = Time.now
		if !nop
			_run
		else
			puts @prog
			@status = 0
		end
		Dir.chdir(curdir) if at

		if !@async
			_conclude
		else
			@done ||= false
		end

		@@last_commands[Thread.current.object_id] = self
	end

	def _run
		puts "#{@prog} 1> #{@fout.path} 2> #{@ferr.path}"
		@status = 0
	end

	def out0
		line = @out.first
		line == nil ? "" : line
	end

	def err0
		line = @err.first
		line == nil ? "" : line
	end

	def out_s
		@out.join("\n")
	end

	def err_s
		@err.join("\n")
	end

	def status
		@status
	end

	def failed?
		status != 0
	end

	def ok?
		status == 0
	end

	def pid
		@pid
	end

	def done?
		@done
	end
	
	def wait(timeout = nil)
	end

	def self.last
		@@last_commands[Thread.current.object_id]
	end

	def error!
		error "System.command(#{@prog}) failed" 
	end

private
	def _append(log, file)
		lines = []
		File.open(file.path) do |f|
			if log
				f.each_line do |line|
					log.write line
					lines << line.chomp
				end
			else
				f.each_line do |line|
					lines << line.chomp
				end
			end
		end
		file.close
		file.unlink
		return lines
	end

	def _append_to_log
		begin
			log = File.new(CommandLogFile, "a+")
			
			if @async || !@done
				log.puts "=== #{@when_} (-) [#{@where}]"
				log.puts @prog
				log.puts "--- (-)"
				log.close
			else
				log.puts "=== #{@when_} (#{@elapsed_sec}s) [#{@where}]"
				log.puts @prog
				log.puts "--- (#{status})"

				@out = _append(@no_outlog ? nil : log, @fout)
				log.puts "---"

				@err = _append(@no_errlog ? nil : log, @ferr)

				log.puts "---" if @ferr1
				@err1 = _append(@no_errlog ? nil : log, @ferr1) if @ferr1

				log.close
			end
		rescue IOError => x
			sleep 1 + rand
			retry
		end
	end

	def _conclude
		@elapsed_sec = Time.now - @t0
		@done = true

		if @nolog
			@out = _append(nil, @fout)
			@err = _append(nil, @ferr)
		else
			_append_to_log
		end
	end
	
#	def self.last_commands
#		@@last_commands = Hash.new if !@@last_commands
#	end

end

#----------------------------------------------------------------------------------------------

class CmdCommand < Command
	@@is_takecmd = (ENV["COMSPEC"] =~ /tcc\.exe/i) != nil

	def _run
		prefix = @@is_takecmd ? "cmd /c" : ""
		system("#{prefix}#{@prog} 1> #{@fout.path} 2> #{@ferr.path}")
		@status = $?.exitstatus
	end
end

#----------------------------------------------------------------------------------------------

class BashCommand < Command
	def _run
		if !@async
			system("bash", "-c", "#{@prog} 1> #{@fout.path} 2> #{@ferr.path}")
			@status = $?.exitstatus
		else
			@frc = Tempfile.new('sysrc.')
			@frc.close

			bashcmd = <<~END
				trap 'echo $? > #{@frc.path}' EXIT
				eval #{@prog}
				END

			out, pstat = Open3.capture2e('bash', '-c', <<~END)
				{ nohup /usr/bin/bash -c '#{bashcmd}' </dev/null 1> #{@fout.path} 2> #{@ferr.path} & }
				jobs -p
				disown
				END
			
			if pstat.exitstatus == 0
				@uxpid = out.to_i
				@pid = _winpid(@uxpid)
				@done = false
			else
				@pid = nil
				@status = -1
				@done = true
			end

			_append_to_log
		end
	end

	def done?
		return true if @done
		o, s = Open3.capture2e("bash", "-c", "[[ -d /proc/#{@uxpid} ]]")
		@done = s.exitstatus != 0
		@status = Bento.fread(@frc).to_i
		@frc.unlink
		_conclude if @done
		return @done
	end

	def _winpid(uxpid)
		o, s = Open3.capture2e("bash", "-c", "cat /proc/#{uxpid}/winpid")
		s.exitstatus == 0 ? o.to_i : nil
	end
end

#----------------------------------------------------------------------------------------------

class SSHBashCommand < Command

	def initialize(prog, *opt, user: nil, host: nil, at: nil)
		error "unknown host" if !host
		@host = host.to_s

		@user = !user ? Bento::System.user : user.to_s.downcase
		@r_at = at || ""

		super(prog, *opt)
	end

	# This is some delicate walk-on-thin-ice shit.
	# Bash is executed remotely, runs program and collects outputs and status.
	# Then, tar is packed and streamed back via ssh.
	# Upon arrival, outputs and are placed in temp files (just like in local Command).
	# First challenge: command can be interrupted on client (e.g., ctrl-c). All remote processes
	# should be killed. No good way to do this except by the following trick:
	# 1. client launches ssh in background from a coproc.
	# 2. Coproc then waits (read) for a termination message, upon which all processes from 
	#    the process group are killed (kill -$$).
	# 3. Main ssh script waits either for coproc termination (normal exit), or for an EXIT trap
	#    (on which coproc is signalled).
	# 4. Note that interrupting ssh on the client will lead to killing of ssh session on the server, 
	#    but will not kill all decendant processes. This is handled expcitly by this scheme.
	# Second challenge: since ssh stdin is taken by the termination message channel, the 
	# 'bash -s < <<END' heredoc trick cannot be used to nicely feed a script into ssh.
	# Instead, the heredoc is base64-encoded on the client and fed into ssh on its command line.
	# Notes:
	# - tar extract files with -m to avoid timestamp warnings
	# - The command to be executed (@prog) is stated verbatim in the base64-encoded text, so no 
	#   worries about quotes escaping.

	def _run
		cmdfile = Bento.tempfile(<<~ENDX)
			cmd64=$(base64 -w0 <<-'END'
				fbackd=$(mktemp -d /tmp/fback.XXXXXX)
				fout=$fbackd/out
				ferr=$fbackd/err
				frc=$fbackd/rc
				
				( [[ -z "#{@r_at}" ]] && cd "#{@r_at}"; eval #{@prog} ;) 1> $fout 2> $ferr
				rc=$?
				echo $rc > $frc
				tar cf - -C $fbackd out err rc
				[[ -d $fbackd ]] && rm -rf $fbackd 
				wait
				kill -- -$PPID >& /dev/null
				# echo 'done' >> /tmp/sshlog.1
			END
			)

			FBACKD=$(mktemp -d /tmp/fback.XXXXXX)

			coproc { \
				ssh -o StrictHostKeyChecking=no #{@user}@#{@host} "\
					bash -s < <(echo $cmd64 | base64 -d) & \
					read; \
					kill -- -\\$\\$ \
					" \
				| tar xf - -m -C $FBACKD \
			;}

			exec 2>/dev/null
			trap 'rm -rf $FBACKD; echo >&"${COPROC[1]}"' EXIT
			wait

			cp $FBACKD/out #{@fout.path}
			cp $FBACKD/err #{@ferr.path}
			rc=`cat $FBACKD/rc`
			[[ -d $FBACKD ]] && rm -rf $FBACKD
			exit $rc
			ENDX

		# puts Bento.fread(cmdfile)
		@ferr1 = Tempfile.new('syserr.')
		@ferr1.close

		# system("bash", "-c", ". #{cmdfile} >#{@ferr1.path} 2>&1")

		# executed with 'source' to avoid setting permissions of cmdfile
		system("bash -c '. #{cmdfile}' >#{@ferr1.path} 2>&1")
		@status = $?.exitstatus

		(~cmdfile).unlink
	end

	def _run1
		cmdfile = Bento.tempfile(<<~ENDX)
			# set -x

			FBACKD=$(mktemp -d /tmp/fback.XXXXXX)
			prog='#{@prog}'
			at="#{@r_at}"

			ssh -o StrictHostKeyChecking=no #{@user}@#{@host} "PROG='$prog' AT='$at' bash -s" <<'END' | tar xzf - -m -C $FBACKD
				# set -x

				fbackd=$(mktemp -d /tmp/fback.XXXXXX)
				fout=$fbackd/out
				ferr=$fbackd/err
				frc=$fbackd/rc
				fpack=$fbackd/pack.tgz

				( [[ -z $AT ]] && cd "$AT"; eval $PROG ;) 1> $fout 2> $ferr
				rc=$?
				echo $rc > $frc
				tar czf - -C $fbackd out err rc
				[[ -d $fbackd ]] && rm -rf $fbackd
				exit $rc
			END

			cp $FBACKD/out #{@fout.path}
			cp $FBACKD/err #{@ferr.path}
			rc=`cat $FBACKD/rc`
			[[ -d $FBACKD ]] && rm -rf $FBACKD
			exit $rc
			ENDX

		@ferr1 = Tempfile.new('syserr.')
		@ferr1.close

		system("bash", "-c", "#{cmdfile} >#{@ferr1.path} 2>&1")
		@status = $?.exitstatus

		(~cmdfile).unlink
	end

	def error!
		error "Bento::SSHBashCommand(#{@prog}, user: #{@user}, host: #{@host}) failed"
	end
end

#----------------------------------------------------------------------------------------------

class PSCommand < Command

if Bento::System.ostype == :windows
	@@powershell = ENV['WINDIR'] + "\\system32\\WindowsPowerShell\\v1.0\\powershell.exe"
else
	@@powershell = "powershell"
end

	# options:
	# :json
	def initialize(*opt, at: nil, include: nil, exclude: nil, depth: nil)
		opt_flags = []
		@cmds = []
		opt.each do |o|
			if o.string?
				@cmds << o
			elsif o.symbol?
				opt_flags << o
			elsif o.array?
				@cmds.concat(o)
			else
			end
		end

		opt = opt_flags
		flags binding, [:json]

		@include = include == :all ? ['*'] : include.to_a
		@exclude = exclude.to_a
		@depth = depth
		@json = true if !@include.empty? || !@exclude.empty? || !!@depth

		n = @cmds.size
		# classes_cl = ". " + ~ENV['CLASSICO_ROOT']/"posh/Classico.Posh/Classes.ps1"
		classico_cl = "import-module Classico.Posh -DisableNameChecking"
		noprogress_cl = "$ProgressPreference = 'SilentlyContinue'"
		json_cl = _json_clause
		exit_cl = "exit $(if ($?) {0} else {#{n}})"

		cmds = ""
		for i in (1..n-1)
#@@			cmds += "try { #{@cmds[i-1]} -WarningAction SilentlyContinue -ErrorAction Stop | out-null } catch { Write-Error $_ ; exit #{i} } ; "
			cmds += "try { #{@cmds[i-1]} | out-null } catch { Write-Error $_ ; exit #{i} } ; "
		end
#@@		cmds += "try { #{@cmds[n-1]} -WarningAction SilentlyContinue #{json_cl} } catch { Write-Error $_ ; exit #{n} }"
		cmds += "try { #{@cmds[n-1]} #{json_cl} } catch { Write-Error $_ ; exit #{n} }"
		prog = "#{classico_cl} ; #{noprogress_cl} ; #{cmds} ; #{exit_cl}"

		super(prog, *opt, at: at)
	end

	def _json_clause
		include_cl = @include.join(",")
		exclude_cl = @exclude.empty? ? "" : "-exclude " + @exclude.join(",")
		select_cl = (!include_cl || include_cl == '*') && !exclude_cl ? "" : "| Select-Object #{include_cl} #{exclude_cl}"
		json_cl = @json ? "| ConvertTo-JSON #{!@depth ? '' : "-depth:" + @depth.to_s}" : ""
		"#{select_cl} #{json_cl}"
	end

	def _run
		pscmd = "#{@@powershell} \"#{@prog}\""
		cmd = "cmd /c #{pscmd} 1> #{@fout.path} 2> #{@ferr.path}"
		system(cmd)
		@status = $?.exitstatus
	end
	
	def out_json
		@json && !out_s.empty? ? JSON.from_json(out_s) : nil
	end
	
	def out_json_fields
		# out_json is array of hashes
		out_json.map{|x|x.keys}.reduce(Set[]) {|s,kk| kk.reduce(s, :add)}.to_a
	end
end

#----------------------------------------------------------------------------------------------

def Bento.system(*args)
	if args.count == 1
		a0 = args.first
		if a0.array?
			args = a0
		elsif a0.string?
			args = Shellwords.split(a0)
		end
	end
	if Bento::System.ostype == :windows
		cmd = ["bash", "-c"]
		cmd << Shellwords.join(args)
		Kernel.system(*cmd)
	else
		Kernel.system(*args)
	end
end

#----------------------------------------------------------------------------------------------

end # module Bento

#----------------------------------------------------------------------------------------------

def systema(cmd, *opt, at: nil)
	Bento::BashCommand.new(cmd, *opt, at: at)
end

#----------------------------------------------------------------------------------------------

def systemq(cmd, *opt, at: nil)
	Bento::BashCommand.new(cmd, *opt << :nonop, at: at)
end

#----------------------------------------------------------------------------------------------

def systemx(cmd, *opt, at: nil)
	c = Bento::BashCommand.new(cmd, *opt, at: at)
	c.error! if c.status != 0
	c
end

#----------------------------------------------------------------------------------------------

def systemqx(cmd, *opt, at: nil)
	systemx(cmd, *opt << :nonop, at: at)
end

#----------------------------------------------------------------------------------------------

def rsystem(cmd, *opt, user: nil, host: nil, at: nil)
	Bento::SSHBashCommand.new(cmd, *opt, user: user, host: host, at: at)
end

def rsystemx(cmd, *opt, user: nil, host: nil)
	c = Bento::SSHBashCommand.new(cmd, *opt, user: user, host: host, at: at)
	c.error! if !c.ok?
	c
end

#----------------------------------------------------------------------------------------------

def posha(*opt, at: nil, include: nil, exclude: nil, depth: nil)
	Bento::PSCommand.new(*opt, at: at, include: include, exclude: exclude, depth: depth)
end

def poshx(*opt, at: nil, include: nil, exclude: nil, depth: nil)
	c = Bento::PSCommand.new(*opt, at: at, include: include, exclude: exclude, depth: depth)
	c.error! if c.status != 0
	c
end

#----------------------------------------------------------------------------------------------
