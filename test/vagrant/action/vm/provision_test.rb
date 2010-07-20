require "test_helper"

class ProvisionVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Provision
    @app, @env = mock_action_data

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @vm.stubs(:ssh).returns(mock("ssh"))
    @vm.stubs(:system).returns(mock("system"))
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
  end

  context "initializing" do
    setup do
      @klass.any_instance.stubs(:load_provisioner)
    end

    should "load provisioner if provisioning enabled" do
      @env["config"].vm.provisioner = :chef_solo
      @klass.any_instance.expects(:load_provisioner).once
      @klass.new(@app, @env)
    end

    should "not load provisioner if disabled" do
      @env["config"].vm.provisioner = nil
      @klass.any_instance.expects(:load_provisioner).never
      @klass.new(@app, @env)
    end
  end

  context "with an instance" do
    setup do
      # Set provisioner to nil so the provisioner isn't loaded on init
      @env["config"].vm.provisioner = nil
      @instance = @klass.new(@app, @env)
    end

    context "loading a provisioner" do
      context "with a Class provisioner" do
        setup do
          @prov = mock("instance")
          @prov.stubs(:is_a?).with(Vagrant::Provisioners::Base).returns(true)
          @prov.stubs(:prepare)
          @klass = mock("klass")
          @klass.stubs(:is_a?).with(Class).returns(true)
          @klass.stubs(:new).with(@env).returns(@prov)

          @env["config"].vm.provisioner = @klass
        end

        should "set the provisioner to an instantiation of the class" do
          @klass.expects(:new).with(@env).once.returns(@prov)
          assert_equal @prov, @instance.load_provisioner
        end

        should "call prepare on the instance" do
          @prov.expects(:prepare).once
          @instance.load_provisioner
        end

        should "error environment if the class is not a subclass of the provisioner base" do
          @prov.expects(:is_a?).with(Vagrant::Provisioners::Base).returns(false)
          @instance.load_provisioner
          assert @env.error?
          assert_equal :provisioner_invalid_class, @env.error.first
        end
      end

      context "with a Symbol provisioner" do
        def provisioner_expectation(symbol, provisioner)
          @env[:config].vm.provisioner = symbol

          instance = mock("instance")
          instance.expects(:prepare).once
          provisioner.expects(:new).with(@env).returns(instance)
          assert_equal instance, @instance.load_provisioner
        end

        should "raise an ActionException if its an unknown symbol" do
          @env["config"].vm.provisioner = :this_will_never_exist
          @instance.load_provisioner
          assert @env.error?
          assert_equal :provisioner_unknown_type, @env.error.first
        end

        should "set :chef_solo to the ChefSolo provisioner" do
          provisioner_expectation(:chef_solo, Vagrant::Provisioners::ChefSolo)
        end

        should "set :chef_server to the ChefServer provisioner" do
          provisioner_expectation(:chef_server, Vagrant::Provisioners::ChefServer)
        end
      end
    end

    context "calling" do
      setup do
        Vagrant::Provisioners::ChefSolo.any_instance.stubs(:prepare)
        @env["config"].vm.provisioner = :chef_solo
        @prov = @instance.load_provisioner
      end

      should "provision and continue chain" do
        seq = sequence("seq")
        @app.expects(:call).with(@env).in_sequence(seq)
        @prov.expects(:provision!).in_sequence(seq)

        @instance.call(@env)
      end

      should "continue chain and not provision if not enabled" do
        @env["config"].vm.provisioner = nil
        @prov.expects(:provision!).never
        @app.expects(:call).with(@env).once

        @instance.call(@env)
      end

      should "not provision if erroneous environment" do
        @env.error!(:foo)

        @prov.expects(:provision!).never
        @app.expects(:call).with(@env).once

        @instance.call(@env)
      end
    end
  end
end
