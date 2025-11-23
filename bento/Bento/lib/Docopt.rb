
require 'docopt'
require 'pp'

module Bento
module Docopt

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

	def initialize(docopt, *opt)
		@opthash = ::Docopt::docopt(docopt, *opt)
		@options = Options.new(@opthash)
		Bento.nop = options.nop if options.exist?(:nop)

		if options.exist?(:print_args) && options.print_args
			pp @opthash
			exit(1)
		end

		rescue ::Docopt::Exit => x
			puts "#{File.basename($0)}: " + x.message
			exit(1)

		rescue SystemExit => x
			raise

		rescue Exception => x
			bb
			fatal x.message, exception: x
	end

	def run!
		run

		rescue Bento::Error => x
			puts "#{File.basename($0)}: " + x.message
			exit(1)

		rescue SystemExit => x
			exit(1)

		rescue Exception => x
			bb
			error "internal error", :noraise, exception: x
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

	def initialize(docopt, *opt)
		super(docopt, *opt, options_first: true)

		@command = options.command
		@command_args = [@command] + options.args
	end

	def before; end

	def run
		before
		Bento::Docopt::Subcommand.run(self, @command_args)
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
		s = self.class.class_eval("@@docopt") rescue nil
		s = docopt if s == nil
		@opthash = ::Docopt::docopt(s, argv: @command.command_args)
		@opthash.delete(@command.command)
		@options = Options.new(@opthash)
		if options.exist?(:print_args) && options.print_args
			pp @opthash
			exit(1)
		end

		rescue ::Docopt::Exit => x
			puts x.message
			exit(1)

		rescue SystemExit => x
			raise

		rescue Exception => x
			bb
			fatal x.message, exception: x
	end

	def run; end

	def global_options
		command.global_options
	end

	def op(what, *flags, &b)
		info what
		if block_given?
			yield
		end
		rescue Bento::Error => x
			fatal "while #{what}: #{x}"
	end
end

#----------------------------------------------------------------------------------------------

end # module Docopt
end # module Bento
