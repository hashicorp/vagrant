require "test_helper"

class PackageVagrantfileVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::PackageVagrantfile
    @app, @env = action_env

    @vm = mock("vm")
    @env["vm"] = @vm
    @env["export.temp_dir"] = "foo"

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "create the vagrantfile then continue chain" do
      seq = sequence("sequence")
      @instance.expects(:create_vagrantfile).in_sequence(seq)
      @app.expects(:call).with(@env).in_sequence(seq)

      @instance.call(@env)
    end
  end

  context "creating vagrantfile" do
    setup do
      @network_adapter = mock("nic")
      @network_adapter.stubs(:mac_address).returns("mac_address")
      @internal_vm.stubs(:network_adapters).returns([@network_adapter])
    end

    should "write the rendered vagrantfile to temp_path Vagrantfile" do
      f = mock("file")
      rendered = mock("rendered")
      File.expects(:open).with(File.join(@env["export.temp_dir"], "Vagrantfile"), "w").yields(f)
      Vagrant::Util::TemplateRenderer.expects(:render).returns(rendered).with("package_Vagrantfile", {
                                                                                :base_mac => @internal_vm.network_adapters.first.mac_address
                                                                              })
      f.expects(:write).with(rendered)

      @instance.create_vagrantfile
    end
  end
end
