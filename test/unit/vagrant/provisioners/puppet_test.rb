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

    should "return an empty array if no module path is set" do
      @config.module_path = nil
      assert_equal [], @config.expanded_module_paths
    end

    should "return array of module paths expanded relative to root path" do
      @config.module_path = "foo"

      result = @config.expanded_module_paths
      assert result.is_a?(Array)
      assert_equal 1, result.length
      assert_equal File.expand_path(@config.module_path, @env.root_path), result[0].to_s
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

    should "be invalid if a specified module path doesn't exist" do
      @config.module_path = "foo"
      @config.validate(@errors)
      assert !@errors.errors.empty?
    end

    should "be valid if all module paths exist" do
      @config.module_path = "foo"
      @config.expanded_module_paths.first.mkdir
      @config.validate(@errors)
      assert @errors.errors.empty?
    end
  end

  context "preparing" do
    should "share manifests" do
      pre_seq = sequence("prepare")
      @action.expects(:set_module_paths).once.in_sequence(pre_seq)
      @action.expects(:share_manifests).once.in_sequence(pre_seq)
      @action.expects(:share_module_paths).once.in_sequence(pre_seq)
      @action.prepare
    end
  end

  context "provisioning" do
    should "run the proper sequence of methods in order" do
      prov_seq = sequence("prov_seq")
      @action.expects(:verify_binary).with("puppet").once.in_sequence(prov_seq)
      @action.expects(:run_puppet_client).once.in_sequence(prov_seq)
      @action.provision!
    end
  end

  context "share manifests folder" do
    should "share manifest folder" do
      @env.config.vm.expects(:share_folder).with("manifests", @action.manifests_guest_path, @config.expanded_manifests_path)
      @action.share_manifests
    end
  end

  context "sharing module paths" do
    should "share all the module paths" do
      @config.module_path = ["foo", "bar"]
      @config.expanded_module_paths.each_with_index do |path, i|
        @env.config.vm.expects(:share_folder).with("v-pp-m#{i}", File.join(@config.pp_path, "modules-#{i}"), path)
      end

      @action.set_module_paths
      @action.share_module_paths
    end
  end

  context "verifying binary" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "verify binary exists" do
      binary = "foo"
      @ssh.expects(:sudo!).with("which #{binary}", anything)
      @action.verify_binary(binary)
    end
  end

  context "running puppet client" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
      @action.set_module_paths
    end

    def expect_puppet_command(command)
      @ssh.expects(:sudo!).with(["cd #{@action.manifests_guest_path}", command])
    end

    should "cd into the pp_path directory and run puppet" do
      expect_puppet_command("puppet apply #{@config.computed_manifest_file}")
      @action.run_puppet_client
    end

    should "cd into the pp_path directory and run puppet with given options when given as an array" do
      @config.options = ["--modulepath", "modules", "--verbose"]
      expect_puppet_command("puppet apply --modulepath modules --verbose #{@config.computed_manifest_file}")
      @action.run_puppet_client
    end

    should "cd into the pp_path directory and run puppet with the options when given as a string" do
      @config.options = "--modulepath modules --verbose"
      expect_puppet_command("puppet apply --modulepath modules --verbose #{@config.computed_manifest_file}")
      @action.run_puppet_client
    end

    should "cd into the pp_path and run puppet with module paths if set" do
      @config.module_path = "foo"
      expect_puppet_command("puppet apply --modulepath '#{File.join(@config.pp_path, 'modules-0')}' #{@config.computed_manifest_file}")

      @action.set_module_paths
      @action.run_puppet_client
    end
  end
end
