require "test_helper"

class ProvisionVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Provision
    @app, @env = action_env

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
      @klass.any_instance.stubs(:load_provisioners)
    end

    should "load provisioner if provisioning enabled" do
      @env["config"].vm.provision :chef_solo
      @klass.any_instance.expects(:load_provisioners).once
      @klass.new(@app, @env)
    end

    should "not load provisioner if disabled" do
      @klass.any_instance.expects(:load_provisioners).never
      @klass.new(@app, @env)
    end

    should "not load provisioner if disabled through env hash" do
      @env["provision.enabled"] = false
      @klass.any_instance.expects(:load_provisioners).never
      @klass.new(@app, @env)
    end
  end

  context "with an instance" do
    setup do
      # Set provisioner to nil so the provisioner isn't loaded on init
      @env["config"].vm.provisioners.clear
      @instance = @klass.new(@app, @env)
    end

    context "loading a provisioner" do
      setup do
        Vagrant::Provisioners::ChefSolo.any_instance.expects(:prepare).at_least(0)
      end

      should "instantiate and prepare each provisioner" do
        @env["config"].vm.provision :chef_solo
        @env["config"].vm.provision :chef_solo
        @instance.load_provisioners

        assert_equal 2, @instance.provisioners.length
      end

      should "set the config for each provisioner" do
        @env["config"].vm.provision :chef_solo do |chef|
          chef.cookbooks_path = "foo"
        end

        @instance.load_provisioners

        assert_equal "foo", @instance.provisioners.first.config.cookbooks_path
      end
    end

    context "loading specific provisioners" do
      setup do
        Vagrant::Provisioners::ChefSolo.any_instance.expects(:prepare).at_least(0)
        @env["config"].vm.provisioners.clear
      end

      should "only load the specified provisioner" do
        @env["config"].vm.provision :chef_solo
        @env["config"].vm.provision :shell
        @env["provision.provisioners"] = ["chef_solo"]
        @instance = @klass.new(@app, @env)

        assert_equal 1, @instance.provisioners.length
      end

      should "only load the specified provisioners" do
        @env["config"].vm.provision :chef_solo
        @env["config"].vm.provision :shell
        @env["config"].vm.provision :chef_server
        @env["provision.provisioners"] = ["chef_solo", "shell"]
        @instance = @klass.new(@app, @env)

        assert_equal 2, @instance.provisioners.length
      end

      should "raise an error if the specified provisioner does not exist" do
        @env["provision.provisioners"] = ["chef_solo"]
        @env["config"].vm.provision :shell
        @env["config"].vm.provision :chef_server
        
        assert_raises(Vagrant::Errors::ProvisionerDoesNotExist) do
          @instance = @klass.new(@app, @env)
        end
      end
    end

    context "calling" do
      setup do
        Vagrant::Provisioners::ChefSolo.any_instance.stubs(:prepare)
        @env["config"].vm.provision :chef_solo
        @instance.load_provisioners
      end

      should "provision and continue chain" do
        seq = sequence("seq")
        @app.expects(:call).with(@env).in_sequence(seq)
        @instance.provisioners.each do |prov|
          prov.expects(:provision!).in_sequence(seq)
        end

        @instance.call(@env)
      end
    end
  end
end
