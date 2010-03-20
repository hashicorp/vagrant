require File.join(File.dirname(__FILE__), '..', 'test_helper')

class CommandsTest < Test::Unit::TestCase
  setup do
    Vagrant::Env.stubs(:load!)

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)
    Vagrant::Env.stubs(:persisted_vm).returns(@persisted_vm)
    Vagrant::Env.stubs(:require_persisted_vm)

    @env = mock_environment
    @env.stubs(:vm).returns(@persisted_vm)
    @env.stubs(:require_persisted_vm)
    Vagrant::Environment.stubs(:load!).returns(@env)
  end

  context "init" do
    setup do
      @file = mock("file")
      @file.stubs(:write)
      File.stubs(:open).yields(@file)
      @rootfile_path = File.join(Dir.pwd, Vagrant::Env::ROOTFILE_NAME)

      Vagrant::Util::TemplateRenderer.stubs(:render)
    end

    should "error and exit if a rootfile already exists" do
      File.expects(:exist?).with(@rootfile_path).returns(true)
      Vagrant::Commands.expects(:error_and_exit).with(:rootfile_already_exists).once
      Vagrant::Commands.init
    end

    should "write to the rootfile path using the template renderer" do
      result = "foo"
      Vagrant::Util::TemplateRenderer.expects(:render).returns(result).once
      @file.expects(:write).with(result).once
      File.expects(:open).with(@rootfile_path, 'w+').yields(@file)

      Vagrant::Commands.init
    end

    should "use the given base box if given" do
      box = "zooo"
      Vagrant::Util::TemplateRenderer.expects(:render).with(Vagrant::Env::ROOTFILE_NAME, :default_box => box)
      Vagrant::Commands.init(box)
    end

    should "use the default `base` if no box is given" do
      Vagrant::Util::TemplateRenderer.expects(:render).with(Vagrant::Env::ROOTFILE_NAME, :default_box => "base")
      Vagrant::Commands.init
    end
  end

  context "up" do
    setup do
      @new_vm = mock("vm")
      @new_vm.stubs(:execute!)

      @env.stubs(:vm).returns(nil)
      @env.stubs(:require_box)
      @env.stubs(:create_vm).returns(@new_vm)
    end

    should "require load the environment" do
      Vagrant::Environment.expects(:load!).once.returns(@env)
      Vagrant::Commands.up
    end

    should "require a box" do
      @env.expects(:require_box).once
      Vagrant::Commands.up
    end

    should "call the up action on VM if it doesn't exist" do
      @new_vm.expects(:execute!).with(Vagrant::Actions::VM::Up).once
      Vagrant::Commands.up
    end

    should "call start on the persisted vm if it exists" do
      @env.stubs(:vm).returns(@persisted_vm)
      @persisted_vm.expects(:start).once
      @env.expects(:create_vm).never
      Vagrant::Commands.up
    end
  end

  context "down" do
    setup do
      @persisted_vm.stubs(:destroy)
    end

    should "load the current environment" do
      Vagrant::Environment.expects(:load!).once.returns(@env)
      Vagrant::Commands.down
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      Vagrant::Commands.down
    end

    should "destroy the persisted VM and the VM image" do
      @persisted_vm.expects(:destroy).once
      Vagrant::Commands.down
    end
  end

  context "reload" do
    should "load the current environment" do
      Vagrant::Environment.expects(:load!).once.returns(@env)
      Vagrant::Commands.reload
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      Vagrant::Commands.reload
    end

    should "call the `reload` action on the VM" do
      @persisted_vm.expects(:execute!).with(Vagrant::Actions::VM::Reload).once
      Vagrant::Commands.reload
    end
  end

  context "ssh" do
    setup do
      @env.ssh.stubs(:connect)
    end

    should "load the current environment" do
      Vagrant::Environment.expects(:load!).once.returns(@env)
      Vagrant::Commands.ssh
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      Vagrant::Commands.ssh
    end

    should "connect to SSH" do
      @env.ssh.expects(:connect).once
      Vagrant::Commands.ssh
    end
  end

  context "halt" do
    should "load the current environment" do
      Vagrant::Environment.expects(:load!).once.returns(@env)
      Vagrant::Commands.halt
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      Vagrant::Commands.halt
    end

    should "call the `halt` action on the VM" do
      @persisted_vm.expects(:execute!).with(Vagrant::Actions::VM::Halt).once
      Vagrant::Commands.halt
    end
  end

  context "suspend" do
    setup do
      @persisted_vm.stubs(:suspend)
      @persisted_vm.stubs(:saved?).returns(false)
    end

    should "load the current environment" do
      Vagrant::Environment.expects(:load!).once.returns(@env)
      Vagrant::Commands.suspend
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      Vagrant::Commands.suspend
    end

    should "suspend the VM" do
      @persisted_vm.expects(:suspend).once
      Vagrant::Commands.suspend
    end
  end

  context "resume" do
    setup do
      @persisted_vm.stubs(:resume)
      @persisted_vm.stubs(:saved?).returns(true)
    end

    should "load the current environment" do
      Vagrant::Environment.expects(:load!).once.returns(@env)
      Vagrant::Commands.resume
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      Vagrant::Commands.resume
    end

    should "save the state of the VM" do
      @persisted_vm.expects(:resume).once
      Vagrant::Commands.resume
    end
  end

  context "package" do
    setup do
      @persisted_vm.stubs(:package)
      @persisted_vm.stubs(:powered_off?).returns(true)
    end

    should "load the current environment" do
      Vagrant::Environment.expects(:load!).once.returns(@env)
      Vagrant::Commands.package
    end

    should "require a persisted vm" do
      @env.expects(:require_persisted_vm).once
      Vagrant::Commands.package
    end

    should "error and exit if the VM is not powered off" do
      @persisted_vm.stubs(:powered_off?).returns(false)
      Vagrant::Commands.expects(:error_and_exit).with(:vm_power_off_to_package).once
      @persisted_vm.expects(:package).never
      Vagrant::Commands.package
    end

    should "call package on the persisted VM" do
      @persisted_vm.expects(:package).once
      Vagrant::Commands.package
    end

    should "pass the out path and include_files to the package method" do
      out_path = mock("out_path")
      include_files = mock("include_files")
      @persisted_vm.expects(:package).with(out_path, include_files).once
      Vagrant::Commands.package(out_path, include_files)
    end

    should "default to an empty array when not include_files are specified" do
      out_path = mock("out_path")
      @persisted_vm.expects(:package).with(out_path, []).once
      Vagrant::Commands.package(out_path)
    end
  end

  context "box" do
    setup do
      Vagrant::Commands.stubs(:box_foo)
      Vagrant::Commands.stubs(:box_add)
      Vagrant::Commands.stubs(:box_remove)
    end

    should "load the environment" do
      Vagrant::Env.expects(:load!).once
      Vagrant::Commands.box(["add"])
    end

    should "error and exit if the first argument is not a valid subcommand" do
      Vagrant::Commands.expects(:error_and_exit).with(:command_box_invalid).once
      Vagrant::Commands.box(["foo"])
    end

    should "not error and exit if the first argument is a valid subcommand" do
      commands = ["add", "remove"]

      commands.each do |command|
        Vagrant::Commands.expects(:error_and_exit).never
        Vagrant::Commands.expects("box_#{command}".to_sym).once
        Vagrant::Commands.box([command])
      end
    end

    should "forward any additional arguments" do
      Vagrant::Commands.expects(:box_add).with(1,2,3).once
      Vagrant::Commands.box(["add",1,2,3])
    end
  end

  context "box list" do
    setup do
      @boxes = ["foo", "bar"]

      Vagrant::Box.stubs(:all).returns(@boxes)
      Vagrant::Commands.stubs(:puts)
    end

    should "call all on box and sort the results" do
      @all = mock("all")
      @all.expects(:sort).returns(@boxes)
      Vagrant::Box.expects(:all).returns(@all)
      Vagrant::Commands.box_list
    end
  end

  context "box add" do
    setup do
      @name = "foo"
      @path = "bar"
    end

    should "execute the add action with the name and path" do
      Vagrant::Box.expects(:add).with(@name, @path).once
      Vagrant::Commands.box_add(@name, @path)
    end
  end

  context "box remove" do
    setup do
      @name = "foo"
    end

    should "error and exit if the box doesn't exist" do
      Vagrant::Box.expects(:find).returns(nil)
      Vagrant::Commands.expects(:error_and_exit).with(:box_remove_doesnt_exist).once
      Vagrant::Commands.box_remove(@name)
    end

    should "call destroy on the box if it exists" do
      @box = mock("box")
      Vagrant::Box.expects(:find).with(@name).returns(@box)
      @box.expects(:destroy).once
      Vagrant::Commands.box_remove(@name)
    end
  end
end
