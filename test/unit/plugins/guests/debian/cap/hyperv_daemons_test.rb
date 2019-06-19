require_relative "../../../../base"

describe "VagrantPlugins::GuestDebian::Cap::HypervDaemons" do
  let(:caps) do
    VagrantPlugins::GuestDebian::Plugin
      .components
      .guest_capabilities[:debian]
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

    it "checks whether linux-cloud-tools-common package is installed" do
      cap.hyperv_daemons_installed(machine)
      expect(comm.received_commands[0]).to match(/dpkg -s linux-cloud-tools-common/)
    end
  end

  describe ".hyperv_daemons_install" do
    let(:cap) { caps.get(:hyperv_daemons_install) }
    let(:cmd) do
      <<-EOH.gsub(/^ {12}/, "")
            DEBIAN_FRONTEND=noninteractive apt-get update -y &&
            apt-get install -y -o Dpkg::Options::="--force-confdef" linux-cloud-tools-common
      EOH
    end

    it "install linux-cloud-tools-common package" do
      cap.hyperv_daemons_install(machine)
      expect(comm.received_commands[0]).to match("DEBIAN_FRONTEND=noninteractive apt-get update -y &&\napt-get install -y -o Dpkg::Options::=\"--force-confdef\" linux-cloud-tools-common\n")
    end
  end
end
