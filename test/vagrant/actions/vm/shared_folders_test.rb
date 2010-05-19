require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class SharedFoldersActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::SharedFolders)
    @runner.stubs(:system).returns(linux_system(@vm))
  end

  def stub_shared_folders
    folders = [%w{foo from to}, %w{bar bfrom bto}]
    @action.expects(:shared_folders).returns(folders)
    folders
  end

  context "before boot" do
    should "clear folders and create metadata, in order" do
      before_seq = sequence("before")
      @action.expects(:clear_shared_folders).once.in_sequence(before_seq)
      @action.expects(:create_metadata).once.in_sequence(before_seq)
      @action.before_boot
    end
  end

  context "collecting shared folders" do
    setup do
      File.stubs(:expand_path).returns("baz")
    end

    should "convert the vagrant config values into an array" do
      mock_env_shared_folders

      result = [["foo", "baz", "bar"]]
      assert_equal result, @action.shared_folders
    end

    should "expand the path of the host folder" do
      File.expects(:expand_path).with("baz").once.returns("expanded_baz")

      env = mock_environment do |config|
        config.vm.shared_folders.clear
        config.vm.share_folder("foo", "bar", "baz")
      end

      @runner.expects(:env).returns(env)

      result = [["foo", "expanded_baz", "bar"]]
      assert_equal result, @action.shared_folders
    end

    context "with rsync" do
      should "append the rsync value to the other config values" do
        mock_env_shared_folders(:rsync => true)

        assert_equal [["foo", "baz", "bar-rsync", "bar"]], @action.shared_folders
      end
    end

    def mock_env_shared_folders(opts={})
      env = mock_environment do |config|
        config.vm.shared_folders.clear
        config.vm.share_folder("foo", "bar", "baz", opts)
      end

      @runner.expects(:env).returns(env)
    end
  end

  context "clearing shared folders" do
    setup do
      @shared_folder = mock("shared_folder")
      @shared_folders = [@shared_folder]
      @vm.stubs(:shared_folders).returns(@shared_folders)
    end

    should "call destroy on each shared folder then reload" do
      destroy_seq = sequence("destroy")
      @shared_folders.each do |sf|
        sf.expects(:destroy).once.in_sequence(destroy_seq)
      end

      @runner.expects(:reload!).once.in_sequence(destroy_seq)
      @action.clear_shared_folders
    end
  end

  context "setting up shared folder metadata" do
    setup do
      @folders = stub_shared_folders
    end

    should "add all shared folders to the VM" do
      share_seq = sequence("share_seq")
      shared_folders = mock("shared_folders")
      shared_folders.expects(:<<).in_sequence(share_seq).with() { |sf| sf.name == "foo" && sf.host_path == "from" }
      shared_folders.expects(:<<).in_sequence(share_seq).with() { |sf| sf.name == "bar" && sf.host_path == "bfrom" }
      @vm.stubs(:shared_folders).returns(shared_folders)
      @vm.expects(:save).once

      @action.create_metadata
    end
  end

  context "mounting the shared folders" do
    setup do
      @folders = stub_shared_folders
      @ssh = mock("ssh")
      @runner.env.ssh.stubs(:execute).yields(@ssh)
      @runner.system.stubs(:mount_shared_folder)
    end

    should "mount all shared folders to the VM" do
      mount_seq = sequence("mount_seq")
      @folders.each do |name, hostpath, guestpath|
        @runner.system.expects(:mount_shared_folder).with(@ssh, name, guestpath).in_sequence(mount_seq)
      end

      @action.after_boot
    end

    should "execute the necessary rysnc commands for each rsync folder" do
      @folders.map { |f| f << 'rsync' }
      @folders.each do |name, hostpath, guestpath, rsyncd|
        @runner.system.expects(:create_rsync).with(@ssh, :rsyncpath => rsyncd, :guestpath => guestpath)
      end
      @runner.ssh.expects(:execute).yields(ssh)

      @action.after_boot
    end
  end

  context "with rsyncd folders" do
    # TODO prevented by odd configuration swapping when stubbing ssh.execute
    should "prepare the system for rsync if necessary" do
    end
  end
end
