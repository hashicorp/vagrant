require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::ChangeHostName" do
  let(:caps) do
    VagrantPlugins::GuestSUSE::Plugin
      .components
      .guest_capabilities[:suse]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:cap) { caps.get(:change_host_name) }
  let(:name) { "banana-rama.example.com" }
  let(:basename) { "banana-rama" }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    context "minimal network config" do 
      let(:networks) { [
        [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}]
      ] }

      before do 
        allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
      end

      it "sets the hostname" do
        comm.stub_command('test "$(hostnamectl --static status)" = "#{basename}"', exit_code: 1)

        cap.change_host_name(machine, name)
        expect(comm.received_commands[1]).to match(/echo #{name} > \/etc\/HOSTNAME/)
        expect(comm.received_commands[1]).to match(/hostnamectl set-hostname '#{basename}'/)
      end

      it "does not change the hostname if already set" do
        comm.stub_command('test "$(hostnamectl --static status)" = "#{basename}"', exit_code: 0)

        cap.change_host_name(machine, name)
        expect(comm.received_commands.size).to eq(1)
      end
    end

    context "multiple networks configured with hostname" do 
      before do 
        allow(comm).to receive(:test).with('test "$(hostnamectl --static status)" = "#{basename}"', sudo: false).and_return(false)
      end

      it "adds a new entry only for the hostname" do 
        networks = [
          [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}],
          [:public_network, {:ip=>"192.168.0.1", :hostname=>true, :protocol=>"tcp", :id=>"93a4ad88-0774-4127-a161-ceb715ff372f"}],
          [:public_network, {:ip=>"192.168.0.2", :protocol=>"tcp", :id=>"5aebe848-7d85-4425-8911-c2003d924120"}]
        ]
        allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)


        expect(cap).to receive(:replace_host)
        expect(cap).to_not receive(:add_hostname_to_loopback_interface)
        cap.change_host_name(machine, name)
      end

      it "appends an entry to the loopback interface" do 
        networks = [
          [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}],
          [:public_network, {:ip=>"192.168.0.1", :protocol=>"tcp", :id=>"93a4ad88-0774-4127-a161-ceb715ff372f"}],
          [:public_network, {:ip=>"192.168.0.2", :protocol=>"tcp", :id=>"5aebe848-7d85-4425-8911-c2003d924120"}]
        ]
        allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)


        expect(cap).to_not receive(:replace_host)
        expect(cap).to receive(:add_hostname_to_loopback_interface).once
        cap.change_host_name(machine, name)
      end
    end
  end
end
