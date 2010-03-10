require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class SharedFoldersActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::VM::SharedFolders)
    mock_config
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
      mock_config do |config|
        config.vm.shared_folders.clear
        config.vm.share_folder("foo", "bar", "baz")
      end

      result = [["foo", "baz", "bar"]]
      assert_equal result, @action.shared_folders
    end

    should "expand the path of the host folder" do
      File.expects(:expand_path).with("baz").once.returns("expanded_baz")

      mock_config do |config|
        config.vm.shared_folders.clear
        config.vm.share_folder("foo", "bar", "baz")
      end

      result = [["foo", "expanded_baz", "bar"]]
      assert_equal result, @action.shared_folders
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

      @mock_vm.expects(:reload!).once.in_sequence(destroy_seq)
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
      shared_folders.expects(:<<).in_sequence(share_seq).with() { |sf| sf.name == "foo" && sf.hostpath == "from" }
      shared_folders.expects(:<<).in_sequence(share_seq).with() { |sf| sf.name == "bar" && sf.hostpath == "bfrom" }
      @vm.stubs(:shared_folders).returns(shared_folders)
      @vm.expects(:save).with(true).once

      @action.create_metadata
    end
  end

  context "mounting the shared folders" do
    setup do
      @folders = stub_shared_folders
    end

    should "mount all shared folders to the VM" do
      mount_seq = sequence("mount_seq")
      ssh = mock("ssh")
      @folders.each do |name, hostpath, guestpath|
        ssh.expects(:exec!).with("sudo mkdir -p #{guestpath}").in_sequence(mount_seq)
        @action.expects(:mount_folder).with(ssh, name, guestpath).in_sequence(mount_seq)
        ssh.expects(:exec!).with("sudo chown #{Vagrant.config.ssh.username} #{guestpath}").in_sequence(mount_seq)
      end
      Vagrant::SSH.expects(:execute).yields(ssh)

      @action.after_boot
    end
  end

  context "mounting the main folder" do
    setup do
      @ssh = mock("ssh")
      @name = "foo"
      @guestpath = "bar"
      @sleeptime = 0
      @limit = 10

      @success_return = false
    end

    def mount_folder
      @action.mount_folder(@ssh, @name, @guestpath, @sleeptime)
    end

    should "execute the proper mount command" do
      @ssh.expects(:exec!).with("sudo mount -t vboxsf #{@name} #{@guestpath}").returns(@success_return)
      mount_folder
    end

    should "test type of text and text string to detect error" do
      data = mock("data")
      data.expects(:[]=).with(:result, !@success_return)

      @ssh.expects(:exec!).yields(data, :stderr, "No such device").returns(@success_return)
      mount_folder
    end

    should "test type of text and test string to detect success" do
      data = mock("data")
      data.expects(:[]=).with(:result, @success_return)

      @ssh.expects(:exec!).yields(data, :stdout, "Nothing such device").returns(@success_return)
      mount_folder
    end

    should "raise an ActionException if the command fails constantly" do
      @ssh.expects(:exec!).times(@limit).returns(!@success_return)

      assert_raises(Vagrant::Actions::ActionException) {
        mount_folder
      }
    end

    should "not raise any exception if the command succeeded" do
      @ssh.expects(:exec!).once.returns(@success_return)

      assert_nothing_raised {
        mount_folder
      }
    end
  end
end
