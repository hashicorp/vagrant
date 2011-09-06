require "test_helper"

class ForwardPortsHelpersVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Class.new do
      include Vagrant::Action::VM::ForwardPortsHelpers
      def initialize(env); @env = env; end
    end

    @app, @env = action_env

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @env["vm"] = @vm

    @instance = @klass.new(@env)
  end

  context "getting list of used ports" do
    setup do
      @vms = []
      VirtualBox::VM.stubs(:all).returns(@vms)
      VirtualBox.stubs(:version).returns("3.1.0")
      @vm.stubs(:uuid).returns(:bar)
    end

    def mock_vm(options={})
      options = {
        :running? => true,
        :accessible? => true,
        :uuid => :foo
      }.merge(options)

      vm = mock("vm")
      options.each do |k,v|
        vm.stubs(k).returns(v)
      end

      vm
    end

    def mock_fp(hostport)
      fp = mock("fp")
      fp.stubs(:hostport).returns(hostport.to_s)
      fp
    end

    should "ignore VMs which aren't running" do
      @vms << mock_vm(:running? => false)
      @vms[0].expects(:forwarded_ports).never
      @instance.used_ports
    end

    should "ignore VMs which aren't accessible" do
      @vms << mock_vm(:accessible? => false)
      @vms[0].expects(:forwarded_ports).never
      @instance.used_ports
    end

    should "ignore VMs of the same uuid" do
      @vms << mock_vm(:uuid => @vm.uuid)
      @vms[0].expects(:forwarded_ports).never
      @instance.used_ports
    end

    should "return the forwarded ports for VB 3.2.x" do
      VirtualBox.stubs(:version).returns("3.2.4")
      fps = [mock_fp(2222), mock_fp(80)]
      na = mock("na")
      ne = mock("ne")
      na.stubs(:nat_driver).returns(ne)
      ne.stubs(:forwarded_ports).returns(fps)
      @vms << mock_vm(:network_adapters => [na])
      assert_equal [2222, 80], @instance.used_ports
    end
  end
end
