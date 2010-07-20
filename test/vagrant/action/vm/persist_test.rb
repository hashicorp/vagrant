require "test_helper"

class PersistVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Persist
    @app, @env = mock_action_data

    @vm = mock("vm")
    @vm.stubs(:uuid).returns("123")
    @env["vm"] = @vm
  end

  context "initializing" do
    setup do
      File.stubs(:file?).returns(true)
      File.stubs(:exist?).returns(true)
      @dotfile_path = "foo"
      @env.env.stubs(:dotfile_path).returns(@dotfile_path)
    end

    should "error environment if dotfile exists but is not a file" do
      File.expects(:file?).with(@env.env.dotfile_path).returns(false)
      @klass.new(@app, @env)
      assert @env.error?
      assert_equal :dotfile_error, @env.error.first
    end

    should "initialize properly if dotfiles doesn't exist" do
      File.expects(:exist?).with(@env.env.dotfile_path).returns(false)
      @klass.new(@app, @env)
      assert !@env.error?
    end
  end

  context "with an instance" do
    setup do
      File.stubs(:file?).returns(true)
      File.stubs(:exist?).returns(true)
      @instance = @klass.new(@app, @env)
    end

    should "persist the dotfile then continue chain" do
      update_seq = sequence("update_seq")
      @env.env.expects(:update_dotfile).in_sequence(update_seq)
      @app.expects(:call).with(@env).in_sequence(update_seq)

      @instance.call(@env)
    end
  end
end
