require "test_helper"

class ShareFoldersVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::ShareFolders
    @app, @env = action_env

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @vm.stubs(:ssh).returns(mock("ssh"))
    @vm.stubs(:system).returns(mock("system"))
    @env["vm"] = @vm
    @env["vm.modify"] = mock("proc")

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    # No validation for this test since its a nightmare due to all the
    # nonexistent shared folders.
    Vagrant::Config::Top.any_instance.stubs(:validate!)

    @instance = @klass.new(@app, @env)
  end

  def stub_shared_folders(contents)
    env = vagrant_env(vagrantfile(<<-vf))
      config.vm.shared_folders.clear
      #{contents}
    vf

    @env.stubs(:env).returns(env)
    env.config.vm.shared_folders
  end

  context "calling" do
    should "run the methods in the proper order" do
      before_seq = sequence("before")
      @instance.expects(:create_metadata).once.in_sequence(before_seq)
      @app.expects(:call).with(@env).in_sequence(before_seq)
      @instance.expects(:mount_shared_folders).once.in_sequence(before_seq)

      @instance.call(@env)
    end
  end

  context "collecting shared folders" do
    should "return a hash of the shared folders" do
      data = {
        "foo" => %W[bar baz],
        "bar" => %W[foo baz]
      }

      stub_shared_folders(<<-sf)
        config.vm.share_folder("foo", "bar", "baz")
        config.vm.share_folder("bar", "foo", "baz")
      sf

      result = @instance.shared_folders
      assert_equal data.length, result.length
      data.each do |name, value|
        guest, host = value
        assert_equal guest, result[name][:guestpath]
        assert_equal host, result[name][:hostpath]
      end
    end

    should "ignore disabled shared folders" do
      stub_shared_folders(<<-sf)
        config.vm.share_folder("v-foo", "/foo", "/foo")
        config.vm.share_folder("v-root", "/vagrant", ".", :disabled => true)
        config.vm.share_folder("v-bar", "/bar", "/bar")
      sf

      assert_equal 2, @instance.shared_folders.length
      assert_equal %W[v-bar v-foo], @instance.shared_folders.keys.sort
    end

    should "not destroy original hash" do
      @folders = stub_shared_folders(<<-sf)
        config.vm.share_folder("foo", "bar", "baz", :sync => true)
      sf

      folder = @folders["foo"].dup

      @instance.shared_folders
      assert_equal folder, @env.env.config.vm.shared_folders["foo"]
    end
  end

  context "setting up shared folder metadata" do
    setup do
      stub_shared_folders(<<-sf)
        config.vm.share_folder("foo", "fooguest", "foohost")
        config.vm.share_folder("bar", "barguest", "barhost")
      sf
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

      @env["vm.modify"].expects(:call).with() do |proc|
        proc.call(@internal_vm)
        true
      end

      @instance.create_metadata
    end
  end

  context "mounting the shared folders" do
    setup do
      @folders = stub_shared_folders(<<-sf)
        config.vm.share_folder("foo", "fooguest", "foohost", :owner => "yo", :group => "fo")
        config.vm.share_folder("bar", "barguestt", "barhost", :owner => "foo", :group => "bar")
        config.vm.share_folder("foo_no_mount", nil, "foohost2")
      sf
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
      @vm.system.stubs(:mount_shared_folder)
    end

    should "mount all shared folders to the VM" do
      mount_seq = sequence("mount_seq")
      @ssh.expects(:exit).once
      @folders.each do |name, data|
        if data[:guestpath]
          @vm.system.expects(:mount_shared_folder).with(@ssh, name, data[:guestpath], data[:owner], data[:group]).in_sequence(mount_seq)
        else
          @vm.system.expects(:mount_shared_folder).with(@ssh, name, anything, anything, anything).never
        end
      end

      @instance.mount_shared_folders
    end
  end
end
