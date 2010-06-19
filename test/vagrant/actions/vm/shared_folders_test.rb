require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class SharedFoldersActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::SharedFolders)
    @runner.stubs(:system).returns(linux_system(@vm))
  end

  def stub_shared_folders
    env = mock_environment do |config|
      config.vm.shared_folders.clear

      if block_given?
        yield config
      else
        folders = [%w{foo fooguest foohost}, %w{bar barguest barhost}]
        folders.each do |data|
          config.vm.share_folder(*data)
        end
      end
    end

    @runner.stubs(:env).returns(env)
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

    should "return a hash of the shared folders" do
      data = {
        "foo" => %W[bar baz],
        "bar" => %W[foo baz]
      }

      stub_shared_folders do |config|
        data.each do |name, value|
          config.vm.share_folder(name, *value)
        end
      end

      result = @action.shared_folders
      assert_equal data.length, result.length
      data.each do |name, value|
        guest, host = value
        assert_equal guest, result[name][:guestpath]
        assert_equal host, result[name][:hostpath]
      end
    end

    should "append sync suffix if sync enabled to a folder" do
      name = "foo"
      guest = "bar"
      host = "baz"

      stub_shared_folders do |config|
        config.vm.share_folder(name, guest, host, :sync => true)
      end

      result = @action.shared_folders
      assert_equal "#{guest}#{@runner.env.config.unison.folder_suffix}", result[name][:guestpath]
      assert_equal guest, result[name][:original][:guestpath]
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

    should "do nothing if no shared folders existed" do
      @shared_folders.clear
      @runner.expects(:reload!).never
      @action.clear_shared_folders
    end
  end

  context "setting up shared folder metadata" do
    setup do
      stub_shared_folders
    end

    should "add all shared folders to the VM" do
      shared_folders = []
      data = %W[foo bar]
      shared_folders.expects(:<<).times(data.length).with() do |sf|
        hostpath = File.expand_path("#{sf.name}host", @runner.env.root_path)
        assert data.include?(sf.name)
        assert_equal hostpath, sf.host_path
        true
      end

      @vm.stubs(:shared_folders).returns(shared_folders)
      @vm.expects(:save).once

      @action.create_metadata
    end
  end

  # context "mounting the shared folders" do
  #   setup do
  #     @folders = stub_shared_folders
  #     @ssh = mock("ssh")
  #     @runner.ssh.stubs(:execute).yields(@ssh)
  #     @runner.system.stubs(:mount_shared_folder)
  #   end

  #   should "mount all shared folders to the VM" do
  #     mount_seq = sequence("mount_seq")
  #     @folders.each do |name, hostpath, guestpath|
  #       @runner.system.expects(:mount_shared_folder).with(@ssh, name, guestpath).in_sequence(mount_seq)
  #     end

  #     @action.after_boot
  #   end

  #   should "execute the necessary rysnc commands for each sync folder" do
  #     @folders.map { |f| f << 'sync' }
  #     @folders.each do |name, hostpath, guestpath, syncd|
  #       @runner.system.expects(:create_sync).with(@ssh, :syncpath => syncd, :guestpath => guestpath)
  #     end
  #     @runner.ssh.expects(:execute).yields(@ssh)

  #     @action.after_boot
  #   end
  # end
end
