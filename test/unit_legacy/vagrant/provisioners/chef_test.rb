require "test_helper"

class ChefProvisionerTest < Test::Unit::TestCase
  setup do
    @action_env = Vagrant::Action::Environment.new(vagrant_env.vms[:default].env)

    @klass = Vagrant::Provisioners::Chef
    @config = @klass::Config.new
    @action = @klass.new(@action_env, @config)
    @env = @action.env
    @vm = @action.vm
  end

  context "preparing" do
    should "error the environment" do
      assert_raises(@klass::ChefError) {
        @action.prepare
      }
    end
  end

  context "config" do
    should "not include the 'json' key in the config dump" do
      result = @config.to_json
      assert result !~ /"json":/
    end

    should "not include the 'run_list' key in json if not accessed" do
      result = @config.merged_json
      assert !result.has_key?(:run_list)
    end

    should "include the 'run_list' key in json if it is set" do
      @config.run_list << "foo"
      result = @config.merged_json
      assert result.has_key?(:run_list)
    end

    should "provide accessors to the run list" do
      @config.run_list << "foo"
      assert !@config.run_list.empty?
      assert_equal ["foo"], @config.run_list
    end

    should "provide a writer for the run list" do
      data = mock("data")

      assert_nothing_raised {
        @config.run_list = data
        assert_equal data, @config.run_list
      }
    end

    should "have an empty run list to begin with" do
      assert @config.run_list.empty?
    end

    should "add a recipe to the run list" do
      @config.add_recipe("foo")
      assert_equal "recipe[foo]", @config.run_list[0]
    end

    should "not wrap the recipe in 'recipe[]' if it was in the name" do
      @config.add_recipe("recipe[foo]")
      assert_equal "recipe[foo]", @config.run_list[0]
    end

    should "add a role to the run list" do
      @config.add_role("user")
      assert_equal "role[user]", @config.run_list[0]
    end

    should "not wrap the role in 'role[]' if it was in the name" do
      @config.add_role("role[user]")
      assert_equal "role[user]", @config.run_list[0]
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

  context "chef binary path" do
    should "return just the binary if no binary path is set" do
      @config.binary_path = nil
      assert_equal "foo", @action.chef_binary_path("foo")
    end

    should "return the joined binary path and binary if set" do
      @config.binary_path = "/foo"
      assert_equal File.join(@config.binary_path, "bar"), @action.chef_binary_path("bar")
    end
  end

  context "permissions on provisioning folder" do
    should "create and chown the folder to the ssh user" do
      ssh_seq = sequence("ssh_seq")
      ssh = mock("ssh")
      ssh.expects(:sudo!).with("mkdir -p #{@config.provisioning_path}").once.in_sequence(ssh_seq)
      ssh.expects(:sudo!).with("chown #{@env.config.ssh.username} #{@config.provisioning_path}").once.in_sequence(ssh_seq)
      @vm.ssh.expects(:execute).yields(ssh)
      @action.chown_provisioning_folder
    end
  end

  context "generating and uploading chef configuration file" do
    setup do
      @vm.ssh.stubs(:upload!)

      @template = "template"
      @filename = "foo.rb"

      Vagrant::Util::TemplateRenderer.stubs(:render).returns("foo")
    end

    should "render and upload file" do
      template_data = mock("data")
      string_io = mock("string_io")
      Vagrant::Util::TemplateRenderer.expects(:render).with(@template, anything).returns(template_data)
      StringIO.expects(:new).with(template_data).returns(string_io)
      File.expects(:join).with(@config.provisioning_path, @filename).once.returns("bar")
      @vm.ssh.expects(:upload!).with(string_io, "bar")

      @action.setup_config(@template, @filename, {})
    end

    should "provide log level by default" do
      Vagrant::Util::TemplateRenderer.expects(:render).returns("foo").with() do |template, vars|
        assert vars.has_key?(:log_level)
        assert_equal @config.log_level.to_sym, vars[:log_level]
        true
      end

      @action.setup_config(@template, @filename, {})
    end

    should "allow custom template variables" do
      custom = {
        :foo => "bar",
        :int => 7
      }

      Vagrant::Util::TemplateRenderer.expects(:render).returns("foo").with() do |template, vars|
        custom.each do |key, value|
          assert vars.has_key?(key)
          assert_equal value, vars[key]
        end

        true
      end

      @action.setup_config(@template, @filename, custom)
    end
  end

  context "generating and uploading json" do
    def assert_json
      @vm.ssh.expects(:upload!).with do |json, path|
        data = JSON.parse(json.read)
        yield data
        true
      end

      @action.setup_json
    end

    should "merge in the extra json specified in the config" do
      @config.json = { :foo => "BAR" }
      assert_json do |data|
        assert_equal "BAR", data["foo"]
      end
    end

    should "add the directory as a special case to the JSON" do
      assert_json do |data|
        assert_equal @env.config.vm.shared_folders["v-root"][:guestpath], data["vagrant"]["directory"]
      end
    end

    should "not add the directory if the 'v-root' shared folder doesn't exist" do
      @env.config.vm.shared_folders.delete("v-root")
      assert_json do |data|
        assert !data["vagrant"].has_key?("directory")
      end
    end

    should "add the config to the JSON" do
      assert_json do |data|
        assert_equal @env.config.ssh.username, data["vagrant"]["config"]["ssh"]["username"]
      end
    end

    should "upload a StringIO to dna.json" do
      StringIO.expects(:new).with(anything).returns("bar")
      File.expects(:join).with(@config.provisioning_path, "dna.json").once.returns("baz")
      @vm.ssh.expects(:upload!).with("bar", "baz").once
      @action.setup_json
    end
  end
end
