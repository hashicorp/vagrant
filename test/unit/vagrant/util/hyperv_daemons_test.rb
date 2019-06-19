require File.expand_path("../../../base", __FILE__)

require "vagrant/util/hyperv_daemons"

describe Vagrant::Util::HypervDaemons do
  HYPERV_DAEMON_SERVICES = %i[kvp vss fcopy]

  include_context "unit"

  subject do
    klass = described_class
    Class.new do
      extend klass
    end
  end

  let(:machine) do
    double("machine").tap do |machine|
      allow(machine).to receive(:communicate).and_return(comm)
    end
  end
  let(:comm) { double("comm") }

  def name_for(service, separator)
    ['hv', service.to_s, 'daemon'].join separator
  end

  describe "#hyperv_daemon_running" do
    %i[debian linux].each do |guest_type|
      context "guest: #{guest_type}" do
        let(:guest_type) { guest_type }
        let(:is_debian) { guest_type == :debian }

        before do
          allow(comm).to receive(:test).with("which apt-get").and_return(is_debian)
        end

        HYPERV_DAEMON_SERVICES.each do |service|
          context "daemon: #{service}" do
            let(:service) { service }
            let(:service_name) { name_for(service, is_debian ? '-' : '_') }

            it "checks daemon service is running" do
              expect(comm).to receive(:test).with("systemctl -q is-active #{service_name}").and_return(true)
              expect(subject.hyperv_daemon_running(machine, service)).to be_truthy
            end

            it "checks daemon service is not running" do
              expect(comm).to receive(:test).with("systemctl -q is-active #{service_name}").and_return(false)
              expect(subject.hyperv_daemon_running(machine, service)).to be_falsy
            end
          end
        end
      end
    end
  end

  describe "#hyperv_daemons_running" do
    %i[debian linux].each do |guest_type|
      context "guest: #{guest_type}" do
        let(:guest_type) { guest_type }

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
    end
  end

  describe "#hyperv_daemon_installed" do
    %i[debian linux].each do |guest_type|
      context "guest: #{guest_type}" do
        let(:guest_type) { guest_type }

        HYPERV_DAEMON_SERVICES.each do |service|
          context "daemon: #{service}" do
            let(:service) { service }
            let(:daemon_name) { name_for(service, '_') }

            it "checks daemon is installed" do
              allow(comm).to receive(:test).with("which #{daemon_name}").and_return(true)
              expect(subject.hyperv_daemon_installed(machine, service)).to be_truthy
            end

            it "checks daemon is not installed" do
              allow(comm).to receive(:test).with("which #{daemon_name}").and_return(false)
              expect(subject.hyperv_daemon_installed(machine, service)).to be_falsy
            end
          end
        end
      end
    end
  end

  describe "#hyperv_daemons_installed" do
    %i[debian linux].each do |guest_type|
      context "guest: #{guest_type}" do
        let(:guest_type) { guest_type }

        it "checks hyperv daemons are installed" do
          HYPERV_DAEMON_SERVICES.each do |service|
            expect(subject).to receive(:hyperv_daemon_installed).with(machine, service).and_return(true)
          end
          expect(subject.hyperv_daemons_installed(machine)).to be_truthy
        end

        it "checks hyperv daemons are not installed" do
          HYPERV_DAEMON_SERVICES.each do |service|
            expect(subject).to receive(:hyperv_daemon_installed).with(machine, service).and_return(false)
          end
          expect(subject.hyperv_daemons_installed(machine)).to be_falsy
        end
      end
    end
  end

  describe "#hyperv_daemon_activate" do
    %i[debian linux].each do |guest_type|
      context "guest: #{guest_type}" do
        let(:guest_type) { guest_type }
        let(:is_debian) { guest_type == :debian }

        before do
          allow(comm).to receive(:test).with("which apt-get").and_return(is_debian)
        end

        HYPERV_DAEMON_SERVICES.each do |service|
          context "daemon: #{service}" do
            let(:service) { service }
            let(:service_name) { name_for(service, is_debian ? '-' : '_') }

            before do
              allow(comm).to receive(:test).with("systemctl enable #{service_name}", sudo: true).and_return(true)
              allow(comm).to receive(:test).with("systemctl restart #{service_name}", sudo: true).and_return(true)
              allow(comm).to receive(:test).with("systemctl -q is-active #{service_name}").and_return(true)
            end

            context "activation succeeds" do
              after { expect(subject.hyperv_daemon_activate(machine, service)).to be_truthy }

              it "tests whether enabling service succeeds" do
                expect(comm).to receive(:test).with("systemctl enable #{service_name}", sudo: true).and_return(true)
              end

              it "tests whether restart service succeeds" do
                expect(comm).to receive(:test).with("systemctl restart #{service_name}", sudo: true).and_return(true)
              end

              it "checks whether service is active after restart" do
                expect(comm).to receive(:test).with("systemctl -q is-active #{service_name}").and_return(true)
              end
            end

            context "fails to enable" do
              before { allow(comm).to receive(:test).with("systemctl enable #{service_name}", sudo: true).and_return(false) }
              after { expect(subject.hyperv_daemon_activate(machine, service)).to be_falsy }

              it "tests whether enabling service succeeds" do
                expect(comm).to receive(:test).with("systemctl enable #{service_name}", sudo: true).and_return(false)
              end

              it "does not try to restart service" do
                expect(comm).to receive(:test).with("systemctl restart #{service_name}", sudo: true).never
              end

              it "does not check the service status" do
                expect(comm).to receive(:test).with("systemctl -q is-active #{service_name}").never
              end
            end

            context "fails to restart" do
              before { allow(comm).to receive(:test).with("systemctl restart #{service_name}", sudo: true).and_return(false) }
              after { expect(subject.hyperv_daemon_activate(machine, service)).to be_falsy }

              it "tests whether enabling service succeeds" do
                expect(comm).to receive(:test).with("systemctl enable #{service_name}", sudo: true).and_return(true)
              end

              it "tests whether restart service succeeds" do
                expect(comm).to receive(:test).with("systemctl restart #{service_name}", sudo: true).and_return(false)
              end

              it "does not check the service status" do
                expect(comm).to receive(:test).with("systemctl -q is-active #{service_name}").never
              end
            end

            context "restarts the service but still not active" do
              before { allow(comm).to receive(:test).with("systemctl -q is-active #{service_name}").and_return(false) }
              after { expect(subject.hyperv_daemon_activate(machine, service)).to be_falsy }

              it "tests whether enabling service succeeds" do
                expect(comm).to receive(:test).with("systemctl enable #{service_name}", sudo: true).and_return(true)
              end

              it "tests whether restart service succeeds" do
                expect(comm).to receive(:test).with("systemctl restart #{service_name}", sudo: true).and_return(true)
              end

              it "checks whether service is active after restart" do
                expect(comm).to receive(:test).with("systemctl -q is-active #{service_name}").and_return(false)
              end
            end
          end
        end
      end
    end
  end

  describe "#hyperv_daemons_activate" do
    %i[debian linux].each do |guest_type|
      context "guest: #{guest_type}" do
        let(:guest_type) { guest_type }

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
    end
  end
end
