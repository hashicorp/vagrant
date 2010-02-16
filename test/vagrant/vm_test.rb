require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VMTest < Test::Unit::TestCase
  setup do
    @mock_vm = mock("vm")
    mock_config

    @persisted_vm = mock("persisted_vm")
    Vagrant::Env.stubs(:persisted_vm).returns(@persisted_vm)

    Net::SSH.stubs(:start)
  end

  context "callbacks" do
    setup do
      @vm = Vagrant::VM.new(@mock_vm)
    end

    context "around callbacks" do
      should "invoke before/after_name for around callbacks" do
        block_obj = mock("block_obj")
        around_seq = sequence("around_seq")
        @vm.expects(:invoke_callback).with(:before_foo).once.in_sequence(around_seq)
        block_obj.expects(:foo).once.in_sequence(around_seq)
        @vm.expects(:invoke_callback).with(:after_foo).once.in_sequence(around_seq)

        @vm.invoke_around_callback(:foo) do
          block_obj.foo
        end
      end

      should "forward arguments to invoke_callback" do
        @vm.expects(:invoke_callback).with(:before_foo, "foo").once
        @vm.expects(:invoke_callback).with(:after_foo, "foo").once
        @vm.invoke_around_callback(:foo, "foo") do; end
      end
    end

    should "not invoke callback on actions which don't respond to it" do
      action = mock("action")
      action.stubs(:respond_to?).with(:foo).returns(false)
      action.expects(:foo).never

      assert_nothing_raised do
        @vm.actions << action
        @vm.invoke_callback(:foo)
      end
    end

    should "invoke callback on actions which do respond to the method" do
      action = mock("action")
      action.expects(:foo).once

      @vm.actions << action
      @vm.invoke_callback(:foo)
    end

    should "collect all the results and return them as an array" do
      result = []
      3.times do |i|
        action = mock("action#{i}")
        action.expects(:foo).returns("foo#{i}").once

        @vm.actions << action
        result << "foo#{i}"
      end

      assert_equal result, @vm.invoke_callback(:foo)
    end
  end

  context "actions" do
    setup do
      @vm = Vagrant::VM.new(@mock_vm)
    end

    should "be empty initially" do
      assert @vm.actions.empty?
    end

    should "initialize the action when added" do
      action_klass = mock("action_class")
      action_inst = mock("action_inst")
      action_klass.expects(:new).once.returns(action_inst)
      @vm.add_action(action_klass)
      assert_equal 1, @vm.actions.length
    end

    should "initialize the action with given arguments when added" do
      action_klass = mock("action_class")
      action_klass.expects(:new).with(@vm, "foo", "bar").once
      @vm.add_action(action_klass, "foo", "bar")
    end

    should "run #prepare on all actions, then #execute!" do
      action_seq = sequence("action_seq")
      actions = []
      5.times do |i|
        action = mock("action#{i}")

        @vm.actions << action
        actions << action
      end

      [:prepare, :execute!].each do |method|
        actions.each do |action|
          action.expects(method).once.in_sequence(action_seq)
        end
      end

      @vm.execute!
    end

    should "run actions on class method execute!" do
      vm = mock("vm")
      execute_seq = sequence("execute_seq")
      Vagrant::VM.expects(:new).returns(vm).in_sequence(execute_seq)
      vm.expects(:add_action).with("foo").in_sequence(execute_seq)
      vm.expects(:execute!).once.in_sequence(execute_seq)

      Vagrant::VM.execute!("foo")
    end

    should "forward arguments to add_action on class method execute!" do
      vm = mock("vm")
      execute_seq = sequence("execute_seq")
      Vagrant::VM.expects(:new).returns(vm).in_sequence(execute_seq)
      vm.expects(:add_action).with("foo", "bar", "baz").in_sequence(execute_seq)
      vm.expects(:execute!).once.in_sequence(execute_seq)

      Vagrant::VM.execute!("foo", "bar", "baz")
    end
  end

  context "finding a VM" do
    should "return nil if the VM is not found" do
      VirtualBox::VM.expects(:find).returns(nil)
      assert_nil Vagrant::VM.find("foo")
    end

    should "return a Vagrant::VM object for that VM otherwise" do
      VirtualBox::VM.expects(:find).with("foo").returns("bar")
      result = Vagrant::VM.find("foo")
      assert result.is_a?(Vagrant::VM)
      assert_equal "bar", result.vm
    end
  end

  context "vagrant VM instance" do
    setup do
      @vm = Vagrant::VM.new(@mock_vm)
    end

    context "destroying" do
      setup do
        @mock_vm.stubs(:running?).returns(false)
      end

      should "destoy the VM along with images" do
        @mock_vm.expects(:destroy).with(:destroy_image => true).once
        @vm.destroy
      end

      should "stop the VM if its running" do
        @mock_vm.expects(:running?).returns(true)
        @mock_vm.expects(:stop).with(true)
        @mock_vm.expects(:destroy).with(:destroy_image => true).once
        @vm.destroy
      end
    end

    context "saving the state" do
      should "check if a VM is saved" do
        @mock_vm.expects(:saved?).returns("foo")
        assert_equal "foo", @vm.saved?
      end

      should "save state with errors raised" do
        @mock_vm.expects(:save_state).with(true).once
        @vm.save_state
      end
    end
  end

  # TODO more comprehensive testing
  context "packaging a vm" do
    should "dump the three necessary files to a tar in the current working dir" do
      location = FileUtils.pwd
      name = 'vagrant'
      new_dir = File.join(location, name)
      @mock_vm.expects(:export).with(File.join(new_dir, "#{name}.ovf"))
      FileUtils.expects(:mkpath).with(new_dir).returns(new_dir)
      FileUtils.expects(:rm_r).with(new_dir)
      Zlib::GzipWriter.expects(:open).with("#{location}/#{name}.box")

      # TODO test whats passed to the open tar.append_tree
      assert_equal Vagrant::VM.new(@mock_vm).package(name, location), "#{new_dir}.box"
    end
  end

  context "unpackaging a vm" do

    # TODO test actual decompression
    should "call decompress with the path to the file and the directory to decompress to" do
      working_dir = File.join FileUtils.pwd, 'something'
      file = File.join(FileUtils.pwd, 'something.box')
      FileUtils.expects(:mkpath).with(working_dir).once
      FileUtils.expects(:mv).with(working_dir, Vagrant.config[:vagrant][:home]).once
      Vagrant::VM.expects(:decompress).with(file, working_dir).once
      Vagrant::VM.unpackage(file)

    end
  end
end
