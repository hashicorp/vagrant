require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ChefSoloProvisionerTest < Test::Unit::TestCase
  setup do
    @env = mock_environment
    @action = Vagrant::Provisioners::ChefSolo.new(@env)

    Vagrant::SSH.stubs(:execute)
    Vagrant::SSH.stubs(:upload!)

    mock_config
  end

  context "preparing" do
    should "share cookbook folders" do
      @action.expects(:share_cookbook_folders).once
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
        @env.config.vm.expects(:share_folder).with("vagrant-chef-solo-#{i}", @action.cookbook_path(i), cookbook).in_sequence(share_seq)
      end

      @action.share_cookbook_folders
    end
  end

  context "host cookbooks paths" do
    should "return as an array if was originally a string" do
      File.stubs(:expand_path).returns("foo")
      @env.config.chef.cookbooks_path = "foo"

      assert_equal ["foo"], @action.host_cookbook_paths
    end

    should "return the array of cookbooks if its an array" do
      cookbooks = ["foo", "bar"]
      @env.config.chef.cookbooks_path = cookbooks

      expand_seq = sequence('expand_seq')
      cookbooks.collect! { |cookbook| File.expand_path(cookbook, @env.root_path) }

      assert_equal cookbooks, @action.host_cookbook_paths
    end
  end

  context "cookbooks path" do
    should "return a proper path to a single cookbook" do
      expected = File.join(@env.config.chef.provisioning_path, "cookbooks-5")
      assert_equal expected, @action.cookbook_path(5)
    end

    should "return array-representation of cookbook paths if multiple" do
      @cookbooks = (0..5).inject([]) do |acc, i|
        acc << @action.cookbook_path(i)
      end

      @env.config.chef.cookbooks_path = @cookbooks
      assert_equal @cookbooks.to_json, @action.cookbooks_path
    end

    should "return a single string representation if cookbook paths is single" do
      @cookbooks = @action.cookbook_path(0)

      @env.config.chef.cookbooks_path = @cookbooks
      assert_equal @cookbooks.to_json, @action.cookbooks_path
    end
  end

  context "generating and uploading chef solo configuration file" do
    setup do
      @env.ssh.stubs(:upload!)
    end

    should "upload properly generate the configuration file using configuration data" do
      expected_config = <<-config
file_cache_path "#{@env.config.chef.provisioning_path}"
cookbook_path #{@action.cookbooks_path}
config

      StringIO.expects(:new).with(expected_config).once
      @action.setup_solo_config
    end

    should "upload this file as solo.rb to the provisioning folder" do
      @action.expects(:cookbooks_path).returns("cookbooks")
      StringIO.expects(:new).returns("foo")
      File.expects(:join).with(@env.config.chef.provisioning_path, "solo.rb").once.returns("bar")
      @env.ssh.expects(:upload!).with("foo", "bar").once
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
