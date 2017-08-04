require_relative "../base"
require 'socket'

describe VagrantPlugins::ProviderVirtualBox::Action::NetworkFixIPv6 do
  include_context "unit"
  include_context "virtualbox"

  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      allow(m.provider).to receive(:driver).and_return(driver)
    end
  end

  let(:env) {{ machine: machine }}
  let(:app) { lambda { |*args| }}
  let(:driver) { double("driver") }

  subject { described_class.new(app, env) }

  it "ignores nil IP addresses" do
    allow(machine.config.vm).to receive(:networks)
      .and_return(private_network: { ip: nil })
    expect { subject.call(env) }.to_not raise_error
  end

  it "blank nil IP addresses" do
    allow(machine.config.vm).to receive(:networks)
      .and_return(private_network: { ip: "" })
    expect { subject.call(env) }.to_not raise_error
  end

  context "with IPv6 interfaces" do
    let(:socket) { double("socket") }

    before do
      # This address is only used to trigger the fixup code. It doesn't matter
      # what it is.
      allow(machine.config.vm).to receive(:networks)
        .and_return(private_network: { ip: 'fe:80::' })
      allow(UDPSocket).to receive(:new).with(Socket::AF_INET6)
        .and_return(socket)
      allow(socket).to receive(:connect)
    end

    it "only checks the interfaces associated with the VM" do
      all_networks = [{name: "vboxnet0",
                       ipv6: "dead:beef::",
                       ipv6_prefix: 64,
                       status: 'Up'
                      },
                      {name: "vboxnet1",
                       ipv6: "badd:badd::",
                       ipv6_prefix: 64,
                       status: 'Up'
                      }
                     ]
      ifaces = { 1 => {type: :hostonly, hostonly: "vboxnet0"}
               }
      allow(machine.provider.driver).to receive(:read_network_interfaces)
        .and_return(ifaces)
      allow(machine.provider.driver).to receive(:read_host_only_interfaces)
        .and_return(all_networks)
      subject.call(env)
      expect(socket).to have_received(:connect)
        .with(all_networks[0][:ipv6] + (['ffff']*4).join(':'), 80)
    end

    it "correctly uses the netmask to figure out the probe address" do
      all_networks = [{name: "vboxnet0",
                       ipv6: "dead:beef::",
                       ipv6_prefix: 113,
                       status: 'Up'
                      }
                     ]
      ifaces = { 1 => {type: :hostonly, hostonly: "vboxnet0"}
               }
      allow(machine.provider.driver).to receive(:read_network_interfaces)
        .and_return(ifaces)
      allow(machine.provider.driver).to receive(:read_host_only_interfaces)
        .and_return(all_networks)
      subject.call(env)
      expect(socket).to have_received(:connect)
        .with(all_networks[0][:ipv6] + '7fff', 80)
    end

    it "should ignore interfaces that are down" do
      all_networks = [{name: "vboxnet0",
                       ipv6: "dead:beef::",
                       ipv6_prefix: 64,
                       status: 'Down'
                      }
                     ]
      ifaces = { 1 => {type: :hostonly, hostonly: "vboxnet0"}
               }
      allow(machine.provider.driver).to receive(:read_network_interfaces)
        .and_return(ifaces)
      allow(machine.provider.driver).to receive(:read_host_only_interfaces)
        .and_return(all_networks)
      subject.call(env)
      expect(socket).to_not have_received(:connect)
    end

    it "should ignore interfaces without an IPv6 address" do
      all_networks = [{name: "vboxnet0",
                       ipv6: "",
                       ipv6_prefix: 0,
                       status: 'Up'
                      }
                     ]
      ifaces = { 1 => {type: :hostonly, hostonly: "vboxnet0"}
               }
      allow(machine.provider.driver).to receive(:read_network_interfaces)
        .and_return(ifaces)
      allow(machine.provider.driver).to receive(:read_host_only_interfaces)
        .and_return(all_networks)
      subject.call(env)
      expect(socket).to_not have_received(:connect)
    end

    it "should ignore nat interfaces" do
      all_networks = [{name: "vboxnet0",
                       ipv6: "",
                       ipv6_prefix: 0,
                       status: 'Up'
                      }
                     ]
      ifaces = { 1 => {type: :nat}
               }
      allow(machine.provider.driver).to receive(:read_network_interfaces)
        .and_return(ifaces)
      allow(machine.provider.driver).to receive(:read_host_only_interfaces)
        .and_return(all_networks)
      subject.call(env)
      expect(socket).to_not have_received(:connect)
    end

    it "should reconfigure an interface if unreachable" do
      all_networks = [{name: "vboxnet0",
                       ipv6: "dead:beef::",
                       ipv6_prefix: 64,
                       status: 'Up'
                      }
                     ]
      ifaces = { 1 => {type: :hostonly, hostonly: "vboxnet0"}
               }
      allow(machine.provider.driver).to receive(:read_network_interfaces)
        .and_return(ifaces)
      allow(machine.provider.driver).to receive(:read_host_only_interfaces)
        .and_return(all_networks)
      allow(socket).to receive(:connect)
        .with(all_networks[0][:ipv6] + (['ffff']*4).join(':'), 80)
        .and_raise Errno::EHOSTUNREACH
      allow(machine.provider.driver).to receive(:reconfig_host_only)
      subject.call(env)
      expect(machine.provider.driver).to have_received(:reconfig_host_only)
        .with(all_networks[0])
    end
  end
end
