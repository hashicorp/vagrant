require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::VagrantPlugins::Cap::ConfigureNetworks" do
  let(:plugin) { VagrantPlugins::GuestSmartos::Plugin.components.guest_capabilities[:smartos].get(:configure_networks) }
  let(:machine) { double("machine") }
  let(:config) { double("config", smartos: VagrantPlugins::GuestSmartos::Config.new) }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    machine.stub(:communicate).and_return(communicator)
    machine.stub(:config).and_return(config)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".configure_networks" do
    let(:interface) { "eth0" }
    let(:device) { "e1000g#{interface}" }

    describe 'dhcp' do
      let(:network) { {interface: interface, type: :dhcp} }

      it "plumbs the device" do
        communicator.expect_command(%Q(pfexec /sbin/ifconfig #{device} plumb))
        plugin.configure_networks(machine, [network])
      end

      it "starts dhcp for the device" do
        communicator.expect_command(%Q(pfexec /sbin/ifconfig #{device} dhcp start))
        plugin.configure_networks(machine, [network])
      end
    end

    describe 'static' do
      let(:network) { {interface: interface, type: :static, ip: '1.1.1.1', netmask: '255.255.255.0'} }

      it "plumbs the network" do
        communicator.expect_command(%Q(pfexec /sbin/ifconfig #{device} plumb))
        plugin.configure_networks(machine, [network])
      end

      it "starts sets netmask and IP for the device" do
        communicator.expect_command(%Q(pfexec /sbin/ifconfig #{device} inet 1.1.1.1 netmask 255.255.255.0))
        plugin.configure_networks(machine, [network])
      end

      it "starts enables the device" do
        communicator.expect_command(%Q(pfexec /sbin/ifconfig #{device} up))
        plugin.configure_networks(machine, [network])
      end

      it "starts writes out a hostname file" do
        communicator.expect_command(%Q(pfexec sh -c "echo '1.1.1.1' > /etc/hostname.#{device}"))
        plugin.configure_networks(machine, [network])
      end
    end
  end
end

