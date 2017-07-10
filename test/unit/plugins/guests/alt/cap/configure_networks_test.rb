require_relative "../../../../base"

describe "VagrantPlugins::GuestALT::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestALT::Plugin
      .components
      .guest_capabilities[:alt]
  end

  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:config) { double("config", vm: vm) }
  let(:guest) { double("guest") }
  let(:machine) { double("machine", guest: guest, config: config) }
  let(:networks){ [[{}], [{}]] }
  let(:vm){ double("vm", networks: networks) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".configure_networks" do
    let(:cap) { caps.get(:configure_networks) }

    before do
      allow(guest).to receive(:capability)
        .with(:flavor)
        .and_return(:alt)

      allow(guest).to receive(:capability)
        .with(:network_scripts_dir)
        .and_return("/etc/net")

      allow(guest).to receive(:capability)
        .with(:network_interfaces)
        .and_return(["eth1", "eth2"])
    end

    let(:network_1) do
      {
        interface: 0,
        type: "dhcp",
      }
    end

    let(:network_2) do
      {
        interface: 1,
        type: "static",
        ip: "33.33.33.10",
        netmask: "255.255.0.0",
        gateway: "33.33.0.1",
      }
    end

    context "with NetworkManager installed" do
      before do
        allow(cap).to receive(:nmcli?).and_return true
      end

      context "with devices managed by NetworkManager" do
        before do
          allow(cap).to receive(:nm_controlled?).and_return true
        end

        context "with nm_controlled option omitted" do
          it "downs networks via nmcli, creates ifaces and restart NetworksManager" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/nmcli.*disconnect/)
            expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
            expect(comm.received_commands[0]).to match(/NetworkManager/)
            expect(comm.received_commands[0]).to_not match(/ifdown|ifup/)
          end
        end

        context "with nm_controlled option set to true" do
          let(:networks){ [[{nm_controlled: true}], [{nm_controlled: true}]] }

          it "downs networks via nmcli, creates ifaces and restart NetworksManager" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/nmcli.*disconnect/)
            expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
            expect(comm.received_commands[0]).to match(/NetworkManager/)
            expect(comm.received_commands[0]).to_not match(/(ifdown|ifup)/)
          end
        end

        context "with nm_controlled option set to false" do
          let(:networks){ [[{nm_controlled: false}], [{nm_controlled: false}]] }

          it "downs networks manually, creates ifaces, starts networks manually and restart NetworksManager" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
            expect(comm.received_commands[0]).to match(/ifup/)
            expect(comm.received_commands[0]).to match(/NetworkManager/)
            expect(comm.received_commands[0]).to_not match(/nmcli/)
          end
        end

        context "with nm_controlled option set to false on first device" do
          let(:networks){ [[{nm_controlled: false}], [{nm_controlled: true}]] }

          it "downs networks, creates ifaces and starts the networks with one managed manually and one NetworkManager controlled" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to match(/nmcli.*disconnect/)
            expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
            expect(comm.received_commands[0]).to match(/ifup/)
            expect(comm.received_commands[0]).to match(/NetworkManager/)
          end
        end
      end

      context "with devices not managed by NetworkManager" do
        before do
          allow(cap).to receive(:nm_controlled?).and_return false
        end

        context "with nm_controlled option omitted" do
          it "creates and starts the networks manually" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
            expect(comm.received_commands[0]).to match(/ifup/)
            expect(comm.received_commands[0]).to match(/NetworkManager/)
            expect(comm.received_commands[0]).to_not match(/nmcli/)
          end
        end

        context "with nm_controlled option set to true" do
          let(:networks){ [[{nm_controlled: true}], [{nm_controlled: true}]] }

          it "creates and starts the networks via nmcli" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
            expect(comm.received_commands[0]).to match(/NetworkManager/)
            expect(comm.received_commands[0]).to_not match(/ifup/)
          end
        end

        context "with nm_controlled option set to false" do
          let(:networks){ [[{nm_controlled: false}], [{nm_controlled: false}]] }

          it "creates and starts the networks via ifup " do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
            expect(comm.received_commands[0]).to match(/ifup/)
            expect(comm.received_commands[0]).to match(/NetworkManager/)
            expect(comm.received_commands[0]).to_not match(/nmcli/)
          end
        end

        context "with nm_controlled option set to false on first device" do
          let(:networks){ [[{nm_controlled: false}], [{nm_controlled: true}]] }

          it "creates and starts the networks with one managed manually and one NetworkManager controlled" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
            expect(comm.received_commands[0]).to match(/ifup/)
            expect(comm.received_commands[0]).to match(/NetworkManager/)
            expect(comm.received_commands[0]).to_not match(/nmcli.*disconnect/)
          end
        end
      end
    end

    context "without NetworkManager installed" do
      before do
        allow(cap).to receive(:nmcli?).and_return false
      end

      context "with nm_controlled option omitted" do

        it "creates and starts the networks manually" do
          cap.configure_networks(machine, [network_1, network_2])
          expect(comm.received_commands[0]).to match(/ifdown/)
          expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
          expect(comm.received_commands[0]).to match(/ifup/)
          expect(comm.received_commands[0]).to_not match(/nmcli/)
          expect(comm.received_commands[0]).to_not match(/NetworkManager/)
        end
      end

      context "with nm_controlled option omitted" do
        let(:networks){ [[{nm_controlled: false}], [{nm_controlled: false}]] }

        it "creates and starts the networks manually" do
          cap.configure_networks(machine, [network_1, network_2])
          expect(comm.received_commands[0]).to match(/ifdown/)
          expect(comm.received_commands[0]).to match(/mkdir.*\/etc\/net\/ifaces/)
          expect(comm.received_commands[0]).to match(/ifup/)
          expect(comm.received_commands[0]).to_not match(/nmcli/)
          expect(comm.received_commands[0]).to_not match(/NetworkManager/)
        end
      end

      context "with nm_controlled option set" do
        let(:networks){ [[{nm_controlled: false}], [{nm_controlled: true}]] }

        it "raises an error" do
          expect{ cap.configure_networks(machine, [network_1, network_2]) }.to raise_error(Vagrant::Errors::NetworkManagerNotInstalled)
        end
      end
    end
  end
end
