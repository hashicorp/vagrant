require_relative "../../../../base"

describe "VagrantPlugins::GuestGentoo::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestGentoo::Plugin
      .components
      .guest_capabilities[:gentoo]
      .get(:change_host_name)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
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
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)

        described_class.change_host_name(machine, name)
        expect(comm.received_commands[2]).to match(/systemctl set-hostname '#{name}'/)
      end

      it "does not change the hostname if already set" do
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)

        described_class.change_host_name(machine, name)
        expect(comm).to_not receive(:sudo).with(/systemctl set-hostname '#{name}'/)
      end
    end
  end
end
