require "test_helper"

class PuppetProvisionerTest < Test::Unit::TestCase
  setup do
    clean_paths

    @klass = Vagrant::Provisioners::Puppet

    @action_env = Vagrant::Action::Environment.new(vagrant_env.vms[:default].env)

    @config = @klass::Config.new
    @config.top = Vagrant::Config::Top.new(@action_env.env)
    @config.top.vm.box = "foo"
    @action = @klass.new(@action_env, @config)
    @env = @action.env
    @vm = @action.vm
  end

  context "config" do
    setup do
      @errors = Vagrant::Config::ErrorRecorder.new

      # Set a box
      @config.top.vm.box = "foo"

      # Start in a valid state (verified by the first test)
      @config.expanded_manifests_path.mkdir
      File.open(@config.expanded_manifests_path.join(@config.computed_manifest_file), "w") { |f| f.puts "HELLO" }
    end

    should "expand the manifest path relative to the root path" do
      assert_equal File.expand_path(@config.manifests_path, @env.root_path), @config.expanded_manifests_path.to_s
    end

    should "default the manifest file to the box name" do
      assert_equal "#{@config.top.vm.box}.pp", @config.computed_manifest_file
    end

    should "use the custom manifest file if set" do
      @config.manifest_file = "woot.pp"
      assert_equal "woot.pp", @config.computed_manifest_file
    end

    should "be valid" do
      @config.validate(@errors)
      assert @errors.errors.empty?
    end

    should "be invalid if the manifests path doesn't exist" do
      @config.expanded_manifests_path.rmtree
      @config.validate(@errors)
      assert !@errors.errors.empty?
    end

    should "be invalid if a custom manifests path doesn't exist" do
      @config.manifests_path = "dont_exist"
      @config.validate(@errors)
      assert !@errors.errors.empty?
    end

    should "be invalid if the manifest file doesn't exist" do
      @config.expanded_manifests_path.join(@config.computed_manifest_file).unlink
      @config.validate(@errors)
      assert !@errors.errors.empty?
    end
  end

  context "preparing" do
    should "share manifests" do
      @action.expects(:share_manifests).once
      @action.prepare
    end
  end

  context "provisioning" do
    should "run the proper sequence of methods in order" do
      prov_seq = sequence("prov_seq")
      @action.expects(:verify_binary).with("puppet").once.in_sequence(prov_seq)
      @action.expects(:create_pp_path).once.in_sequence(prov_seq)
      @action.expects(:run_puppet_client).once.in_sequence(prov_seq)
      @action.provision!
    end
  end

  context "share manifests folder" do
    setup do
      @manifests_path = "manifests"
      @pp_path = "/tmp/vagrant-puppet"
      @action.stubs(:manifests_path).returns(@manifests_path)
      @action.stubs(:pp_path).returns(@pp_path)
    end

    should "share manifest folder" do
      @env.config.vm.expects(:share_folder).with("manifests", @pp_path, @manifests_path)
      @action.share_manifests
    end
  end

  context "verifying binary" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "verify binary exists" do
      binary = "foo"
      @ssh.expects(:exec!).with("sudo -i which #{binary}", anything)
      @action.verify_binary(binary)
    end
  end

  context "create pp path" do
    should "create and chown the folder to the ssh user" do
      ssh_seq = sequence("ssh_seq")
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo mkdir -p #{@config.pp_path}").once.in_sequence(ssh_seq)
      ssh.expects(:exec!).with("sudo chown #{@env.config.ssh.username} #{@config.pp_path}").once.in_sequence(ssh_seq)
      @vm.ssh.expects(:execute).yields(ssh)
      @action.create_pp_path
    end
  end

  context "running puppet client" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    def expect_puppet_command(command)
      @ssh.expects(:exec!).with("sudo -i 'cd #{@config.pp_path}; #{command}'")
    end

    should "cd into the pp_path directory and run puppet" do
      expect_puppet_command("puppet #{@config.computed_manifest_file}")
      @action.run_puppet_client
    end

    should "cd into the pp_path directory and run puppet with given options when given as an array" do
      @config.options = ["--modulepath", "modules", "--verbose"]
      expect_puppet_command("puppet --modulepath modules --verbose #{@config.computed_manifest_file}")
      @action.run_puppet_client
    end

    should "cd into the pp_path directory and run puppet with the options when given as a string" do
      @config.options = "--modulepath modules --verbose"
      expect_puppet_command("puppet --modulepath modules --verbose #{@config.computed_manifest_file}")
      @action.run_puppet_client
    end
  end
end
