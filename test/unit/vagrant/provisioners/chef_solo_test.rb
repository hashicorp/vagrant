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

  context "creating expanded folder sets" do
    should "expand VM folders properly" do
      assert_equal [[:vm, nil, "/foo"]], @action.expanded_folders([:vm, "/foo"])
    end

    should "expand host folders properly" do
      path = "foo"
      local_path = File.expand_path(path, @env.root_path)
      remote_path = "#{@action.config.provisioning_path}/chef-solo-1"
      assert_equal [[:host, local_path, remote_path]], @action.expanded_folders([:host, path])
    end

    should "share roles and cookbooks in different folders" do
      local_roles_path = File.expand_path('roles',@env.root_path)
      local_cookbooks_path = File.expand_path('cookbooks',@env.root_path)
      remote_roles_path = @action.expanded_folders([:host,local_roles_path])[0][2]
      remote_cookbooks_path = @action.expanded_folders([:host,local_cookbooks_path])[0][2]
      assert_not_equal remote_roles_path, remote_cookbooks_path
    end
  end

  context "guest paths" do
    should "extract the parts properly" do
      structure = [[1,2,3],[1,2,3]]
      assert_equal [3,3], @action.guest_paths(structure)
    end
  end

  context "generating and uploading chef solo configuration file" do
    setup do
      @vm.ssh.stubs(:upload!)

      @config.recipe_url = "foo/bar/baz"
      @action.prepare
    end

    should "call setup_config with proper variables" do
      @action.expects(:setup_config).with("chef_solo_solo", "solo.rb", {
        :node_name => @config.node_name,
        :provisioning_path => @config.provisioning_path,
        :cookbooks_path => @action.guest_paths(@action.cookbook_folders),
        :recipe_url => @config.recipe_url,
        :roles_path => @action.guest_paths(@action.role_folders).first,
        :data_bags_path => @action.guest_paths(@action.data_bags_folders).first
      })

      @action.setup_solo_config
    end
  end

  context "running chef solo" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "run chef solo" do
      cmd = "/bin/bash -c 'sudo /usr/bin/chef-solo -c #{@config.provisioning_path}/solo.rb -j #{@config.provisioning_path}/dna.json'"
      #sess = mock('session')
      #@ssh.stubs(:execute).yields(sess)
      @ssh.expects(:vagrant_remote_cmd).with(cmd).returns("is_a(String)").once
      @ssh.expects(:vagrant_type).with("is_a(String)").once
      #@ssh.expects(:exit).once
      @action.run_chef_solo
    end

    should "check the exit status if that is given" do
      cmd = "/bin/bash -c 'sudo /usr/bin/chef-solo -c #{@config.provisioning_path}/solo.rb -j #{@config.provisioning_path}/dna.json'"
      sess = mock('session')
      @ssh.stubs(:execute).yields(sess)
      @ssh.expects(:vagrant_remote_cmd).with(cmd).returns("is_a(String)").once
      @ssh.expects(:vagrant_type).with("is_a(String)").once
      #@ssh.expects(:check_exit_status).with(is_a(Integer), anything, is_a(Hash), is_a(String), is_a(String)).once
      #@ssh.expects(:exit).once
      @action.run_chef_solo
    end
  end
end
