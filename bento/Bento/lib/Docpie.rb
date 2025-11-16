
# require 'docpie.rb'
require 'shellwords'
require 'pp'
require 'open3'

module Bento
module Docpie

#----------------------------------------------------------------------------------------------

class Docpie

	@@piedoc_t = <<~END
		"""
		<%= argdoc %>
		"""

		from docpie import docpie
		import json

		args = docpie(__doc__, optionsfirst = <%= options_first ? 'True' : 'False' %>)
		print(json.dumps(args))
		exit(7)

		END

	def initialize(argdoc, argv: nil, options_first: false)
		argv = ARGV if !argv
		piefile = Bento.tempfile(Bento.mold(@@piedoc_t, binding))
		pieargs = argv.map{|x| '"' + Shellwords.escape(x) + '"'} * ' '
		pie = systema("python #{piefile} #{pieargs}")#, :nolog)
		if pie.ok? # this is a help string
			puts pie.out_s
			# exit(0)
			raise HelpException.new
			
		elsif pie.status != 7 # this is an syntax error
			puts pie.err_s
			raise Error.new
			# exit(1)
		end

		@args = Bento::JSON.from_json(pie.out_s)
		puts args.to_s
	end
	
	def args
		@args.to_h
	end
	
	class Error < RuntimeError
		def initialize(err = '')
			super(err)
		end
	end
	
	class Exit < Exception
		def initialize(msg = '')
		end
	end
end

#----------------------------------------------------------------------------------------------

class Options
	def initialize(opthash)
		@opthash = opthash
	end
	
	def method_missing(m, *args_)
		m = m.to_s.gsub('_', '-')
		self[m]
	end

	def[](s)
		s = s.to_s
		if @opthash.include?("#{s}")
			@opthash["#{s}"]
		elsif @opthash.include?("--#{s}")
			@opthash["--#{s}"]
		elsif @opthash.include?("<#{s}>")
			@opthash["<#{s}>"]
		elsif @opthash.include?("#{s.upcase}")
			@opthash["#{s.upcase}"]
		else
			error "invalid option: '#{s}'"
		end
	end

	def exist?(s)
		s = s.to_s
		@opthash.include?("--#{s}") || @opthash.include?("<#{s}>") || @opthash.include?("#{s.upcase}")
	end
	
	def verbatim(s)
		@opthash[s.to_s]
	end
end

#----------------------------------------------------------------------------------------------

class Command
	attr_reader :options

	def initialize(argdoc, *opt)
		@opthash = Docpie.new(argdoc, *opt).args
		@options = Options.new(@opthash)
		Bento.nop = options.nop if options.exist?(:nop)

		if options.exist?(:print_args) && options.print_args
			pp @opthash
			exit(1)
		end

		rescue Bento::Docpie::Docpie::Exit => x
			puts "#{File.basename($0)}: " + x.message
			exit(1)

		rescue SystemExit => x
			raise

		rescue Exception => x
			fatal x.message
	end

	def run!
		run

		rescue Bento::Error => x
			puts "#{$0}: " + x.message
			exit(1)

		rescue SystemExit => x
			exit(1)

		rescue Exception => x
			puts "Internal error."
			bt(x)
			exit(1)
	end

#	def error(x)
#		puts "Error: " + x.message
#		exit(1)
#	end
end

#----------------------------------------------------------------------------------------------

class Supercommand < Command
	attr_reader :command, :command_args

	alias_method :global_options, :options

	def initialize(argdoc, *opt)
		super(argdoc, *opt, options_first: true)

		@command = options.command
		@command_args = [@command] + options.args
	end

	def before; end

	def run
		before
		Bento::Docpie::Subcommand.run(self, @command_args)
	end
end

#----------------------------------------------------------------------------------------------

class Subcommand
	attr_reader :command, :options

	@@subcommands = []

	def self.inherited(sub)
		@@subcommands << sub if sub.to_s != "Subcommand"
		super
	end

	def self.run(sup_cmd, args)
		@@subcommands.each do |sub|
			name = sub.name.downcase
			return sub.send("new", sup_cmd).run if name == sup_cmd.command
		end
		fatal "invalid command '#{sup_cmd.command}'."
		nil
	end

	def initialize(sup_cmd)
		@command = sup_cmd
		s = self.class.class_eval("@@argdoc") rescue nil
		s = docpie if s == nil
		@opthash = Docpie.new(s, argv: @command.command_args).args
		@options = Options.new(@opthash)
		if options.exist?(:print_args) && options.print_args
			pp @opthash
			exit(1)
		end

		rescue Docpie::Exit => x
			puts "#{$0}: " + x.message
			exit(1)

		rescue SystemExit => x
			raise

		rescue Exception => x
			fatal x.message
	end

	def run; end

	def global_options
		command.global_options
	end
end

#----------------------------------------------------------------------------------------------

end # module Docpie
end # module Bento
