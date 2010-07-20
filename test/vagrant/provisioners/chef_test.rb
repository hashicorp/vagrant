require "test_helper"

class ChefProvisionerTest < Test::Unit::TestCase
  setup do
    @action_env = Vagrant::Action::Environment.new(mock_environment)
    @action_env.env.vm = mock_vm

    @action = Vagrant::Provisioners::Chef.new(@action_env)
    @env = @action.env
    @vm = @action.vm
  end

  context "preparing" do
    should "error the environment" do
      @action.prepare
      assert @action_env.error?
      assert_equal :chef_base_invalid_provisioner, @action_env.error.first
    end
  end

  context "config" do
    setup do
      @config = Vagrant::Provisioners::Chef::ChefConfig.new
      @config.run_list.clear
    end

    should "not include the 'json' key in the config dump" do
      result = JSON.parse(@config.to_json)
      assert !result.has_key?("json")
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
      @ssh.expects(:exec!).with("which #{binary}", :error_key => :chef_not_detected, :error_data => { :binary => binary }).once
      @action.verify_binary(binary)
    end
  end
  context "permissions on provisioning folder" do
    should "create and chown the folder to the ssh user" do
      ssh_seq = sequence("ssh_seq")
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo mkdir -p #{@env.config.chef.provisioning_path}").once.in_sequence(ssh_seq)
      ssh.expects(:exec!).with("sudo chown #{@env.config.ssh.username} #{@env.config.chef.provisioning_path}").once.in_sequence(ssh_seq)
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
      File.expects(:join).with(@env.config.chef.provisioning_path, @filename).once.returns("bar")
      @vm.ssh.expects(:upload!).with(string_io, "bar")

      @action.setup_config(@template, @filename, {})
    end

    should "provide log level by default" do
      Vagrant::Util::TemplateRenderer.expects(:render).returns("foo").with() do |template, vars|
        assert vars.has_key?(:log_level)
        assert_equal @env.config.chef.log_level.to_sym, vars[:log_level]
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
      @env.config.chef.json = { :foo => "BAR" }
      assert_json do |data|
        assert_equal "BAR", data["foo"]
      end
    end

    should "add the directory as a special case to the JSON" do
      assert_json do |data|
        assert_equal @env.config.vm.shared_folders["v-root"][:guestpath], data["vagrant"]["directory"]
      end
    end

    should "add the config to the JSON" do
      assert_json do |data|
        assert_equal @env.config.ssh.username, data["vagrant"]["config"]["ssh"]["username"]
      end
    end

    should "upload a StringIO to dna.json" do
      StringIO.expects(:new).with(anything).returns("bar")
      File.expects(:join).with(@env.config.chef.provisioning_path, "dna.json").once.returns("baz")
      @vm.ssh.expects(:upload!).with("bar", "baz").once
      @action.setup_json
    end
  end
end
