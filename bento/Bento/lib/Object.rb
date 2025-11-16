
#----------------------------------------------------------------------------------------------

class Object

	def deep_clone
		return Marshal.load(Marshal.dump(self)) if array? || hash?
		return @deep_cloning_obj if @deep_cloning
		@deep_cloning_obj = clone
		@deep_cloning_obj.instance_variables.each do |var|
			val = @deep_cloning_obj.instance_variable_get(var)
			begin
				@deep_cloning = true
				val = val.deep_clone
			rescue TypeError
				next
			ensure
				@deep_cloning = false
			end
			@deep_cloning_obj.instance_variable_set(var, val)
		end
		deep_cloning_obj = @deep_cloning_obj
		@deep_cloning_obj = nil
		deep_cloning_obj
	end

	def bool?
		is_a?(TrueClass) || is_a?(FalseClass)
	end

	def number?
		is_a?(Numeric)
	end
	
	def int?
		is_a?(Integer)
	end
	
	def string?
		is_a?(String)
	end
	
	def symbol?
		is_a?(Symbol)
	end
	
	def array?
		is_a?(Array)
	end
	
	def hash?
		is_a?(Hash)
	end
	
	def class?
		is_a?(Class)
	end

	def module
		k = class? ? self : self.class
		eval(k.name.split("::")[0..-2].join("::"))
	end

	def is_a(t)
		if t.array?
			t.each { |t1| is_a t1 }
		elsif t.is_a?(Class)
			error "Expected #{t.name} got #{self.class.name}" if !self.is_a?(t)
		else
			error "Method Object::is_a expects classes, got #{t.class.name}"
		end
		self
	end
end

#----------------------------------------------------------------------------------------------

# class UnboundMethod
#	def parameters_string
#		# parameters look like: [[:req, :a], [:req, :b], [:rest, :opt]]
#		parameters.map{|x| x[0] == :req ? x[1].to_s : "*" + x[1].to_s}.join(",")
#	end
#end

#req     #required argument
#opt     #optional argument
#rest    #rest of arguments as array
#keyreq  #reguired key argument (2.1+)
#key     #key argument
#keyrest #rest of key arguments as Hash
#block   #block parameter