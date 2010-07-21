require "test_helper"

class ShareFoldersVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::ShareFolders
    @app, @env = mock_action_data

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @vm.stubs(:ssh).returns(mock("ssh"))
    @vm.stubs(:system).returns(mock("system"))
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
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

    @env.stubs(:env).returns(env)
    env.config.vm.shared_folders
  end

  context "calling" do
    should "run the methods in the proper order" do
      before_seq = sequence("before")
      @instance.expects(:create_metadata).once.in_sequence(before_seq)
      @app.expects(:call).with(@env).in_sequence(before_seq)
      @instance.expects(:mount_shared_folders).once.in_sequence(before_seq)
      @instance.expects(:setup_unison).once.in_sequence(before_seq)

      @instance.call(@env)
    end

    should "run only the metadata actions if erroneous environment" do
      @env.error!(:foo)

      before_seq = sequence("before")
      @instance.expects(:create_metadata).once.in_sequence(before_seq)
      @app.expects(:call).with(@env).in_sequence(before_seq)
      @instance.expects(:mount_shared_folders).never
      @instance.expects(:setup_unison).never

      @instance.call(@env)
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

      result = @instance.shared_folders
      assert_equal data.length, result.length
      data.each do |name, value|
        guest, host = value
        assert_equal guest, result[name][:guestpath]
        assert_equal host, result[name][:hostpath]
      end
    end

    should "ignore disabled shared folders" do
      stub_shared_folders do |config|
        config.vm.share_folder("v-foo", "/foo", "/foo")
        config.vm.share_folder("v-root", "/vagrant", ".", :disabled => true)
        config.vm.share_folder("v-bar", "/bar", "/bar")
      end

      assert_equal 2, @instance.shared_folders.length
      assert_equal %W[v-bar v-foo], @instance.shared_folders.keys.sort
    end

    should "append sync suffix if sync enabled to a folder" do
      name = "foo"
      guest = "bar"
      host = "baz"

      stub_shared_folders do |config|
        config.vm.share_folder(name, guest, host, :sync => true)
      end

      result = @instance.shared_folders
      assert_equal "#{guest}#{@env.env.config.unison.folder_suffix}", result[name][:guestpath]
      assert_equal guest, result[name][:original][:guestpath]
    end

    should "not destroy original hash" do
      @folders = stub_shared_folders do |config|
        config.vm.share_folder("foo", "bar", "baz", :sync => true)
      end

      folder = @folders["foo"].dup

      @instance.shared_folders
      assert_equal folder, @env.env.config.vm.shared_folders["foo"]
    end
  end

  context "unison shared folders" do
    setup do
      @folders = stub_shared_folders do |config|
        config.vm.share_folder("foo", "bar", "baz", :sync => true)
        config.vm.share_folder("bar", "foo", "baz")
      end
    end

    should "only return the folders marked for syncing" do
      result = @instance.unison_folders
      assert_equal 1, result.length
      assert result.has_key?("foo")
      assert !result.has_key?("bar")
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
        hostpath = File.expand_path("#{sf.name}host", @env.env.root_path)
        assert data.include?(sf.name)
        assert_equal hostpath, sf.host_path
        true
      end

      @internal_vm.stubs(:shared_folders).returns(shared_folders)
      @internal_vm.expects(:save).once

      @instance.create_metadata
    end
  end

  context "mounting the shared folders" do
    setup do
      @folders = stub_shared_folders
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
      @vm.system.stubs(:mount_shared_folder)
    end

    should "mount all shared folders to the VM" do
      mount_seq = sequence("mount_seq")
      @folders.each do |name, data|
        @vm.system.expects(:mount_shared_folder).with(@ssh, name, data[:guestpath]).in_sequence(mount_seq)
      end

      @instance.mount_shared_folders
    end
  end

  context "setting up unison" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)

      @folders = stub_shared_folders do |config|
        config.vm.share_folder("foo", "bar", "baz", :sync => true)
        config.vm.share_folder("bar", "foo", "baz")
      end
    end

    should "do nothing if unison folders is empty" do
      @instance.stubs(:unison_folders).returns({})
      @vm.ssh.expects(:execute).never
      @instance.setup_unison
    end

    should "prepare unison then create for each folder" do
      seq = sequence("unison seq")
      @vm.system.expects(:prepare_unison).with(@ssh).once.in_sequence(seq)
      @instance.unison_folders.each do |name, data|
        if data[:sync]
          @vm.system.expects(:create_unison).with do |ssh, opts|
            assert_equal @ssh, ssh
            assert_equal data, opts

            true
          end
        end
      end

      @instance.setup_unison
    end
  end
end
