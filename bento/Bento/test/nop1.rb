
require 'minitest/autorun'
require 'Bento'

class Nop1 < Minitest::Test

	def test_nop1
		Bento.nop = false
		assert_equal false, Bento.nop?
		assert_equal true, Bento.nop?(:nop)
		assert_equal false, Bento.nop?(:nonop)
		assert_raises(RuntimeError) { Bento.nop?(:nop, :nonop) }

		Bento.nop = true
		assert_equal true, Bento.nop?
		assert_equal true, Bento.nop?(:nop)
		assert_equal false, Bento.nop?(:nonop)
		assert_raises(RuntimeError) { Bento.nop?(:nop, :nonop) }
	end
	
	def f(*opt)
		Bento.nop?(*opt)
	end

	def test_nop2
		Bento.nop = false
		assert_equal false, f(:x)
		assert_equal true, f(:x, :nop)
		assert_equal false, f(:nonop, :x)
	end
end
