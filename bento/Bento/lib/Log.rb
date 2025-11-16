
require 'logger'

module Bento

#---------------------------------------------------------------------------------------------- 

class Logger < ::Logger
	def initialize(logdev, *opt)
		super(nil, *opt)
		@logdev = Logger::LogDevice.new(logdev, *opt) if logdev
	end

	class LogDevice < ::Logger::LogDevice
		def add_log_header(file) ; end
	end
end

#---------------------------------------------------------------------------------------------- 

module Log
	$logger = nil
	$log_stream = nil
	$stack_stream = nil
	
	def debug(progname = nil, &block)
		logger.debug(progname, &block)
	end

	def info(progname = nil, &block)
		logger.info(progname, &block)
	end

	def warn(progname = nil, &block)
		logger.warn(progname, &block)
	end

	def error(progname = nil, *args, **nargs, &block)
		noraise = args.include?(:noraise)
		
		skip = nargs.include?(:skip) ? nargs[:skip] : 0
		except = nargs.include?(:exception) ? nargs[:exception] : nil

		if progname.is_a?(Exception)
			error_class = progname
			text = progname.to_s
		else
			text = Log.get_message(progname, &block)
		end
		if except
			text += " <== #{except}"
			File.open($stack_stream, "a+") do |f|
				when_s = DateTime.now.strftime('%Y-%m-%d %H:%M:%S')
				f.write("\n" + when_s + " " + "-" * (80 - when_s.size) + "\n")
				f.write(Bento::Backtrace.new(except, :nocolor))
			end
		end
		
		# superx = args.size > 0 ? args[0] : nil
		logger.add(Logger::ERROR, text, &block)
		return if noraise

		if !error_class
			if self.class.name == "Class"
				error_class = eval("#{self.name}::Error rescue nil")
			else
				error_class = eval("#{self.class.name}::Error rescue nil")
			end
			error_class = Bento::Error if error_class == nil
		end
		raise error_class, text, caller[skip..-1]
	end

	def fatal(progname = nil, **nargs, &block)
		except = nargs.include?(:exception) ? nargs[:exception] : nil

		text = Log.get_message(progname, &block)
		if except
			text += " <== #{except}"
			File.open($stack_stream, "a+") do |f|
				when_s = DateTime.now.strftime('%Y-%m-%d %H:%M:%S')
				f.write("\n" + when_s + " " + "-" * (80 - when_s.size) + "\n")
				f.write(Bento::Backtrace.new(except, :nocolor))
			end
		end
		logger.add(Logger::FATAL, text, nil)
		puts "Error: " + text
		exit(1)
	end

	def unimplemented
		error "unimplemented", skip: 1
	end

	def Log.get_message(text, &block)
		text = yield if block_given?
		text
	end

	def Log.to=(io)
		$log_stream = io
		new_logger
	end

	def Log.stack=(io)
		$stack_stream = io
	end

	def logger
		$logger ? $logger : new_logger
	end

	private def new_logger
		$logger.close if $logger
		if !$log_stream
			box = Box.find
			if box
				$log_stream = box.log_root/std_name
			else
				$log_stream = $stdout
			end
		end
		$logger = Logger.new($log_stream)
		$logger.formatter = proc do |severity, datetime, progname, msg|
			when_s = datetime.strftime('%Y-%m-%d %H:%M:%S')
			"%s %-5s %s\n" % [when_s, severity, msg]
		end
		$logger
	end

	def std_name
		"#{File.basename($0, '.*')}.log"
	end
end

#---------------------------------------------------------------------------------------------- 

end # Bento

#---------------------------------------------------------------------------------------------- 

class Object
	include Bento::Log
end

