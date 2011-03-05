require "test_helper"

class BaseProvisionerTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Provisioners::Base
  end

  should "include the util class so subclasses have access to it" do
    assert Vagrant::Provisioners::Base.include?(Vagrant::Util)
  end

  context "registering provisioners" do
    teardown do
      @klass.registered.delete(:zomg)
    end

    should "not have unregistered provisioners" do
      assert_nil @klass.registered[:foo]
    end

    should "be able to register a provisioner" do
      foo = Class.new(@klass) do
        register :zomg
      end

      assert_equal foo, @klass.registered[:zomg]
    end
  end

  context "base instance" do
    setup do
      @env = Vagrant::Action::Environment.new(vagrant_env)
      @config = mock("config")
      @base = Vagrant::Provisioners::Base.new(@env, @config)
    end

    should "set the environment" do
      assert_equal @env.env, @base.env
    end

    should "return the VM which the provisioner is acting on" do
      assert_equal @env.env.vm, @base.vm
    end

    should "provide access to the config" do
      assert_equal @config, @base.config
    end

    should "implement provision! which does nothing" do
      assert_nothing_raised do
        assert @base.respond_to?(:provision!)
        @base.provision!
      end
    end

    should "implement prepare which does nothing" do
      assert_nothing_raised do
        assert @base.respond_to?(:prepare)
        @base.prepare
      end
    end
  end
end
