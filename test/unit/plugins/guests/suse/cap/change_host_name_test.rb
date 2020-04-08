require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::ChangeHostName" do
  let(:caps) do
    VagrantPlugins::GuestSUSE::Plugin
      .components
      .guest_capabilities[:suse]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(comm).to receive(:sudo).with("sed -i \"s/localhost/localhost #{basename}/g\" /etc/hosts")
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    let(:cap) { caps.get(:change_host_name) }

    let(:name) { "banana-rama.example.com" }
    let(:basename) { "banana-rama" }

    it "sets the hostname" do
      allow(comm).to receive(:test).with("hostnamectl --static status", {:sudo=>true}).and_return(true)
      
      expect(comm).to receive(:sudo).with("hostnamectl set-hostname '#{basename}'")
      cap.change_host_name(machine, name)
    end

    it "does not change the hostname if already set" do
      allow(comm).to receive(:test).with("hostnamectl --static status", {:sudo=>true}).and_return(false)

      expect(comm).to receive(:sudo)
      expect(comm).to_not receive(:sudo).with("hostnamectl set-hostname '#{basename}'")
      cap.change_host_name(machine, name)
    end
  end
end
