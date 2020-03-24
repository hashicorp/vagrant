require 'json'

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/guests/windows/cap/hyperv_daemons")

describe VagrantPlugins::GuestWindows::Cap::HypervDaemons do
  HYPERV_DAEMON_SERVICES = %i[kvp vss fcopy]
  HYPERV_DAEMON_SERVICE_NAMES = {kvp: "vmickvpexchange", vss: "vmicvss", fcopy: "vmicguestinterface" }

  STOPPED = 1
  RUNNING =	4

  MANUAL_MODE = 3
  DISABLED_MODE = 4

  include_context "unit"

  let(:machine) do
    double("machine").tap do |machine|
      allow(machine).to receive(:communicate).and_return(comm)
    end
  end
  let(:comm) { double("comm") }

  def name_for(service)
    HYPERV_DAEMON_SERVICE_NAMES[service]
  end

  def service_status(name, running: true, disabled: false)
    { "Name" => name,
      "Status" => running ? RUNNING : STOPPED,
      "StartType" => disabled ? DISABLED_MODE : MANUAL_MODE }
  end

  context "test declared methods" do
    subject { described_class }

    describe "#hyperv_daemon_running" do
      HYPERV_DAEMON_SERVICES.each do |service|
        context "daemon #{service}" do
          let(:service) { service }
          let(:service_name) { name_for(service) }

          it "checks daemon is running" do
            expect(subject).to receive(:service_info).
              with(comm, service_name).and_return(service_status(service_name, running: true))
            expect(subject.hyperv_daemon_running(machine, service)).to be_truthy
          end

          it "checks daemon is not running" do
            expect(subject).to receive(:service_info).
              with(comm, service_name).and_return(service_status(service_name, running: false))
            expect(subject.hyperv_daemon_running(machine, service)).to be_falsy
          end
        end
      end
    end

    describe "#hyperv_daemons_running" do
      it "checks hyperv daemons are running" do
        HYPERV_DAEMON_SERVICES.each do |service|
          expect(subject).to receive(:hyperv_daemon_running).with(machine, service).and_return(true)
        end
        expect(subject.hyperv_daemons_running(machine)).to be_truthy
      end

      it "checks hyperv daemons are not running" do
        HYPERV_DAEMON_SERVICES.each do |service|
          expect(subject).to receive(:hyperv_daemon_running).with(machine, service).and_return(false)
        end
        expect(subject.hyperv_daemons_running(machine)).to be_falsy
      end
    end

    describe "#hyperv_daemon_installed" do
      HYPERV_DAEMON_SERVICES.each do |service|
        context "daemon #{service}" do
          let(:service) { service }

          before { expect(subject.hyperv_daemon_installed(subject, service)).to be_truthy }

          it "does not call communicate#execute" do
            expect(comm).to receive(:execute).never
          end
        end
      end
    end

    describe "#hyperv_daemons_installed" do
      it "checks hyperv daemons are running" do
        HYPERV_DAEMON_SERVICES.each do |service|
          expect(subject).to receive(:hyperv_daemon_installed).with(machine, service).and_return(true)
        end
        expect(subject.hyperv_daemons_installed(machine)).to be_truthy
        expect(comm).to receive(:execute).never
      end

      it "checks hyperv daemons are not running" do
        HYPERV_DAEMON_SERVICES.each do |service|
          expect(subject).to receive(:hyperv_daemon_installed).with(machine, service).and_return(false)
        end
        expect(subject.hyperv_daemons_installed(machine)).to be_falsy
        expect(comm).to receive(:execute).never
      end
    end

    describe "#hyperv_daemon_activate" do
      HYPERV_DAEMON_SERVICES.each do |service|
        context "daemon #{service}" do
          let(:service) { service }
          let(:service_name) { name_for(service) }
          let(:service_disabled_status) { service_status(service_name, disabled: true, running: false) }
          let(:service_stopped_status) { service_status(service_name, running: false) }
          let(:service_running_status) { service_status(service_name) }

          context "activate succeeds" do
            after { expect(subject.hyperv_daemon_activate(machine, service)).to be_truthy }

            it "enables the service when service disabled" do
              expect(subject).to receive(:service_info).
                with(comm, service_name).ordered.and_return(service_disabled_status)
              expect(subject).to receive(:enable_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:restart_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:service_info).
                with(comm, service_name).ordered.and_return(service_running_status)
            end

            it "only restarts the service when service enabled" do
              expect(subject).to receive(:service_info).
                with(comm, service_name).ordered.and_return(service_running_status)
              expect(subject).to receive(:enable_service).never
              expect(subject).to receive(:restart_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:service_info).
                with(comm, service_name).ordered.and_return(service_running_status)
            end
          end

          context "activate fails" do
            after { expect(subject.hyperv_daemon_activate(machine, service)).to be_falsy }

            it "enables the service when service disabled" do
              expect(subject).to receive(:service_info).
                with(comm, service_name).ordered.and_return(service_disabled_status)
              expect(subject).to receive(:enable_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:restart_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:service_info).
                with(comm, service_name).ordered.and_return(service_stopped_status)
            end

            it "does not restart service when failed to enable it" do
              expect(subject).to receive(:service_info).
                with(comm, service_name).and_return(service_disabled_status)
              expect(subject).to receive(:enable_service).with(comm, service_name).and_return(false)
              expect(subject).to receive(:restart_service).never
            end
          end
        end
      end
    end

    describe "#hyperv_daemons_activate" do
      it "activates hyperv daemons" do
        HYPERV_DAEMON_SERVICES.each do |service|
          expect(subject).to receive(:hyperv_daemon_activate).with(machine, service).and_return(true)
        end
        expect(subject.hyperv_daemons_activate(machine)).to be_truthy
      end

      it "fails to activate hyperv daemons" do
        HYPERV_DAEMON_SERVICES.each do |service|
          expect(subject).to receive(:hyperv_daemon_activate).with(machine, service).and_return(false)
        end
        expect(subject.hyperv_daemons_activate(machine)).to be_falsy
      end
    end

    describe "#hyperv_daemon_activate" do
      HYPERV_DAEMON_SERVICES.each do |service|
        context "daemon #{service}" do
          let(:service) { service }
          let(:service_name) { name_for(service) }
          let(:service_disabled_status) { service_status(service_name, disabled: true, running: false) }
          let(:service_stopped_status) { service_status(service_name, running: false) }
          let(:service_running_status) { service_status(service_name) }

          context "activate succeeds" do
            after { expect(subject.hyperv_daemon_activate(machine, service)).to be_truthy }

            it "enables the service when service disabled" do
              expect(subject).to receive(:service_info).
                  with(comm, service_name).ordered.and_return(service_disabled_status)
              expect(subject).to receive(:enable_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:restart_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:service_info).
                  with(comm, service_name).ordered.and_return(service_running_status)
            end

            it "only restarts the service when service enabled" do
              expect(subject).to receive(:service_info).
                  with(comm, service_name).ordered.and_return(service_running_status)
              expect(subject).to receive(:enable_service).never
              expect(subject).to receive(:restart_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:service_info).
                  with(comm, service_name).ordered.and_return(service_running_status)
            end
          end

          context "activate fails" do
            after { expect(subject.hyperv_daemon_activate(machine, service)).to be_falsy }

            it "enables the service when service disabled" do
              expect(subject).to receive(:service_info).
                  with(comm, service_name).ordered.and_return(service_disabled_status)
              expect(subject).to receive(:enable_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:restart_service).with(comm, service_name).and_return(true)
              expect(subject).to receive(:service_info).
                  with(comm, service_name).ordered.and_return(service_stopped_status)
            end

            it "does not restart service when failed to enable it" do
              expect(subject).to receive(:service_info).
                  with(comm, service_name).and_return(service_disabled_status)
              expect(subject).to receive(:enable_service).with(comm, service_name).and_return(false)
              expect(subject).to receive(:restart_service).never
            end
          end
        end
      end
    end

    describe "#service_info" do
      let(:service_name) { name_for(:kvp) }
      let(:status) { service_status(service_name) }

      it "executes powershell script" do
        cmd = "ConvertTo-Json (Get-Service -Name #{service_name})"
        expect(comm).to receive(:execute).with(cmd, shell: :powershell) do |&proc|
          proc.call :stdout, status.to_json
        end
        expect(subject.send(:service_info, comm, service_name)).to eq(status)
      end
    end

    describe "#restart_service" do
      let(:service_name) { name_for(:kvp) }
      let(:status) { service_status(service_name) }

      it "executes powershell script" do
        cmd = "Restart-Service -Name #{service_name} -Force"
        expect(comm).to receive(:execute).with(cmd, shell: :powershell)
        expect(subject.send(:restart_service, comm, service_name)).to be_truthy
      end
    end

    describe "#enable_service" do
      let(:service_name) { name_for(:kvp) }
      let(:status) { service_status(service_name) }

      it "executes powershell script" do
        cmd = "Set-Service -Name #{service_name} -StartupType #{MANUAL_MODE}"
        expect(comm).to receive(:execute).with(cmd, shell: :powershell)
        expect(subject.send(:enable_service, comm, service_name)).to be_truthy
      end
    end
  end

  context "calls through guest capabilities" do
    let(:caps) do
      VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows]
    end

    describe "#hyperv_daemons_running" do
      let(:cap) { caps.get(:hyperv_daemons_running) }

      it "checks hyperv daemons are running" do
        HYPERV_DAEMON_SERVICES.each do |service|
          expect(cap).to receive(:hyperv_daemon_running).with(machine, service).and_return(true)
        end
        expect(cap.hyperv_daemons_running(machine)).to be_truthy
      end
    end

    describe "#hyperv_daemons_installed" do
      let(:cap) { caps.get(:hyperv_daemons_installed) }

      it "checks hyperv daemons are running" do
        HYPERV_DAEMON_SERVICES.each do |service|
          expect(cap).to receive(:hyperv_daemon_installed).with(machine, service).and_return(true)
        end
        expect(cap.hyperv_daemons_installed(machine)).to be_truthy
      end
    end

    describe "#hyperv_daemons_activate" do
      let(:cap) { caps.get(:hyperv_daemons_activate) }

      it "activates hyperv daemons" do
        HYPERV_DAEMON_SERVICES.each do |service|
          expect(cap).to receive(:hyperv_daemon_activate).with(machine, service).and_return(true)
        end
        expect(cap.hyperv_daemons_activate(machine)).to be_truthy
      end
    end
  end

end
