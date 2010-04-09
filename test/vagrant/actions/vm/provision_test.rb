require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ProvisionActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Provision)
  end

  context "initialization" do
    should "have a nil provisioner by default" do
      assert_nil @action.provisioner
    end
  end

  context "executing" do
    should "do nothing if the provisioner is nil" do
      @action.expects(:provisioner).returns(nil)
      assert_nothing_raised { @action.execute! }
    end

    should "call `provision!` on the provisioner" do
      provisioner = mock("provisioner")
      provisioner.expects(:provision!).once
      @action.expects(:provisioner).twice.returns(provisioner)
      @action.execute!
    end
  end

  context "preparing" do
    context "with a nil provisioner" do
      setup do
        @runner.env.config.vm.provisioner = nil
      end

      should "not set a provisioner if set to nil" do
        @action.prepare
        assert_nil @action.provisioner
      end
    end

    context "with a Class provisioner" do
      setup do
        @instance = mock("instance")
        @instance.stubs(:is_a?).with(Vagrant::Provisioners::Base).returns(true)
        @instance.stubs(:prepare)
        @klass = mock("klass")
        @klass.stubs(:is_a?).with(Class).returns(true)
        @klass.stubs(:new).with(@runner.env).returns(@instance)

        @runner.env.config.vm.provisioner = @klass
      end

      should "set the provisioner to an instantiation of the class" do
        @klass.expects(:new).with(@runner.env).once.returns(@instance)
        assert_nothing_raised { @action.prepare }
        assert_equal @instance, @action.provisioner
      end

      should "call prepare on the instance" do
        @instance.expects(:prepare).once
        @action.prepare
      end

      should "raise an exception if the class is not a subclass of the provisioner base" do
        @instance.expects(:is_a?).with(Vagrant::Provisioners::Base).returns(false)
        assert_raises(Vagrant::Actions::ActionException) {
          @action.prepare
        }
      end
    end

    context "with a Symbol provisioner" do
      def provisioner_expectation(symbol, provisioner)
        @runner.env.config.vm.provisioner = symbol

        instance = mock("instance")
        instance.expects(:prepare).once
        provisioner.expects(:new).with(@runner.env).returns(instance)
        assert_nothing_raised { @action.prepare }
        assert_equal instance, @action.provisioner
      end

      should "raise an ActionException if its an unknown symbol" do
        @runner.env.config.vm.provisioner = :this_will_never_exist

        assert_raises(Vagrant::Actions::ActionException) {
          @action.prepare
        }
      end

      should "set :chef_solo to the ChefSolo provisioner" do
        provisioner_expectation(:chef_solo, Vagrant::Provisioners::ChefSolo)
      end

      should "set :chef_server to the ChefServer provisioner" do
        provisioner_expectation(:chef_server, Vagrant::Provisioners::ChefServer)
      end
    end
  end
end
