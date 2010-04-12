require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ChefSoloProvisionerTest < Test::Unit::TestCase
  setup do
    @env = mock_environment
    @action = Vagrant::Provisioners::ChefSolo.new(@env)
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
      @env.config.chef.stubs(:cookbooks_path).returns("foo")
      @action.expects(:host_folder_paths).with(@env.config.chef.cookbooks_path).returns(result)
      assert_equal result, @action.host_cookbook_paths
    end
  end

  context "host roles paths" do
    should "get folders path for configured roles path" do
      result = mock("result")
      @env.config.chef.stubs(:roles_path).returns("foo")
      @action.expects(:host_folder_paths).with(@env.config.chef.roles_path).returns(result)
      assert_equal result, @action.host_role_paths
    end
  end

  context "folder path" do
    should "return a proper path to a single folder" do
      expected = File.join(@env.config.chef.provisioning_path, "cookbooks-5")
      assert_equal expected, @action.folder_path("cookbooks", 5)
    end

    should "return array-representation of folder paths if multiple" do
      @folders = (0..5).to_a
      @cookbooks = @folders.inject([]) do |acc, i|
        acc << @action.cookbook_path(i)
      end

      assert_equal @cookbooks.to_json, @action.folders_path(@folders, "cookbooks")
    end

    should "return a single string representation if folder paths is single" do
      @folder = "cookbooks"
      @cookbooks = @action.folder_path(@folder, 0)

      assert_equal @cookbooks.to_json, @action.folders_path([0], @folder)
    end
  end

  context "cookbooks path" do
    should "return a proper path to a single cookbook" do
      expected = File.join(@env.config.chef.provisioning_path, "cookbooks-5")
      assert_equal expected, @action.cookbook_path(5)
    end

    should "properly call folders path and return result" do
      result = mock("result")
      @action.stubs(:host_cookbook_paths).returns([])
      @action.expects(:folders_path).with(@action.host_cookbook_paths, "cookbooks").once.returns(result)
      assert_equal result, @action.cookbooks_path
    end
  end

  context "roles path" do
    should "return a proper path to a single role" do
      expected = File.join(@env.config.chef.provisioning_path, "roles-5")
      assert_equal expected, @action.role_path(5)
    end

    should "properly call folders path and return result" do
      result = mock("result")
      @action.stubs(:host_role_paths).returns([])
      @action.expects(:folders_path).with(@action.host_role_paths, "roles").once.returns(result)
      assert_equal result, @action.roles_path
    end
  end

  context "generating and uploading chef solo configuration file" do
    setup do
      @env.ssh.stubs(:upload!)
    end

    should "call setup_config with proper variables" do
      @action.expects(:setup_config).with("chef_solo_solo", "solo.rb", {
        :provisioning_path => @env.config.chef.provisioning_path,
        :cookbooks_path => @action.cookbooks_path,
        :roles_path => @action.roles_path
      })

      @action.setup_solo_config
    end
  end

  context "running chef solo" do
    should "cd into the provisioning directory and run chef solo" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("cd #{@env.config.chef.provisioning_path} && sudo chef-solo -c solo.rb -j dna.json").once
      @env.ssh.expects(:execute).yields(ssh)
      @action.run_chef_solo
    end
  end
end
