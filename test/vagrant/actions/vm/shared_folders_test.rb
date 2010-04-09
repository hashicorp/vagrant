require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class SharedFoldersActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::SharedFolders)
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
      env = mock_environment do |config|
        config.vm.shared_folders.clear
        config.vm.share_folder("foo", "bar", "baz")
      end

      @runner.expects(:env).returns(env)

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
    end

    should "mount all shared folders to the VM" do
      mount_seq = sequence("mount_seq")
      ssh = mock("ssh")
      @folders.each do |name, hostpath, guestpath|
        ssh.expects(:exec!).with("sudo mkdir -p #{guestpath}").in_sequence(mount_seq)
        @action.expects(:mount_folder).with(ssh, name, guestpath).in_sequence(mount_seq)
        ssh.expects(:exec!).with("sudo chown #{@runner.env.config.ssh.username} #{guestpath}").in_sequence(mount_seq)
      end
      @runner.env.ssh.expects(:execute).yields(ssh)

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
      @ssh.expects(:exec!).with("sudo mount -t vboxsf -o uid=#{@runner.env.config.ssh.username},gid=#{@runner.env.config.ssh.username} #{@name} #{@guestpath}").returns(@success_return)
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

    should "add uid AND gid to mount" do
      uid = "foo"
      gid = "bar"
      env = mock_environment do |config|
        config.vm.shared_folder_uid = uid
        config.vm.shared_folder_gid = gid
      end

      @runner.expects(:env).twice.returns(env)

      @ssh.expects(:exec!).with("sudo mount -t vboxsf -o uid=#{uid},gid=#{gid} #{@name} #{@guestpath}").returns(@success_return)
      mount_folder
    end
  end
end
