require File.join(File.dirname(__FILE__), '..', 'test_helper')

class CommandsTest < Test::Unit::TestCase
  setup do
    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:vm).returns(@persisted_vm)
    @env.stubs(:require_persisted_vm)
    Vagrant::Environment.stubs(:load!).returns(@env)
  end

  context "instance methods" do
    setup do
      @commands = Vagrant::Commands.new(@env)
    end

    context "initialization" do
      should "set up the environment variable" do
        env = mock("env")
        command = Vagrant::Commands.new(env)
        assert_equal env, command.env
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

      should "require a box" do
        @env.expects(:require_box).once
        @commands.up
      end

      should "call the up action on VM if it doesn't exist" do
        @new_vm.expects(:execute!).with(Vagrant::Actions::VM::Up).once
        @commands.up
      end

      should "call start on the persisted vm if it exists" do
        @env.stubs(:vm).returns(@persisted_vm)
        @persisted_vm.expects(:start).once
        @env.expects(:create_vm).never
        @commands.up
      end
    end

    context "destroy" do
      setup do
        @persisted_vm.stubs(:destroy)
      end

      should "require a persisted VM" do
        @env.expects(:require_persisted_vm).once
        @commands.destroy
      end

      should "destroy the persisted VM and the VM image" do
        @persisted_vm.expects(:destroy).once
        @commands.destroy
      end
    end

    context "reload" do
      should "require a persisted VM" do
        @env.expects(:require_persisted_vm).once
        @commands.reload
      end

      should "call the `reload` action on the VM" do
        @persisted_vm.expects(:execute!).with(Vagrant::Actions::VM::Reload).once
        @commands.reload
      end
    end

    context "ssh" do
      setup do
        @env.ssh.stubs(:connect)
      end

      should "require a persisted VM" do
        @env.expects(:require_persisted_vm).once
        @commands.ssh
      end

      should "connect to SSH" do
        @env.ssh.expects(:connect).once
        @commands.ssh
      end
    end

    context "halt" do
      should "require a persisted VM" do
        @env.expects(:require_persisted_vm).once
        @commands.halt
      end

      should "call the `halt` action on the VM" do
        @persisted_vm.expects(:execute!).with(Vagrant::Actions::VM::Halt).once
        @commands.halt
      end
    end

    context "suspend" do
      setup do
        @persisted_vm.stubs(:suspend)
        @persisted_vm.stubs(:saved?).returns(false)
      end

      should "require a persisted VM" do
        @env.expects(:require_persisted_vm).once
        @commands.suspend
      end

      should "suspend the VM" do
        @persisted_vm.expects(:suspend).once
        @commands.suspend
      end
    end

    context "resume" do
      setup do
        @persisted_vm.stubs(:resume)
        @persisted_vm.stubs(:saved?).returns(true)
      end

      should "require a persisted VM" do
        @env.expects(:require_persisted_vm).once
        @commands.resume
      end

      should "save the state of the VM" do
        @persisted_vm.expects(:resume).once
        @commands.resume
      end
    end

    context "package" do
      setup do
        @persisted_vm.stubs(:package)
        @persisted_vm.stubs(:powered_off?).returns(true)
      end

      context "with no base specified" do
        should "require a persisted vm" do
          @env.expects(:require_persisted_vm).once
          @commands.package
        end
      end

      context "with base specified" do
        setup do
          @vm = mock("vm")

          Vagrant::VM.stubs(:find).with(@name).returns(@vm)
          @vm.stubs(:env=).with(@env)
          @env.stubs(:vm=)

          @name = :bar
        end

        should "find the given base and set it on the env" do
          Vagrant::VM.expects(:find).with(@name).returns(@vm)
          @vm.expects(:env=).with(@env)
          @env.expects(:vm=).with(@vm)

          @commands.package("foo", { :base => @name })
        end

        should "error if the VM is not found" do
          Vagrant::VM.expects(:find).with(@name).returns(nil)
          @commands.expects(:error_and_exit).with(:vm_base_not_found, :name => @name).once

          @commands.package("foo", { :base => @name })
        end
      end

      context "shared (with and without base specified)" do
        should "error and exit if the VM is not powered off" do
          @persisted_vm.stubs(:powered_off?).returns(false)
          @commands.expects(:error_and_exit).with(:vm_power_off_to_package).once
          @persisted_vm.expects(:package).never
          @commands.package
        end

        should "call package on the persisted VM" do
          @persisted_vm.expects(:package).once
          @commands.package
        end

        should "pass the out path and include_files to the package method" do
          out_path = mock("out_path")
          include_files = mock("include_files")
          @persisted_vm.expects(:package).with(out_path, include_files).once
          @commands.package(out_path, {
            :include => include_files
          })
        end

        should "default to an empty array when not include_files are specified" do
          out_path = mock("out_path")
          @persisted_vm.expects(:package).with(out_path, []).once
          @commands.package(out_path)
        end
      end
    end

    context "box" do
      setup do
        @commands.stubs(:box_foo)
        @commands.stubs(:box_add)
        @commands.stubs(:box_remove)
      end

      should "error and exit if the first argument is not a valid subcommand" do
        @commands.expects(:error_and_exit).with(:command_box_invalid).once
        @commands.box(["foo"])
      end

      should "not error and exit if the first argument is a valid subcommand" do
        commands = ["add", "remove", "list"]

        commands.each do |command|
          @commands.expects(:error_and_exit).never
          @commands.expects("box_#{command}".to_sym).once
          @commands.box([command])
        end
      end

      should "forward any additional arguments" do
        @commands.expects(:box_add).with(@env, 1,2,3).once
        @commands.box(["add",1,2,3])
      end
    end

    context "box list" do
      setup do
        @boxes = ["foo", "bar"]

        Vagrant::Box.stubs(:all).returns(@boxes)
        @commands.stubs(:wrap_output)
      end

      should "call all on box and sort the results" do
        @all = mock("all")
        @all.expects(:sort).returns(@boxes)
        Vagrant::Box.expects(:all).with(@env).returns(@all)
        @commands.box_list(@env)
      end
    end

    context "box add" do
      setup do
        @name = "foo"
        @path = "bar"
      end

      should "execute the add action with the name and path" do
        Vagrant::Box.expects(:add).with(@env, @name, @path).once
        @commands.box_add(@env, @name, @path)
      end
    end

    context "box remove" do
      setup do
        @name = "foo"
      end

      should "error and exit if the box doesn't exist" do
        Vagrant::Box.expects(:find).returns(nil)
        @commands.expects(:error_and_exit).with(:box_remove_doesnt_exist).once
        @commands.box_remove(@env, @name)
      end

      should "call destroy on the box if it exists" do
        @box = mock("box")
        Vagrant::Box.expects(:find).with(@env, @name).returns(@box)
        @box.expects(:destroy).once
        @commands.box_remove(@env, @name)
      end
    end
  end

  context "class methods" do
    context "init" do
      setup do
        @file = mock("file")
        @file.stubs(:write)
        File.stubs(:open).yields(@file)
        @rootfile_path = File.join(Dir.pwd, Vagrant::Environment::ROOTFILE_NAME)

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
        Vagrant::Util::TemplateRenderer.expects(:render).with(Vagrant::Environment::ROOTFILE_NAME, :default_box => box)
        Vagrant::Commands.init(box)
      end

      should "use the default `base` if no box is given" do
        Vagrant::Util::TemplateRenderer.expects(:render).with(Vagrant::Environment::ROOTFILE_NAME, :default_box => "base")
        Vagrant::Commands.init
      end
    end

    context "executing commands in the current environment" do
      should "load the environment then send the command to the commands instance" do
        method = :foo
        args = [1,2,3]

        Vagrant::Environment.expects(:load!).returns(@env)
        @env.commands.expects(:send).with(method, *args).once
        Vagrant::Commands.execute(method, *args)
      end
    end
  end
end
