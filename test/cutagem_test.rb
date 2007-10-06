require File.dirname(__FILE__) + '/test_helper.rb'

require "test/unit"
class SafeEvalTest < Test::Unit::TestCase

	def setup
		@t = SafeEval.new.taint
	end

	def test_interface
		assert_nothing_raised do
			@t.safe_eval(":foo")
		end

		assert_nothing_raised do
			@t.eval(":foo")
		end

		assert_nothing_raised do
			SafeEval.eval(":foo")
		end
	end

	def test_safe
		assert_raise(SecurityError) do
			@t.safe_eval("puts ''")
		end

		assert_raise(SecurityError) do
			@t.safe_eval("$foo = :foo")
		end
	end

	def test_thread
		a = Thread.list.size
		ret = @t.safe_eval <<-EOC
			Thread.start {
				sleep
			}
		EOC
		assert_equal(a, Thread.list.size)

		a = Thread.list.size
		ret = @t.safe_eval <<-EOC
			100.times do
				Thread.start {
					sleep
				}
			end
		EOC
		assert_equal(a, Thread.list.size)
	end

	def test_timeout
		assert_raise(Timeout::Error) do
			@t.safe_eval("sleep", 0.1)
		end

		assert_nothing_raised(Timeout::Error) do
			@t.safe_eval("nil", 0.1)
		end

	end

	def test_define_method
		# failed on ruby1.9 (2007-09-24)
		assert_nothing_raised(SecurityError) do
			@t.safe_eval("def hoge; end")
		end

		@t.safe_eval <<-EOS
			def safe_eval(code)
				"Nice boat."
			end
		EOS
		assert_not_equal("Nice boat", @t.safe_eval("nil"))
	end

	def test_safe_access
		assert_raise(NoMethodError) do
			@t.safe_eval("@foo << :bar")
		end
		assert_equal(nil, @t.instance_variable_get(:@foo))

		assert_raise(NameError) do
			@t.safe_eval("@@foo")
		end

		assert_raise(SecurityError) do
			@t.safe_eval("@@foo = :foo")
		end
		
	end

end
