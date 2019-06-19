require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::HypervDaemons" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:hyperv_services) do
    %w[kvp vss fcopy]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".hyperv_daemons_running" do
    let(:cap) { caps.get(:hyperv_daemons_running) }

    before do
      comm.stub_command("which apt-get", exit_code: 0)
      hyperv_services.each do |service|
        name = ['hv', service, 'daemon'].join('-')
        comm.stub_command("systemctl -q is-active #{name}", exit_code: 0)
      end
      expect(cap.hyperv_daemons_running(machine)).to be_truthy
    end

    it "checks whether guest OS is apt based" do
      expect(comm.received_commands[0]).to match(/which apt-get/)
    end

    it "checks daemon service status by systemctl" do
      hyperv_services.each_with_index do |service, idx|
        name = ['hv', service, 'daemon'].join('-')
        expect(comm.received_commands[idx + 1]).to match(/systemctl -q is-active #{name}/)
      end
    end
  end

  describe ".hyperv_daemons_installed" do
    let(:cap) { caps.get(:hyperv_daemons_installed) }

    before do
      hyperv_services.each do |service|
        comm.stub_command("which #{['hv', service, 'daemon'].join('_')}", exit_code: 0)
      end

      expect(cap.hyperv_daemons_installed(machine)).to be_truthy
    end

    it "checks whether hyperv daemons exist on the path" do
      hyperv_services.each_with_index do |service, idx|
        name = ['hv', service, 'daemon'].join('_')
        expect(comm.received_commands[idx]).to match(/which #{name}/)
      end
    end
  end

  describe ".hyperv_daemons_activate" do
    let(:cap) { caps.get(:hyperv_daemons_activate) }
    let(:hyperv_service_names) { [] }

    before do
      comm.stub_command("which apt-get", exit_code: apt_get? ? 0 : 1)
      hyperv_services.each do |service|
        name = ['hv', service, 'daemon'].join(service_separator)
        comm.stub_command("systemctl enable #{name}", exit_code: 0)
        comm.stub_command("systemctl restart #{name}", exit_code: 0)
        comm.stub_command("systemctl -q is-active #{name}", exit_code: 0)
        hyperv_service_names << name
      end
      expect(cap.hyperv_daemons_activate(machine)).to be_truthy
    end

    [ { name: "Debian/Ubuntu",
        apt_get?: true,
        service_separator: "-" },
      { name: "Generic Linux",
        apt_get?: false,
        service_separator: "_" } ].each do |test|

      context test[name] do
        let(:apt_get?) { test[:apt_get?] }
        let(:service_separator) { test[:service_separator] }

        it "checks whether guest OS is apt based" do
          expect(comm.received_commands[0]).to match(/which apt-get/)
        end

        it "checks whether hyperv daemons are activated on Debian/Ubuntu" do
          pos = 1
          hyperv_service_names.each do |name|
            expect(comm.received_commands[pos]).to match(/systemctl enable #{name}/)
            expect(comm.received_commands[pos + 1]).to match(/systemctl restart #{name}/)
            expect(comm.received_commands[pos + 2]).to match(/systemctl -q is-active #{name}/)
            pos += 3
          end
        end
      end
    end
  end
end
