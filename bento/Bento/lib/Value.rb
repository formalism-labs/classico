
module Bento

#----------------------------------------------------------------------------------------------

class Value
	def to_i; value.to_i; end
	def to_int; to_i; end
	
	def to_s; value.to_s; end
	def to_str; to_s; end

	def coerce(x)
		# [self.class.send(:new, x), self]
		[self.class.send(:new, self.class.send(:coerce_value, x)), self]
	end
	
	class << self
		def unary_operators(ops)
			ops.each do |op|
				uop = op + "@"
				define_method(uop.to_sym) do
					value.send uop.to_sym
				end
			end
		end

		def binary_operators(ops)
			ops.each do |op|
				define_method(op.to_sym) do |x|
					x = x.value if x.is_a?(self.class)
					value.send op.to_sym, x
				end
			end
		end
	end
	
	unary_operators %w(+ - ~ !)
	binary_operators %w(+ - * / % ** == != < <= > >= <=> === =~ !~ && || & | ^ << >> .. ...)

	def value
		raise "Error: need to override 'value' method"
	end
	
	def self.coerce_value(x)
		x
	end
end

#----------------------------------------------------------------------------------------------

class SimpleValue < Value
	def initialize(x)
		@x = x
	end

	def value
		x = Integer(@x) rescue @x
		if x.string?
			b = x.to_bool
			return b if b != nil
		end
		x
	end
end

#----------------------------------------------------------------------------------------------

end # module Bento
