require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::HypervDaemons" do
  let(:caps) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".hyperv_daemons_installed" do
    let(:cap) { caps.get(:hyperv_daemons_installed) }

    it "checks whether hyperv-daemons package is installed" do
      cap.hyperv_daemons_installed(machine)
      expect(comm.received_commands[0]).to match(/rpm -q hyperv-daemons/)
    end
  end

  describe ".hyperv_daemons_install" do
    let(:cap) { caps.get(:hyperv_daemons_install) }
    let(:cmd) do
      <<-EOH.gsub(/^ {12}/, "")
            if command -v dnf; then
              dnf -y install hyperv-daemons
            else
              yum -y install hyperv-daemons
            fi
      EOH
    end

    it "install hyperv-daemons package" do
      cap.hyperv_daemons_install(machine)
      expect(comm.received_commands[0]).to match(/if command -v dnf; then\n  dnf -y install hyperv-daemons\nelse\n  yum -y install hyperv-daemons\nfi\n/)
    end
  end
end
