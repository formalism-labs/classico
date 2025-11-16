
# require 'minitest'
require 'minitest/autorun'

module Bento

#----------------------------------------------------------------------------------------------

# Provide test-class-level before/after methods (in addition to test-method
# level setup/teardown methods).

class Test < Minitest::Test
	attr_reader :box

	@@objects = Hash.new

	class << self; attr_accessor :before_class end
	@before_class = false

	@@test_object = nil

	def self.class_init
		Minitest.after_run { @@test_object._after if @@test_object != nil }
	end
	class_init

	def live_to_tell
		yield
		rescue => x
			self.failures << Minitest::UnexpectedError.new(x)
	end

	def setup
		return if self.class.before_class

		@@test_object._after if @@test_object != nil

		self.class.before_class = true
		@@test_object = self

		@@objects[object_id] = self
		ObjectSpace.define_finalizer(self, proc {|id| Test.finalize(id) })

		_before # live_to_tell { _before }
	end

	def self.finalize(id)
		x = @@objects[id]
		x._finally if x
	end

	def _before(final = true)
		live_to_tell do
			if create_box?
				@box = create_box
				@box.enter
			end
			before if final
		end
	end

	def _after(final = true)
		live_to_tell do
			after if final
			@box.remove if @box != nil && !keep_box?
		end
	end

	def _finally(final = true)
		self.failures.each do |x| 
			puts x.message
		end
		live_to_tell { finally if final }
	end

	def before; end
	def after; end
	def finally; end

	#------------------------------------------------------------------------------------------

	def create_box
		box_class = eval("#{self.module.name}::Box") rescue nil
		return nil if !box_class
		box_class.create(:test)
	end

	def create_box?
		true
	end

	def keep_box?
		ENV["KEEP_TEST_BOX"].to_i == 1
	end
end

#----------------------------------------------------------------------------------------------

end # module Bento
