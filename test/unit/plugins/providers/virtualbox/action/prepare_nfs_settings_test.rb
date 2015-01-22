require_relative "../base"

require "vagrant/util/platform"

describe VagrantPlugins::ProviderVirtualBox::Action::PrepareNFSSettings do
  include_context "unit"
  include_context "virtualbox"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      m.provider.stub(driver: driver)
    end
  end

  let(:env)    {{ machine: machine }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double("driver") }
  let(:host)   { double("host") }

  subject { described_class.new(app, env) }

  before do
    env[:test] = true
    allow(machine.env).to receive(:host) { host }
    allow(host).to receive(:capability).with(:nfs_installed) { true }
  end

  it "calls the next action in the chain" do
    driver.stub(read_network_interfaces: {2 => {type: :hostonly, hostonly: "vmnet2"}})
    driver.stub(read_host_only_interfaces: [{name: "vmnet2", ip: "1.2.3.4"}])
    allow(driver).to receive(:read_guest_ip).with(1).and_return("2.3.4.5")

    called = false
    app = lambda { |*args| called = true }

    action = described_class.new(app, env)
    action.call(env)

    expect(called).to eq(true)
  end

  context "with an nfs synced folder" do
    before do
      # We can't be on Windows, because NFS gets disabled on Windows
      Vagrant::Util::Platform.stub(windows?: false)

      env[:machine].config.vm.synced_folder("/host/path", "/guest/path", type: "nfs")
      env[:machine].config.finalize!

      # Stub out the stuff so it just works by default
      driver.stub(read_network_interfaces: {
        2 => {type: :hostonly, hostonly: "vmnet2"},
      })
      driver.stub(read_host_only_interfaces: [
        {name: "vmnet2", ip: "1.2.3.4"},
      ])
      allow(driver).to receive(:read_guest_ip).with(1).and_return("2.3.4.5")

      # override sleep to 0 so test does not take seconds
      retry_options = subject.retry_options
      allow(subject).to receive(:retry_options).and_return(retry_options.merge(sleep: 0))
    end

    it "sets nfs_host_ip and nfs_machine_ip properly" do
      subject.call(env)

      expect(env[:nfs_host_ip]).to    eq("1.2.3.4")
      expect(env[:nfs_machine_ip]).to eq("2.3.4.5")
    end

    it "raises an error when no host only adapter is configured" do
      allow(driver).to receive(:read_network_interfaces) {{}}

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::NFSNoHostonlyNetwork)
    end

    it "retries through guest property not found errors" do
      raise_then_return = [
        lambda { raise Vagrant::Errors::VirtualBoxGuestPropertyNotFound, guest_property: 'stub' },
        lambda { "2.3.4.5" }
      ]
      allow(driver).to receive(:read_guest_ip) { raise_then_return.shift.call }

      subject.call(env)

      expect(env[:nfs_host_ip]).to    eq("1.2.3.4")
      expect(env[:nfs_machine_ip]).to eq("2.3.4.5")
    end

    it "raises an error informing the user of a bug when the guest IP cannot be found" do
      allow(driver).to receive(:read_guest_ip) {
        raise Vagrant::Errors::VirtualBoxGuestPropertyNotFound, guest_property: 'stub'
      }

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::NFSNoGuestIP)
    end

    it "allows statically configured guest IPs to work for NFS, even when guest property would fail" do
      env[:machine].config.vm.network :private_network, ip: "11.12.13.14"

      allow(driver).to receive(:read_guest_ip) {
        raise Vagrant::Errors::VirtualBoxGuestPropertyNotFound, guest_property: "stub"
      }

      subject.call(env)

      expect(env[:nfs_host_ip]).to    eq("1.2.3.4")
      expect(env[:nfs_machine_ip]).to eq(["11.12.13.14"])
    end
  end
end
