require_relative "../../../../base"

describe "VagrantPlugins::GuestOPNsense::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestOPNsense::Plugin
      .components
      .guest_capabilities[:opnsense]
      .get(:change_host_name)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:name) { "banana-rama.example.com" }
  let(:basename) { "banana-rama" }
  let(:check_command) { "hostname -f | grep '^#{name}$'" }
  let(:modify_hostname_command) {
    %Q(sudo sed -i '' 's@\\(<hostname>\\).*\\(</hostname>\\)@\\1#{basename}\\2@g' /conf/config.xml
    sudo /usr/local/etc/rc.reload_all
).gsub(/^ {14}/, '').gsub(/^ {4}/, '')
  }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    context "minimal network config" do

      it "sets the hostname" do
        comm.stub_command("#{check_command}", exit_code: 1)

        described_class.change_host_name(machine, name)
        expect(comm.received_commands[0]).to eq("#{check_command}")
        expect(comm.received_commands[1]).to eq("#{modify_hostname_command}")
      end

      it "does not change the hostname if already set" do
        comm.stub_command("#{check_command}", exit_code: 0)

        described_class.change_host_name(machine, name)
        expect(comm.received_commands[0]).to eq("#{check_command}")
        # sudo command should not be executed so only one command in the communicator
        expect(comm.received_commands.length).to eq(1)
      end
    end

  end
end
