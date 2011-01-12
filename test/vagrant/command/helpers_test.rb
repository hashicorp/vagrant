require "test_helper"

class CommandHelpersTest < Test::Unit::TestCase
  setup do
    @module = Vagrant::Command::Helpers
    @command = Class.new(Vagrant::Command::Base) do
      argument :name, :optional => true, :type => :string
    end
  end

  def command(args, env)
    @command.new(args, {}, { :env => env })
  end

  context "initializing environment" do
    should "raise an exception if no environment is given" do
      assert_raises(Vagrant::Errors::CLIMissingEnvironment) { command([], nil) }
    end
  end

  context "vms from args" do
    setup do
      @env = vagrant_env
    end

    should "raise an exception if no root path" do
      @env.stubs(:root_path).returns(nil)

      assert_raises(Vagrant::Errors::NoEnvironmentError) {
        command([], @env).target_vms
      }
    end

    should "only calculate the result once" do
      instance = command([], @env)
      result = instance.target_vms
      assert instance.target_vms.equal?(result)
    end

    context "without multivm" do
      setup do
        @env.stubs(:vms_ordered => [1, 2], :vms => {:one => 1, :two => 2})
      end

      should "raise an exception if a name is specified" do
        instance = command(["foo"], vagrant_env)
        assert_raises(Vagrant::Errors::MultiVMEnvironmentRequired) {
          instance.target_vms
        }
      end

      should "return the VM if no name is specified" do
        instance = command([], @env)
        assert_nothing_raised {
          assert_equal @env.vms.values.sort, instance.target_vms.sort
        }
      end
    end

    context "with multivm" do
      setup do
        @env.stubs(:vms_ordered => [1, 2], :vms => {:one => 1, :two => 2})
      end

      should "return all the VMs if no name is specified" do
        instance = command([], @env)
        assert_equal @env.vms.values.sort, instance.target_vms.sort
      end

      should "return only the specified VM if a name is given" do
        instance = command(["one"], @env)
        assert_equal @env.vms[:one], instance.target_vms.first
      end

      should "return only the specified VM if name is given in the arg" do
        instance = command([], @env)
        assert_equal @env.vms[:two], instance.target_vms("two").first
      end

      should "raise an exception if an invalid name is given" do
        instance = command(["foo"], @env)
        assert_raises(Vagrant::Errors::VMNotFoundError) {
          instance.target_vms
        }
      end
    end
  end
end
