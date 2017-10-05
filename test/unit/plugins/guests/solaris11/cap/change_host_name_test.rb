require_relative "../../../../base"

describe "VagrantPlugins::GuestSolaris11::Cap::ChangeHostName" do
  let(:caps) do
    VagrantPlugins::GuestSolaris11::Plugin
      .components
      .guest_capabilities[:solaris11]
  end

  let(:machine) { double("machine", config: double("config", solaris11: double("solaris11", suexec_cmd: 'sudo'))) }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    let(:cap) { caps.get(:change_host_name) }
    let(:name) { "solaris11.domain.com" }

    it "changes the hostname" do
      allow(machine.communicate).to receive(:test).and_return(false)
      allow(machine.communicate).to receive(:execute)

      expect(machine.communicate).to receive(:execute).with("sudo /usr/sbin/svccfg -s system/identity:node setprop config/nodename=\"#{name}\"")
      expect(machine.communicate).to receive(:execute).with("sudo /usr/sbin/svccfg -s system/identity:node setprop config/loopback=\"#{name}\"")
      expect(machine.communicate).to receive(:execute).with("sudo /usr/sbin/svccfg -s system/identity:node refresh ")
      expect(machine.communicate).to receive(:execute).with("sudo /usr/sbin/svcadm restart system/identity:node ")
      cap.change_host_name(machine, name)
    end
  end
end
