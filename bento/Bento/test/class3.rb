
require 'minitest/autorun'
require 'Bento/lib/Class'

# based on Jorg W Mittag's work:
# http://stackoverflow.com/questions/3157426/how-to-simulate-java-like-annotations-in-ruby

#-------------------------------------------------------------------------------------------

class A
	include Bento::Class

	_hello   color: 'red',   ancho:   23
	_goodbye color: 'green', alto:  -123
	_foobar  color: 'blew'
	def m1; end

	def m2; end

	_foobar  color: 'cyan'
	def m3; end
end

#-------------------------------------------------------------------------------------------

class Test1 < Minitest::Test

	def test_that_m1_is_annotated_with_hello_and_has_value_red
		assert_equal 'red', A.annotations(:m1)[:hello][:color]
	end
	
	def test_that_m3_is_annotated_with_foobar_and_has_value_cyan
		assert_equal 'cyan', A.annotations[:m3][:foobar][:color]
	end
	
	def test_that_m1_is_annotated_with_goodbye
		assert A.annotations[:m1][:goodbye]
	end

	def test_that_all_annotations_are_there
		annotations = {
			m1: {
				hello:   { color: 'red',   ancho:   23 },
				goodbye: { color: 'green', alto:  -123 },
				foobar:  { color: 'blew' }
				},
			m3: {
				foobar:  { color: 'cyan' }
				}
			}
		assert_equal annotations, A.annotations
	end
end

#-------------------------------------------------------------------------------------------
