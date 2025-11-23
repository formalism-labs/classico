
require 'minitest/autorun'
require 'Bento/lib/Class'

#-------------------------------------------------------------------------------------------

module M

class A
	include Bento::Class

	attr_reader :init, :name, :file

	constructors :is, :create
	members :file, :name, :init

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
end

class B < A

	constructors :is

	def is(file = "nofile")
		super(file)
	end
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
		
		x = M::A.create("jojo", file: "file")
		assert_equal true, x.init
		assert_equal "jojo", x.name
		assert_equal "file", x.file
	end

	# _covers :constructors
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
