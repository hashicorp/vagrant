require "test_helper"

class NFSVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::NFS
    @app, @env = mock_action_data

    @vm = mock("vm")
    @vm.stubs(:system).returns(mock("system"))
    @env.env.stubs(:host).returns(Vagrant::Hosts::Base.new(@env))
    @env.env.config.vm.network("192.168.55.1")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
  end

  context "initializing" do
    should "not call verify settings if NFS is not enabled" do
      @klass.any_instance.expects(:verify_settings).never
      @klass.new(@app, @env)
    end

    should "call verify settings if NFS is enabled" do
      @env.env.config.vm.share_folder("v-root", "/vagrant", ".", :nfs => true)
      @klass.any_instance.expects(:verify_settings).once
      @klass.new(@app, @env)
    end
  end

  context "with an instance" do
    setup do
      @instance = @klass.new(@app, @env)
    end

    context "calling" do
      setup do
        @instance.stubs(:folders).returns([:a])

        [:clear_nfs_exports, :extract_folders, :prepare_folders, :export_folders, :mount_folders].each do |meth|
          @instance.stubs(meth)
        end
      end

      should "call the proper sequence and succeed" do
        seq = sequence('seq')
        @instance.expects(:extract_folders).in_sequence(seq)
        @instance.expects(:prepare_folders).in_sequence(seq)
        @instance.expects(:clear_nfs_exports).with(@env).in_sequence(seq)
        @instance.expects(:export_folders).in_sequence(seq)
        @app.expects(:call).with(@env).in_sequence(seq)
        @instance.expects(:mount_folders).in_sequence(seq)
        @instance.call(@env)
      end

      should "not export folders if folders is empty" do
        @instance.stubs(:folders).returns([])

        seq = sequence('seq')
        @instance.expects(:extract_folders).in_sequence(seq)
        @instance.expects(:prepare_folders).never
        @instance.expects(:export_folders).never
        @instance.expects(:clear_nfs_exports).never
        @app.expects(:call).with(@env).in_sequence(seq)
        @instance.expects(:mount_folders).never
        @instance.call(@env)
      end

      should "halt chain if environment error occured" do
        @env.error!(:foo)

        seq = sequence('seq')
        @instance.expects(:extract_folders).in_sequence(seq)
        @instance.expects(:prepare_folders).in_sequence(seq)
        @instance.expects(:clear_nfs_exports).in_sequence(seq)
        @instance.expects(:export_folders).in_sequence(seq)
        @app.expects(:call).never
        @instance.call(@env)
      end

      should "not mount folders if an error occured" do
        seq = sequence("seq")
        @app.expects(:call).in_sequence(seq).with() do
          # Use this mark the env as error
          @env.error!(:foo)

          true
        end

        @instance.expects(:clear_nfs_exports).with(@env).in_sequence(seq)

        @instance.expects(:mount_folders).never
        @instance.call(@env)
      end
    end

    context "extracting folders" do
      setup do
        @env.env.config.vm.shared_folders.clear
        @env.env.config.vm.share_folder("v-foo", "/foo", ".", :nfs => true)
        @env.env.config.vm.share_folder("v-bar", "/bar", ".", :nfs => true)
      end

      should "extract the NFS enabled folders" do
        @instance.extract_folders
        assert_equal 2, @instance.folders.length
      end

      should "mark the folders disabled from the original config" do
        @instance.extract_folders
        %W[v-foo v-bar].each do |key|
          assert @env["config"].vm.shared_folders[key][:disabled]
        end
      end

      should "expand the hostpath relative to the env root" do
        @instance.extract_folders
        %W[v-foo v-bar].each do |key|
          opts = @env["config"].vm.shared_folders[key]
          assert_equal File.expand_path(opts[:hostpath], @env.env.root_path), @instance.folders[key][:hostpath]
        end
      end
    end

    context "preparing UID/GID" do
      setup do
        @stat = mock("stat")
        File.stubs(:stat).returns(@stat)
      end

      should "return nil if the perm is not set" do
        assert_nil @instance.prepare_permission(:uid, {:gid => 7})
      end

      should "return nil if the perm explicitly says nil" do
        assert_nil @instance.prepare_permission(:uid, {:uid => nil})
      end

      should "return the set value if it is set" do
        assert_equal 7, @instance.prepare_permission(:gid, {:map_gid => 7})
      end

      should "return the global config value if set and not explicitly set on folder" do
        @env.env.config.nfs.map_gid = 12
        assert_equal 12, @instance.prepare_permission(:gid, {})
      end

      should "return the stat result of the hostpath if :auto" do
        opts = { :hostpath => "foo", :map_uid => :auto }
        File.expects(:stat).with(opts[:hostpath]).returns(@stat)
        @stat.stubs(:uid).returns(24)

        assert_equal 24, @instance.prepare_permission(:uid, opts)
      end
    end

    context "exporting folders" do
      setup do
        @instance.stubs(:folders).returns({})
        @instance.stubs(:guest_ip).returns("192.168.33.10")
      end

      should "call nfs_export on the host" do
        @env["host"].expects(:nfs_export).with(@instance.guest_ip, @instance.folders)
        @instance.export_folders
      end

      should "error the environment if exception is raised" do
        @env["host"].expects(:nfs_export).raises(Vagrant::Action::ActionException.new(:foo))
        @instance.export_folders
        assert @env.error?
        assert_equal :foo, @env.error.first
      end
    end

    context "mounting folders" do
      setup do
        @instance.stubs(:host_ip).returns("foo")
        @instance.stubs(:folders).returns(["bar"])
      end

      should "mount the folders on the system" do
        @vm.system.expects(:mount_nfs).with(@instance.host_ip, @instance.folders)
        @instance.mount_folders
      end
    end

    context "getting the host IP" do
      setup do
        @network_adapters = []
        @internal_vm.stubs(:network_adapters).returns(@network_adapters)
      end

      def stub_interface(ip)
        interface = mock("interface")
        adapter = mock("adapter")
        adapter.stubs(:host_interface_object).returns(interface)
        interface.stubs(:ip_address).returns(ip)

        @network_adapters << adapter
        interface
      end

      should "return the IP of the first interface" do
        ip = "192.168.1.1"
        stub_interface(ip)

        assert_equal ip, @instance.host_ip
      end

      should "return nil if no IP is found" do
        assert_nil @instance.host_ip
      end
    end

    context "getting the guest IP" do
      should "return the first networked IP" do
        ip = "192.168.33.10"
        @env.env.config.vm.network(ip, :adapter => 1)
        @env.env.config.vm.network("192.168.66.10", :adapter => 2)
        assert_equal ip, @instance.guest_ip
      end
    end

    context "nfs enabled" do
      should "return false if no folders are marked for NFS" do
        assert !@instance.nfs_enabled?
      end

      should "return true if a shared folder is marked for NFS" do
        @env.env.config.vm.share_folder("v-foo", "/foo", "/bar", :nfs => true)
        assert @instance.nfs_enabled?
      end
    end

    context "verifying settings" do
      setup do
        @env.env.host.stubs(:nfs?).returns(true)
      end

      should "error environment if host is nil" do
        @env.env.stubs(:host).returns(nil)
        @instance.verify_settings
        assert @env.error?
        assert_equal :nfs_host_required, @env.error.first
      end

      should "error environment if host does not support NFS" do
        @env.env.host.stubs(:nfs?).returns(false)
        @instance.verify_settings
        assert @env.error?
        assert_equal :nfs_not_supported, @env.error.first
      end

      should "error environment if host only networking is not enabled" do
        @env.env.config.vm.network_options.clear
        @instance.verify_settings
        assert @env.error?
        assert_equal :nfs_no_host_network, @env.error.first
      end

      should "be fine if everything passes" do
        @env.env.host.stubs(:nfs?).returns(true)
        @instance.verify_settings
        assert !@env.error?
      end
    end
  end
end
