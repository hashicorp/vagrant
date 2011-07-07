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

  context "with an instance" do
    setup do
      # Set provisioner to nil so the provisioner isn't loaded on init
      @env["config"].vm.provisioners.clear
      @instance = @klass.new(@app, @env)
    end

    context "loading a provisioner" do
      should "instantiate and prepare each provisioner" do
        @env["config"].vm.provision :chef_solo
        @env["config"].vm.provision :chef_solo
        provisioners = @instance.enabled_provisioners

        assert_equal 2, provisioners.length
      end

      should "set the config for each provisioner" do
        @env["config"].vm.provision :chef_solo do |chef|
          chef.cookbooks_path = "foo"
        end

        provisioners = @instance.enabled_provisioners

        assert_equal "foo", provisioners.first.config.cookbooks_path
      end
    end

    context "calling" do
      should "provision and continue chain" do
        provisioners = [mock("one"), mock("two")]
        seq = sequence("seq")
        @instance.stubs(:enabled_provisioners).returns(provisioners)

        provisioners.each do |prov|
          prov.expects(:prepare).in_sequence(seq)
        end

        @app.expects(:call).with(@env).in_sequence(seq)

        provisioners.each do |prov|
          prov.expects(:provision!).in_sequence(seq)
        end

        @instance.call(@env)
      end
    end
  end
end
