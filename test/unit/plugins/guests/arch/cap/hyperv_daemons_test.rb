require_relative "../../../../base"

describe "VagrantPlugins::GuestArch::Cap::HypervDaemons" do
  let(:caps) do
    VagrantPlugins::GuestArch::Plugin
      .components
      .guest_capabilities[:arch]
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
    let(:cap) { caps.get(:hyperv_daemons_install) }

    it "checks whether hyperv package is installed" do
      cap.hyperv_daemons_installed(machine)
      expect(comm.received_commands[0]).to match(/pacman -Q hyperv/)
    end
  end

  describe ".hyperv_daemons_install" do
    let(:cap) { caps.get(:hyperv_daemons_install) }
    let(:cmd) do
      <<-EOH.gsub(/^ {12}/, "")
            pacman --noconfirm -Syy &&
            pacman --noconfirm -S hyperv
      EOH
    end

    it "installs hyperv package" do
      cap.hyperv_daemons_install(machine)
      expect(comm.received_commands[0]).to match("pacman --noconfirm -Syy &&\npacman --noconfirm -S hyperv\n")
    end
  end
end
