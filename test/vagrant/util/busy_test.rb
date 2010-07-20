require "test_helper"

class BusyUtilTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Util::Busy
  end

  context "registering" do
    setup do
      @callback = lambda { puts "FOO" }
      Signal.stubs(:trap)
    end

    teardown do
      @klass.registered.clear
    end

    should "trap the signal on the first registration" do
      Signal.expects(:trap).with("INT").once
      @klass.register(@callback)
      @klass.register(lambda { puts "BAR" })
    end

    should "not register the same callback multiple times" do
      @klass.register(@callback)
      @klass.register(@callback)
      @klass.register(@callback)
      assert_equal 1, @klass.registered.length
      assert_equal @callback, @klass.registered.first
    end
  end

  context "unregistering" do
    setup do
      Signal.stubs(:trap)

      @callback = lambda { puts "FOO" }
    end

    teardown do
      @klass.registered.clear
    end

    should "remove the callback and set the trap to DEFAULT when removing final" do
      @klass.register(@callback)
      Signal.expects(:trap).with("INT", "DEFAULT").once
      @klass.unregister(@callback)
      assert @klass.registered.empty?
    end

    should "not reset signal trap if not final callback" do
      @klass.register(@callback)
      @klass.register(lambda { puts "BAR" })
      Signal.expects(:trap).never
      @klass.unregister(@callback)
    end
  end

  context "marking for busy" do
    setup do
      @callback = lambda { "foo" }
    end

    should "register, call the block, then unregister" do
      waiter = mock("waiting")
      proc = lambda { waiter.ping! }

      seq = sequence('seq')
      @klass.expects(:register).with(@callback).in_sequence(seq)
      waiter.expects(:ping!).in_sequence(seq)
      @klass.expects(:unregister).with(@callback).in_sequence(seq)

      @klass.busy(@callback, &proc)
    end

    should "unregister callback even if block raises exception" do
      waiter = mock("waiting")
      proc = lambda { waiter.ping! }

      seq = sequence('seq')
      @klass.expects(:register).with(@callback).in_sequence(seq)
      waiter.expects(:ping!).raises(Exception.new("uh oh!")).in_sequence(seq)
      @klass.expects(:unregister).with(@callback).in_sequence(seq)

      assert_raises(Exception) { @klass.busy(@callback, &proc) }
    end
  end

  context "firing callbacks" do
    setup do
      Signal.stubs(:trap)
    end

    teardown do
      @klass.registered.clear
    end

    should "just call the registered callbacks" do
      waiting = mock("waiting")
      waiting.expects(:ping!).once

      @klass.register(lambda { waiting.ping! })
      @klass.fire_callbacks
    end
  end
end
