
require 'minitest/autorun'
require 'debug'

#-------------------------------------------------------------------------------------------

module M

class A
	attr_reader :init, :name, :file

	def do_it
		"do_it"
	end
	
	def is(file = "nofile")
		@file = file
	end

	def create(name, *opt, file: nil)
		@name = name
		@file = file
	end

	def initialize
		@init = true
	end
	
	### boilerplate
	
	def self.is(*args)
		x = self.new; x.send(:is, *args); x
	end

	def self.create(*args)
		x = self.send(:new); x.send(:create, *args); x
	end
	
	protected :is, :create
	private_class_method :new

	### boilerplate
end

def self.A(*args)
	x = A.send(:new); x.send(:is, *args); x
end

class B < A

	def is(file = "nofile")
		super(file)
	end

	### boilerplate
	
	def self.is(*args)
		x = self.new; x.send(:is, *args); x
	end

	protected :is

	### boilerplate
end

def self.B(*args)
	x = B.send(:new); x.send(:is, *args); x
end

end # module M

#-------------------------------------------------------------------------------------------

class Test1 < Minitest::Test

	def test_A
		x = M.A
		refute_equal true, x.is_a?(Class)
		assert_equal true, x.is_a?(M::A)

		x = M.A()
		refute_equal nil, x
		assert_equal true, x.init
		assert_equal true, x.is_a?(M::A)
		
		assert_raises(NoMethodError) do 
			x.create("jojo")
		end
		
		assert_raises(NoMethodError) do 
			M::A.new 
		end
		
		assert_raises(NoMethodError) do 
			M::A.new(1,2,3)
		end
		
		x = M.A("file")
		assert_equal true, x.init
		assert_equal "file", x.file
		
		binding.break
		x = M::A.create("jojo", file: "file")
		assert_equal true, x.init
		assert_equal "jojo", x.name
		assert_equal "file", x.file
	end

	def test_B
		x = M.B
		refute_equal true, x.is_a?(Class)
		assert_equal true, x.is_a?(M::B)

		x = M.B()
		refute_equal nil, x
		assert_equal true, x.init
		assert_equal true, x.is_a?(M::B)
		
		assert_raises(NoMethodError) do 
			x.create("jojo")
		end
		
		assert_raises(NoMethodError) do 
			M::B.new 
		end
		
		assert_raises(NoMethodError) do 
			M::B.new(1,2,3)
		end
		
		x = M.B("file")
		assert_equal true, x.init
		assert_equal "file", x.file
		
		x = M::B.create("jojo", file: "file")
		assert_equal true, x.init
		assert_equal "jojo", x.name
		assert_equal "file", x.file
	end

end
