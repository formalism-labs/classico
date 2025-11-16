
module Bento

#------------------------------------------------------------------------------

def self.truth_table(vars, values = [0, 1])
	a = [values] * vars
	a.first.product(*a[1..-1])
end

#------------------------------------------------------------------------------

end # module Bento

#------------------------------------------------------------------------------

class Array

	#--------------------------------------------------------------------------

	def self.cxr(x, y)
		case x[-1]
			when 'a'
				return nil if y.size == 0
				y = y.first
			when 'd'
				return [] if y.size == 1
				y = y.drop(1)
			when nil
				return y
			else
				raise "Array: invalid cxr specification: #{x[-1]} in #{x}"
		end
		cxr(x[0...-1], y)
	end

	def self.define_cxr_methods(n)
		(1..n).each do |k|
			Bento.truth_table(k, %w(a d)).map(&:join).each do |x|
				define_method("c#{x}r")  { Array.cxr __method__[1..-2], self }
			end
		end
	end

	define_cxr_methods 5

	#--------------------------------------------------------------------------

	# for array of hashes [{"a"=>1}, {"a"=>2}] return [1,2]
	
	def cut(name = nil)
		if !name
			c = first
			c = c == nil || !c.hash? ? [] : c.keys.select{|k|!k.number?}
			if c.count == 1
				name = c.first
			else
				return self
			end
		end
		map { |x| x[name] }	
	end

	#--------------------------------------------------------------------------

end

#------------------------------------------------------------------------------
