
require 'minitest/autorun'
require 'Bento'

#-------------------------------------------------------------------------------------------

class Test1 < Minitest::Test
	def test_ux
		assert_equal '/abc/def/foo', (Pathname.new("/abc/def")/"foo").to_ux.to_s
		assert_equal '/abc/def/foo', (Pathname.new("/abc/def")+"foo").to_ux.to_s
		
		assert_equal 'v:/foo', (Pathname.new("v:")/"foo").to_ux.to_s
		assert_equal 'v:/foo', (Pathname.new("v:")/"/foo").to_ux.to_s
		binding.break
		assert_equal 'v:/foo', (Pathname.new("v:/")/"foo").to_ux.to_s
		assert_equal 'v:/foo', (Pathname.new("v:/")/"/foo").to_ux.to_s

		assert_equal '/foo', (Pathname.new("/")/"foo").to_ux.to_s
		assert_equal '/foo', (Pathname.new("/")/"/foo").to_ux.to_s
	end
	
	def test1_win
		assert_equal '\abc\def\foo', (Pathname.new("/abc/def")/"foo").to_win.to_s
		assert_equal '\abc\def\foo', (Pathname.new("/abc/def")+"foo").to_win.to_s
		assert_equal 'v:\foo', (Pathname.new("v:")/"foo").to_win.to_s
		assert_equal 'v:\foo', (Pathname.new("v:/")/"foo").to_win.to_s
	end
	
	def test_assignment
		p = ~"c:/"
		assert_equal Pathname.new("c:/"), p
		p /= :foo
		assert_equal "c:/foo", p.to_ux.to_s
	end
end

#-------------------------------------------------------------------------------------------
