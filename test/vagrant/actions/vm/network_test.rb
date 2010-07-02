require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class NetworkTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Network)
    @runner.stubs(:system).returns(linux_system(@vm))

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

  context "preparing" do
    should "verify no bridge collisions for each network enabled" do
      @runner.env.config.vm.network("foo")
      @action.expects(:verify_no_bridge_collision).once.with() do |options|
        assert_equal "foo", options[:ip]
        true
      end

      @action.prepare
    end
  end

  context "before destroy" do
    setup do
      @network_adapters = []
      @vm.stubs(:network_adapters).returns(@network_adapters)
    end

    def stub_interface(length=5)
      interface = mock("interface")
      adapter = mock("adapter")
      adapter.stubs(:host_interface_object).returns(interface)
      interface.stubs(:attached_vms).returns(Array.new(length))

      @network_adapters << adapter
      interface
    end

    should "destroy only the unused network interfaces" do
      stub_interface(5)
      stub_interface(7)
      results = [stub_interface(1), stub_interface(1)]

      results.each do |result|
        result.expects(:destroy).once
      end

      @action.before_destroy
    end
  end

  context "before boot" do
    setup do
      @action.stubs(:enable_network?).returns(false)
    end

    should "do nothing if network should not be enabled" do
      @action.expects(:assign_network).never
      @action.before_boot
    end

    should "assign the network if host only networking is enabled" do
      @action.stubs(:enable_network?).returns(true)
      @action.expects(:assign_network).once
      @action.before_boot
    end
  end

  context "after boot" do
    setup do
      @runner.env.config.vm.network("foo")
      @action.stubs(:enable_network?).returns(true)
    end

    should "prepare the host only network, then enable them" do
      run_seq = sequence("run")
      @runner.system.expects(:prepare_host_only_network).once.in_sequence(run_seq)
      @runner.system.expects(:enable_host_only_network).once.in_sequence(run_seq)
      @action.after_boot
    end

    should "do nothing if network is not enabled" do
      @action.stubs(:enable_network?).returns(false)
      @runner.system.expects(:prepare_host_only_network).never
      @action.after_boot
    end
  end

  context "checking if network is enabled" do
    should "return true if the network options are set" do
      @runner.env.config.vm.network("foo")
      assert @action.enable_network?
    end

    should "return false if the network was not set" do
      assert !@action.enable_network?
    end
  end

  context "assigning the network" do
    setup do
      @network_name = "foo"
      @action.stubs(:network_name).returns(@network_name)

      @network_adapters = []
      @vm.stubs(:network_adapters).returns(@network_adapters)

      @options = {
        :ip => "foo",
        :adapter => 7
      }

      @runner.env.config.vm.network(@options[:ip], @options)
    end

    should "setup the specified network adapter" do
      adapter = mock("adapter")
      @network_adapters[@options[:adapter]] = adapter

      adapter.expects(:enabled=).with(true).once
      adapter.expects(:attachment_type=).with(:host_only).once
      adapter.expects(:host_interface=).with(@network_name).once
      adapter.expects(:save).once

      @action.assign_network
    end
  end

  context "verify no bridge collision" do
    setup do
      @action.stubs(:matching_network?).returns(false)
      @options = { :ip => :foo, :netmask => :bar, :name => nil }
    end

    should "do nothing if everything is okay" do
      mock_interface

      assert_nothing_raised { @action.verify_no_bridge_collision(@options) }
    end

    should "raise an exception if a collision is found" do
      mock_interface(:interface_type => :bridged)
      @action.stubs(:matching_network?).returns(true)

      assert_raises(Vagrant::Actions::ActionException) {
        @action.verify_no_bridge_collision(@options)
      }
    end
  end

  context "network name" do
    setup do
      @action.stubs(:matching_network?).returns(false)

      @options = { :ip => :foo, :netmask => :bar, :name => nil }
    end

    should "return the network which matches" do
      result = mock("result")
      interface = mock_interface(:name => result)

      @action.expects(:matching_network?).with(interface, @options).returns(true)
      assert_equal result, @action.network_name(@options)
    end

    should "ignore non-host only interfaces" do
      @options[:name] = "foo"
      mock_interface(:name => @options[:name],
                     :interface_type => :bridged)

      assert_raises(Vagrant::Actions::ActionException) {
        @action.network_name(@options)
      }
    end

    should "return the network which matches the name if given" do
      @options[:name] = "foo"

      interface = mock_interface(:name => @options[:name])
      assert_equal @options[:name], @action.network_name(@options)
    end

    should "error and exit if the given network name is not found" do
      @options[:name] = "foo"

      @interfaces.expects(:create).never

      assert_raises(Vagrant::Actions::ActionException) {
        @action.network_name(@options)
      }
    end

    should "create a network for the IP and netmask" do
      result = mock("result")
      network_ip = :foo

      interface = mock_interface(:name => result)
      interface.expects(:enable_static).with(network_ip, @options[:netmask])
      @interfaces.expects(:create).returns(interface)
      @action.expects(:network_ip).with(@options[:ip], @options[:netmask]).once.returns(network_ip)

      assert_equal result, @action.network_name(@options)
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
      assert !@action.matching_network?(@interface, @options)
    end

    should "return true if the netmasks yield the same IP" do
      tests = [["255.255.255.0", "192.168.0.1", "192.168.0.45"],
               ["255.255.0.0", "192.168.45.1", "192.168.28.7"]]

      tests.each do |netmask, interface_ip, guest_ip|
        @options[:netmask] = netmask
        @options[:ip] = guest_ip
        @interface.stubs(:network_mask).returns(netmask)
        @interface.stubs(:ip_address).returns(interface_ip)

        assert @action.matching_network?(@interface, @options)
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
        assert_equal v, @action.apply_netmask(*k)
      end
    end
  end

  context "splitting an IP" do
    should "return the proper result" do
      tests = {
        "192.168.0.1" => [192,168,0,1]
      }

      tests.each do |k,v|
        assert_equal v, @action.split_ip(k)
      end
    end
  end

  context "network IP" do
    should "return the proper result" do
      tests = {
        ["192.168.0.45", "255.255.255.0"] => "192.168.0.1"
      }

      tests.each do |args, result|
        assert_equal result, @action.network_ip(*args)
      end
    end
  end
end
