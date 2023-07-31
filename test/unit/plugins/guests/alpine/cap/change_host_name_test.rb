# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe 'VagrantPlugins::GuestAlpine::Cap::ChangeHostname' do
  let(:described_class) do
    VagrantPlugins::GuestAlpine::Plugin.components.guest_capabilities[:alpine].get(:change_host_name)
  end
  let(:machine) { double('machine') }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:old_hostname) { 'oldhostname.olddomain.tld' }
  let(:networks) {[
    [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}]
  ]}

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    communicator.stub_command('hostname -f', stdout: old_hostname)
    allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
  end

  after do
    communicator.verify_expectations!
  end

  describe '.change_host_name' do
    it 'updates /etc/hostname on the machine' do
      communicator.expect_command("echo 'newhostname' > /etc/hostname")
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
    end

    it 'only tries to update /etc/hosts when the provided hostname is not different' do
      described_class.change_host_name(machine, 'oldhostname.olddomain.tld')
      expect(communicator.received_commands[0]).to eq('hostname -f')
      expect(communicator.received_commands.length).to eq(2)
    end

    it 'refreshes the hostname service with the hostname command' do
      communicator.expect_command('hostname -F /etc/hostname')
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
    end

    it 'renews dhcp on the system with the new hostname' do
      communicator.expect_command('ifdown -a; ifup -a; ifup eth0')
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
    end

    describe 'flipping out the old hostname in /etc/hosts' do
      context "minimal network config" do
        it "sets the hostname" do
          described_class.change_host_name(machine, 'newhostname.newdomain.tld')
          add_to_loopback_cmd = communicator.received_commands.find { |c| c =~ /127.0.\$\{i\}.1/ }
          expect(add_to_loopback_cmd).to_not eq(nil)
        end
    end

      context "multiple networks configured with hostname" do
        let(:networks) {[
            [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}],
            [:public_network, {:ip=>"192.168.0.1", :hostname=>true, :protocol=>"tcp", :id=>"93a4ad88-0774-4127-a161-ceb715ff372f"}],
            [:public_network, {:ip=>"192.168.0.2", :protocol=>"tcp", :id=>"5aebe848-7d85-4425-8911-c2003d924120"}]
        ]}
      
        it "sets the hostname" do
            described_class.change_host_name(machine, 'newhostname.newdomain.tld')
            add_to_loopback_cmd = communicator.received_commands.find { |c| c =~ /sed -i '\/newhostname.newdomain.tld\/d'/ }
            expect(add_to_loopback_cmd).to_not eq(nil)
        end
      end
    end
  end
end
