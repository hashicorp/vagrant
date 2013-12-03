require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Action::PrepareNFSSettings do
  include_context "virtualbox"

  let(:machine) {
    environment                    = Vagrant::Environment.new
    provider                       = :virtualbox
    provider_cls, provider_options = Vagrant.plugin("2").manager.providers[provider]
    provider_config                = Vagrant.plugin("2").manager.provider_configs[provider]

    Vagrant::Machine.new(
      'test_machine',
      provider,
      provider_cls,
      provider_config,
      provider_options,
      environment.config_global,
      Pathname('data_dir'),
      double('box'),
      environment
    )
  }

  let(:env)    {{ machine: machine }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { env[:machine].provider.driver }

  subject { described_class.new(app, env) }

  it "calls the next action in the chain" do
    called = false
    app = lambda { |*args| called = true }

    action = described_class.new(app, env)
    action.call(env)

    called.should == true
  end

  describe "with an nfs synced folder" do
    before do
      env[:machine].config.vm.synced_folder("/host/path", "/guest/path", nfs: true)
      env[:machine].config.finalize!
    end

    it "sets nfs_host_ip and nfs_machine_ip properly" do
      adapter_number = 2
      adapter_name   = "vmnet2"
      driver.stub(:read_network_interfaces).and_return(
        adapter_number => {type: :hostonly, hostonly: adapter_name}
      )
      driver.stub(:read_host_only_interfaces).and_return([
        {name: adapter_name, ip: "1.2.3.4"}
      ])
      driver.should_receive(:read_guest_ip).with(adapter_number-1).
        and_return("2.3.4.5")

      subject.call(env)

      env[:nfs_host_ip].should    == "1.2.3.4"
      env[:nfs_machine_ip].should == "2.3.4.5"
    end

    it "raises an error when no host only adapter is configured" do
      driver.stub(:read_network_interfaces) {{}}

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::NFSNoHostonlyNetwork)
    end

    it "retries through guest property not found errors" do
      adapter_number = 2
      adapter_name   = "vmnet2"
      driver.stub(:read_network_interfaces).and_return({
        adapter_number => {type: :hostonly, hostonly: adapter_name}
      })
      driver.stub(:read_host_only_interfaces).and_return([
        {name: adapter_name, ip: "1.2.3.4"}
      ])
      driver.should_receive(:read_guest_ip).with(adapter_number-1).
        and_return("2.3.4.5")

      raise_then_return = [
        lambda { raise Vagrant::Errors::VirtualBoxGuestPropertyNotFound, :guest_property => 'stub' },
        lambda { "2.3.4.5" }
      ]
      driver.stub(:read_guest_ip) { raise_then_return.shift.call }

      # override sleep to 0 so test does not take seconds
      retry_options = subject.retry_options
      subject.stub(:retry_options).and_return(retry_options.merge(sleep: 0))

      subject.call(env)

      env[:nfs_host_ip].should    == "1.2.3.4"
      env[:nfs_machine_ip].should == "2.3.4.5"
    end

    it "raises an error informing the user of a bug when the guest IP cannot be found" do
      adapter_number = 2
      adapter_name   = "vmnet2"
      driver.stub(:read_network_interfaces).and_return({
        adapter_number => {type: :hostonly, hostonly: adapter_name}
      })
      driver.stub(:read_host_only_interfaces).and_return([
        {name: adapter_name, ip: "1.2.3.4"}
      ])
      driver.stub(:read_guest_ip) {
        raise Vagrant::Errors::VirtualBoxGuestPropertyNotFound, :guest_property => 'stub'
      }

      # override sleep to 0 so test does not take seconds
      retry_options = subject.retry_options
      subject.stub(:retry_options).and_return(retry_options.merge(sleep: 0))

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::NFSNoGuestIP)
    end
  end
end
