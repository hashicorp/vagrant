require "test_helper"

class ShellProvisionerTest < Test::Unit::TestCase
  setup do
    clean_paths

    @klass = Vagrant::Provisioners::Shell
    @action_env = Vagrant::Action::Environment.new(vagrant_env.vms[:default].env)
    @config = @klass::Config.new
    @config.top = Vagrant::Config::Top.new(@action_env.env)
    @action = @klass.new(@action_env, @config)

    @config.path = "foo"
  end

  context "config" do
    setup do
      @errors = Vagrant::Config::ErrorRecorder.new

      # Start in a valid state (verified by a test below)
      @config.path = "foo"
      File.open(@config.expanded_path, "w") { |f| f.puts "HELLO" }
    end

    should "be valid" do
      @config.validate(@errors)
      assert @errors.errors.empty?
    end

    should "be invalid if the path is not set" do
      @config.path = nil

      @config.validate(@errors)
      assert !@errors.errors.empty?
    end

    should "be invalid if the path does not exist" do
      @config.path = "bar"

      @config.validate(@errors)
      assert !@errors.errors.empty?
    end

    should "be invalid if the upload path is not set" do
      @config.upload_path = nil

      @config.validate(@errors)
      assert !@errors.errors.empty?
    end
  end

  context "provisioning" do
    setup do
      @ssh = mock("ssh")
      @action.vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "upload the file, chmod, then execute it" do
      commands = ["chmod +x #{@config.upload_path}", @config.upload_path]

      p_seq = sequence("provisioning")
      @action.vm.ssh.expects(:upload!).with(@config.expanded_path.to_s, @config.upload_path).in_sequence(p_seq)
      @ssh.expects(:sudo!).with(commands).in_sequence(p_seq)

      @action.provision!
    end

    should "append arguments if provided" do
      @config.args = "foo bar baz"
      commands = ["chmod +x #{@config.upload_path}", "#{@config.upload_path} #{@config.args}"]

      p_seq = sequence("provisioning")
      @action.vm.ssh.expects(:upload!).with(@config.expanded_path.to_s, @config.upload_path).in_sequence(p_seq)
      @ssh.expects(:sudo!).with(commands).in_sequence(p_seq)

      @action.provision!
    end
  end
end
