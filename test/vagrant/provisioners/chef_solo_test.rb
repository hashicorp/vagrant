require "test_helper"

class ChefSoloProvisionerTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Provisioners::ChefSolo

    @action_env = Vagrant::Action::Environment.new(vagrant_env.vms[:default].env)

    @config = @klass::Config.new
    @action = @klass.new(@action_env, @config)
    @env = @action.env
    @vm = @action.vm
  end

  context "config validation" do
    setup do
      @errors = Vagrant::Config::ErrorRecorder.new
      @config.run_list = ["foo"]
      @config.cookbooks_path = "cookbooks"
    end

    should "be invalid if run list is empty" do
      @config.run_list = []
      @config.validate(@errors)
      assert !@errors.errors.empty?
    end

    should "be invalid if cookbooks path is empty" do
      @config.cookbooks_path = nil
      @config.validate(@errors)
      assert !@errors.errors.empty?
    end
  end

  context "preparing" do
    should "share cookbook folders" do
      @action.expects(:share_cookbook_folders).once
      @action.prepare
    end

    should "share role folders" do
      @action.expects(:share_role_folders).once
      @action.prepare
    end
  end

  context "provisioning" do
    should "run the proper sequence of methods in order" do
      prov_seq = sequence("prov_seq")
      @action.expects(:verify_binary).with("chef-solo").once.in_sequence(prov_seq)
      @action.expects(:chown_provisioning_folder).once.in_sequence(prov_seq)
      @action.expects(:setup_json).once.in_sequence(prov_seq)
      @action.expects(:setup_solo_config).once.in_sequence(prov_seq)
      @action.expects(:run_chef_solo).once.in_sequence(prov_seq)
      @action.provision!
    end
  end
  context "sharing cookbook folders" do
    setup do
      @host_cookbook_paths = ["foo", "bar"]
      @action.stubs(:host_cookbook_paths).returns(@host_cookbook_paths)
    end

    should "share each cookbook folder" do
      share_seq = sequence("share_seq")
      @host_cookbook_paths.each_with_index do |cookbook, i|
        @env.config.vm.expects(:share_folder).with("v-csc-#{i}", @action.cookbook_path(i), cookbook).in_sequence(share_seq)
      end

      @action.share_cookbook_folders
    end
  end

  context "sharing role folders" do
    setup do
      @host_role_paths = ["foo", "bar"]
      @action.stubs(:host_role_paths).returns(@host_role_paths)
    end

    should "share each role folder" do
      share_seq = sequence("share_seq")
      @host_role_paths.each_with_index do |role, i|
        @env.config.vm.expects(:share_folder).with("v-csr-#{i}", @action.role_path(i), role).in_sequence(share_seq)
      end

      @action.share_role_folders
    end
  end

  context "host folder paths" do
    should "ignore VM paths" do
      assert @action.host_folder_paths([:vm, "foo"]).empty?
    end

    should "return as an array if was originally a string" do
      folder = "foo"
      File.stubs(:expand_path).returns("bar")
      assert_equal ["bar"], @action.host_folder_paths(folder)
    end

    should "return the array of folders if its an array" do
      folders = ["foo", "bar"]
      expand_seq = sequence('expand_seq')
      folders.collect! { |folder| File.expand_path(folder, @env.root_path) }

      assert_equal folders, @action.host_folder_paths(folders)
    end
  end

  context "host cookbooks paths" do
    should "get folders path for configured cookbooks path" do
      result = mock("result")
      @config.stubs(:cookbooks_path).returns("foo")
      @action.expects(:host_folder_paths).with(@config.cookbooks_path).returns(result)
      assert_equal result, @action.host_cookbook_paths
    end
  end

  context "host roles paths" do
    should "get folders path for configured roles path" do
      result = mock("result")
      @config.stubs(:roles_path).returns("foo")
      @action.expects(:host_folder_paths).with(@config.roles_path).returns(result)
      assert_equal result, @action.host_role_paths
    end
  end

  context "folder path" do
    should "return a proper path to a single folder" do
      expected = File.join(@config.provisioning_path, "cookbooks-5")
      assert_equal expected, @action.folder_path("cookbooks", 5)
    end

    should "return array-representation of folder paths if multiple" do
      @folders = (0..5).to_a
      @cookbooks = @folders.inject([]) do |acc, i|
        acc << @action.cookbook_path(i)
      end

      assert_equal @cookbooks, @action.folders_path(@folders, "cookbooks")
    end

    should "return a single string representation if folder paths is single" do
      @folder = "cookbooks"
      @cookbooks = @action.folder_path(@folder, 0)

      assert_equal @cookbooks, @action.folders_path([0], @folder)
    end

    should "properly format VM folder paths" do
      @config.provisioning_path = "/foo"
      assert_equal "/foo/bar", @action.folders_path([:vm, "bar"], nil)
    end
  end

  context "cookbooks path" do
    should "return a proper path to a single cookbook" do
      expected = File.join(@config.provisioning_path, "cookbooks-5")
      assert_equal expected, @action.cookbook_path(5)
    end

    should "properly call folders path and return result" do
      result = [:a, :b, :c]
      @action.expects(:folders_path).with(@config.cookbooks_path, "cookbooks").once.returns(result)
      assert_equal result.to_json, @action.cookbooks_path
    end
  end

  context "roles path" do
    should "return a proper path to a single role" do
      expected = File.join(@config.provisioning_path, "roles-5")
      assert_equal expected, @action.role_path(5)
    end

    should "properly call folders path and return result" do
      result = [:a, :b, :c]
      @action.expects(:folders_path).with(@config.roles_path, "roles").once.returns(result)
      assert_equal result.to_json, @action.roles_path
    end
  end

  context "generating and uploading chef solo configuration file" do
    setup do
      @vm.ssh.stubs(:upload!)

      @config.recipe_url = "foo/bar/baz"
    end

    should "call setup_config with proper variables" do
      @action.expects(:setup_config).with("chef_solo_solo", "solo.rb", {
        :node_name => @config.node_name,
        :provisioning_path => @config.provisioning_path,
        :cookbooks_path => @action.cookbooks_path,
        :recipe_url => @config.recipe_url,
        :roles_path => @action.roles_path
      })

      @action.setup_solo_config
    end
  end

  context "running chef solo" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "cd into the provisioning directory and run chef solo" do
      @ssh.expects(:sudo!).with(["cmd_prefix=`[ -e /usr/local/bin/rvm ] && echo \'rvm system exec\'`; ${cmd_prefix} chef-solo -c #{@config.provisioning_path}/solo.rb -j #{@config.provisioning_path}/dna.json"]).once
      @action.run_chef_solo
    end

    should "check the exit status if that is given" do
      @ssh.stubs(:sudo!).yields(nil, :exit_status, :foo)
      @ssh.expects(:check_exit_status).with(:foo, anything).once
      @action.run_chef_solo
    end
  end
end
