require "test_helper"

class NetworkVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Network
    @app, @env = action_env

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @vm.stubs(:ssh).returns(mock("ssh"))
    @vm.stubs(:system).returns(mock("system"))
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
  end

  context "initializing" do
    should "raise an error if on windows x64 and networking is enabled" do
      Vagrant::Util::Platform.stubs(:windows?).returns(true)
      Vagrant::Util::Platform.stubs(:bit64?).returns(true)
      @env.env.config.vm.network("foo")

      assert_raises(Vagrant::Errors::NetworkNotImplemented) {
        @klass.new(@app, @env)
      }
    end

    should "not raise an error if not on windows and networking is enabled" do
      Vagrant::Util::Platform.stubs(:windows?).returns(false)
      @env.env.config.vm.network("foo")

      assert_nothing_raised {
        @klass.new(@app, @env)
      }
    end

    should "verify no bridge collisions for each network enabled" do
      @env.env.config.vm.network("foo")
      @klass.any_instance.expects(:verify_no_bridge_collision).returns(true).once.with() do |options|
        assert_equal "foo", options[:ip]
        true
      end

      @klass.new(@app, @env)
    end
  end

  context "with an instance" do
    setup do
      @klass.any_instance.stubs(:verify_no_bridge_collision)
      @instance = @klass.new(@app, @env)

      @interfaces = []
      VirtualBox::Global.global.host.stubs(:network_interfaces).returns(@interfaces)
    end

    def mock_interface(options=nil)
      options = {
        :interface_type => :host_only,
        :name => "foo"
      }.merge(options || {})

      interface = mock("interface")
      options.each do |k,v|
        interface.stubs(k).returns(v)
      end

      @interfaces << interface
      interface
    end

    context "calling" do
      setup do
        @env.env.config.vm.network("foo")
        @instance.stubs(:enable_network?).returns(false)
      end

      should "do nothing if network should not be enabled" do
        @instance.expects(:assign_network).never
        @app.expects(:call).with(@env).once
        @vm.system.expects(:prepare_host_only_network).never
        @vm.system.expects(:enable_host_only_network).never

        @instance.call(@env)
      end

      should "assign and enable the network if networking enabled" do
        @instance.stubs(:enable_network?).returns(true)

        run_seq = sequence("run")
        @instance.expects(:assign_network).once.in_sequence(run_seq)
        @app.expects(:call).with(@env).once.in_sequence(run_seq)
        @vm.system.expects(:prepare_host_only_network).once.in_sequence(run_seq)
        @vm.system.expects(:enable_host_only_network).once.in_sequence(run_seq)

        @instance.call(@env)
      end
    end

    context "checking if network is enabled" do
      should "return true if the network options are set" do
        @env.env.config.vm.network("foo")
        assert @instance.enable_network?
      end

      should "return false if the network was not set" do
        assert !@instance.enable_network?
      end
    end

    context "assigning the network" do
      setup do
        @network_name = "foo"
        @instance.stubs(:network_name).returns(@network_name)

        @network_adapters = []
        @internal_vm.stubs(:network_adapters).returns(@network_adapters)
      end

      def expect_adapter_setup(options=nil)
        options = {
          :ip => "foo",
          :adapter => 7
        }.merge(options || {})

        @env["config"].vm.network(options[:ip], options)

        @env["vm"].vm.network_adapters.clear
        @env["vm"].vm.network_adapters[options[:adapter]] = adapter = mock("adapter")

        adapter.expects(:enabled=).with(true)
        adapter.expects(:attachment_type=).with(:host_only).once
        adapter.expects(:host_only_interface=).with(@network_name).once

        if options[:mac]
          adapter.expects(:mac_address=).with(options[:mac].gsub(':', '')).once
        else
          adapter.expects(:mac_address=).never
        end

        adapter.expects(:save).once
      end

      should "setup the specified network adapter" do
        expect_adapter_setup
        @instance.assign_network
      end

      should "setup the specified network adapter's mac address if specified" do
        expect_adapter_setup(:mac => "foo")
        @instance.assign_network
      end

      should "properly remove : from mac address" do
        expect_adapter_setup(:mac => "foo:bar")
        @instance.assign_network
      end
    end

    context "network name" do
      setup do
        @instance.stubs(:matching_network?).returns(false)

        @options = { :ip => :foo, :netmask => :bar, :name => nil }
      end

      should "return the network which matches" do
        result = mock("result")
        interface = mock_interface(:name => result)

        @instance.expects(:matching_network?).with(interface, @options).returns(true)
        assert_equal result, @instance.network_name(@options)
      end

      should "ignore non-host only interfaces" do
        @options[:name] = "foo"
        mock_interface(:name => @options[:name],
                       :interface_type => :bridged)

        assert_raises(Vagrant::Errors::NetworkNotFound) {
          @instance.network_name(@options)
        }
      end

      should "return the network which matches the name if given" do
        @options[:name] = "foo"

        interface = mock_interface(:name => @options[:name])
        assert_equal @options[:name], @instance.network_name(@options)
      end

      should "error and exit if the given network name is not found" do
        @options[:name] = "foo"

        @interfaces.expects(:create).never
        assert_raises(Vagrant::Errors::NetworkNotFound) {
          @instance.network_name(@options)
        }
      end

      should "create a network for the IP and netmask" do
        result = mock("result")
        network_ip = :foo

        interface = mock_interface(:name => result)
        interface.expects(:enable_static).with(network_ip, @options[:netmask])
        @interfaces.expects(:create).returns(interface)
        @instance.expects(:network_ip).with(@options[:ip], @options[:netmask]).once.returns(network_ip)

        assert_equal result, @instance.network_name(@options)
      end
    end

    context "checking for a matching network" do
      setup do
        @interface = mock("interface")
        @interface.stubs(:network_mask).returns("foo")
        @interface.stubs(:ip_address).returns("192.168.0.1")

        @options = {
          :netmask => "foo",
          :ip => "baz"
        }
      end

      should "return false if the netmasks don't match" do
        @options[:netmask] = "bar"
        assert @interface.network_mask != @options[:netmask] # sanity
        assert !@instance.matching_network?(@interface, @options)
      end

      should "return true if the netmasks yield the same IP" do
        tests = [["255.255.255.0", "192.168.0.1", "192.168.0.45"],
                 ["255.255.0.0", "192.168.45.1", "192.168.28.7"]]

        tests.each do |netmask, interface_ip, guest_ip|
          @options[:netmask] = netmask
          @options[:ip] = guest_ip
          @interface.stubs(:network_mask).returns(netmask)
          @interface.stubs(:ip_address).returns(interface_ip)

          assert @instance.matching_network?(@interface, @options)
        end
      end
    end

    context "applying the netmask" do
      should "return the proper result" do
        tests = {
          ["192.168.0.1","255.255.255.0"] => [192,168,0,0],
          ["192.168.45.10","255.255.255.0"] => [192,168,45,0]
        }

        tests.each do |k,v|
          assert_equal v, @instance.apply_netmask(*k)
        end
      end
    end

    context "splitting an IP" do
      should "return the proper result" do
        tests = {
          "192.168.0.1" => [192,168,0,1]
        }

        tests.each do |k,v|
          assert_equal v, @instance.split_ip(k)
        end
      end
    end

    context "network IP" do
      should "return the proper result" do
        tests = {
          ["192.168.0.45", "255.255.255.0"] => "192.168.0.1"
        }

        tests.each do |args, result|
          assert_equal result, @instance.network_ip(*args)
        end
      end
    end

  end
end
