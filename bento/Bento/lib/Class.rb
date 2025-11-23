
require 'debug'

module Bento

#----------------------------------------------------------------------------------------------

module Class

	def self.included(base)
		# @@note: need to add an "inherited" hook method for "base" to handle initialization
		# of Bento::Class related structures

		base.class_eval("Self = self")
		base.extend(ClassMethods::All)
	end

	#------------------------------------------------------------------------------------------

	def flags(bind = nil, flagsyms = [], optsym: :opt, withdefaults: [], locals: [])
		if bind == nil
			require 'binding_of_caller'
			bind = binding.of_caller(1)
		end
		opt = eval("#{optsym}", bind)
		
		withdefaults.each do |n|
			x = eval("#{n}", bind)
			if x.symbol?
				opt += [x]
				eval("#{n} = nil", bind)
			end
		end
		eval("#{optsym} = #{opt}", bind)

		flags = eval("#{flagsyms}", bind)
		flags.each do |f|
			b = opt.include?(f)
			instance_variable_set("@#{f}", b)
			opt.delete f if b
		end
		eval("#{optsym} = #{opt}", bind)

		locals.each do |f|
			b = opt.include?(f)
			error "no local variable #{f}" if !bind.local_variable_defined?(f)
			bind.local_variable_set(f, b)
			opt.delete f if b
		end
		eval("#{optsym} = #{opt}", bind)
	end

	# should eventually be deprecated
	# if opt.include? :flag, @flag = true
	def init_flags(flags, opt)
		rest = opt.dup
		flags.each do |f|
			if rest.include? f
				instance_variable_set("@#{f}", true)
				rest.delete f
			end
		end
		rest
	end

	def filter_flags(flags, opt)
		opt.select {|x| flags.include? x }
	end

	def filterout_flags(flags, opt)
		opt.select {|x| !flags.include?(x) }
	end

	# if opt.include? tag, invoke method tag(*args)
	def tagged_init(tag, opt, args)
		return false if !opt.include? tag
		send(tag, *args)
		return true
	end

	# def assert_type(val, type)
	# end

	# def assert_type!(val, type)
	# end

	#------------------------------------------------------------------------------------------

	# called after constructor, checks if members exist
	def __ready
		return
		obj_id = self.class.name + "(#{__identity})"
		self.class.class_eval("@@members ||= []")
		self.class.class_eval("@@members").each do |m|
			if m.symbol?
				# puts "READY: check #{m.to_s}"
				error "READY: #{obj_id}::#{m} undefined", skip: 3 if !eval("defined?(@#{m})")
			elsif m.array?
				# puts "READY: check #{m[0].to_s}"
				var = instance_variable_get("@#{m[0]}")
				error "READY: #{obj_id}::#{m[0]} undefined", skip: 3 if !eval("defined?(@#{m[0]})")
				if m[1].class?
					error "READY: #{obj_id}::#{m[0]}: expected #{m[1].name} got #{var.class.name} " if !instance_variable_get("@#{m[0]}").is_a?(m[1])		
				elsif m[1].symbol?
					error "READY: #{obj_id}::#{m[0]}: test failed", skip: 3 if !eval("#{m[1]}(var)")
				end
			end
		end
	end

	def __identity
		id = instance_variable_get("@id")
		id = instance_variable_get("@name") if !id
		id = "?" if !id
		id
	end

end # Class

#----------------------------------------------------------------------------------------------

module ClassMethods

#----------------------------------------------------------------------------------------------

module Constructors

	def constructors(*ctors)
		class_eval("@@ctors ||= []")
		class_eval("@@ctors += " + ctors.to_s)

		fq_klass = self.name
		
		# for self.name == A::B::C, m_klass == B::C
		# m_klass = self.name.split("::")[-2..-1].join("::")
		
		klass = self.name.split("::")[-1]
		
		# for self.name == A::B::C, mod == A::B
		mod = eval(self.name.split("::")[0..-2].join("::"))

		class_eval("private_class_method :new")

		ctors.each do |ctor|
			if ctor == :is
				# this enables the A::B.C(...) syntax for C.is
				mod.module_eval(<<-END)
					def self.#{klass.to_sym}(*args)
						x = eval("#{fq_klass}").send(:new)
						x.send(:is, *args)
						x.send(:__ready)
						x
					end
				END

#				mod.define_singleton_method(klass.to_sym) do |*args|
#					x = eval(fq_klass).send(:new)
#					x.send(:is, *args)
#					x
#				end
			end
			
			class_eval("private :" + ctor.to_s) rescue ''

			class_eval(<<-END)
				def self.#{ctor}(*args)
					x = self.send(:new)
					x.send(:#{ctor}, *args)
					x.send(:__ready)
					x
				end
			END
		end
	end
	
	def self._method_added(c, m)
		c.class_eval("@@ctors ||= []")
		c.class_eval("private :" + m.to_s) if c.class_eval("@@ctors").include?(m)
	end
	
	def ctors
		class_eval("@@ctors")
	end

	#------------------------------------------------------------------------------------------

	def members(*vars)
		class_eval("@@members ||= []")
		vars.each do |v|
			if v.is_a?(Symbol)
				class_eval("@@members << :#{v}") 
			else
				class_eval("@@members << #{v.to_s}")
			end
		end
	end
	
	def class_members
		class_eval("@@members ||= []")
		class_eval("@@members")
	end
	
end # Constructors

#----------------------------------------------------------------------------------------------

# based on Jorg W Mittag's work:
# http://stackoverflow.com/questions/3157426/how-to-simulate-java-like-annotations-in-ruby

module Annotations

	def annotations(m = nil)
		return @__annotations__[m] if m
		@__annotations__
	end
 
	def self._method_added(c, m)
		warn_level = $VERBOSE
  		$VERBOSE = nil

		c.class_eval("@__annotations__ ||= {}")
		last1 = c.class_eval("@__last_annotation__")
		c.class_eval("@__annotations__")[m] = last1 if last1
		c.class_eval("@__last_annotation__ = nil")

		$VERBOSE = warn_level
	end

	def self._method_missing(c, m, *args)
		warn_level = $VERBOSE
  		$VERBOSE = nil

		return false unless /\A_/ =~ m
		c.class_eval("@__last_annotation__ ||= {}")
		c.class_eval("@__last_annotation__")[m[1..-1].to_sym] = args.size == 1 ? args.first : args

		$VERBOSE = warn_level

		true
	end
end

#----------------------------------------------------------------------------------------------

module Interfaces

	def implement_interface(iface, smart_meth_sym)
		iface.instance_methods.each do |imeth_sym|
			define_method(imeth_sym) do |*args|
				smart = self.send(smart_meth_sym)
				smart.send(imeth_sym, *args)
			end
		end
	end

	def interfaces(*ifaces)
		ifaces.each do |iface|
			iface.instance_methods.each do |imeth_sym|
				if iface.instance_method(imeth_sym).parameters != instance_method(imeth_sym).parameters
					raise "Method '#{self.name}::#{imeth_sym.to_s}' is not compatible with interface '#{iface.to_s}'"
				end
			end
		end
	end

end

#----------------------------------------------------------------------------------------------

module All
	include ClassMethods::Constructors
	include ClassMethods::Annotations
	include ClassMethods::Interfaces

	def method_added(m)
		ClassMethods::Constructors._method_added(self, m)
		ClassMethods::Annotations._method_added(self, m)
		super
	end

	def method_missing(m, *args)
		return if ClassMethods::Annotations._method_missing(self, m, *args)
		super
	end
end

#----------------------------------------------------------------------------------------------

end # ClassMethods

#----------------------------------------------------------------------------------------------

end # module Bento

#----------------------------------------------------------------------------------------------

class Module
	def root
		Pathname.new(self::ROOT) rescue nil
	end
end

#----------------------------------------------------------------------------------------------

module Kernel
	if ENV['BB'] == '1'
		def bb
			loc = caller_locations(1, 1).first
			file = loc.absolute_path || loc.path
			line = loc.lineno + 1
			
			if defined?(DEBUGGER__::SESSION)
				session = DEBUGGER__::SESSION
			else
				if defined?(DEBUGGER__)
					begin
						DEBUGGER__.console
					rescue StandardError
						return
					end
				else
					return
				end
				session = DEBUGGER__::SESSION rescue nil
				return unless session
			end
			
			session.add_line_breakpoint(file, line, oneshot: true)
			nil
		end
	else
		def bb; end
	end
end

#----------------------------------------------------------------------------------------------
