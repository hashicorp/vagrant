require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vm")

describe Vagrant::Action::Builtin::HandleForwardedPortCollisions do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:env) {
    { machine: machine, ui: ui, port_collision_extra_in_use: extra_in_use,
      port_collision_remap: collision_remap, port_collision_repair: collision_repair,
      port_collision_port_check: collision_port_check }
  }
  let(:provider_name) { "default" }
  let(:extra_in_use){ nil }
  let(:collision_remap){ nil }
  let(:collision_repair){ nil }
  let(:collision_port_check){ nil }
  let(:port_check_method){ nil }

  let(:machine) do
    double("machine").tap do |machine|
      allow(machine).to receive(:provider_name).and_return(provider_name)
      allow(machine).to receive(:config).and_return(machine_config)
      allow(machine).to receive(:env).and_return(machine_env)
    end
  end

  let(:machine_config) do
    double("machine_config").tap do |config|
      allow(config).to receive(:vm).and_return(vm_config)
    end
  end

  let(:data_dir){ temporary_dir }

  let(:machine_env) do
    isolated_environment.tap do |i_env|
      allow(i_env).to receive(:data_dir).and_return(data_dir)
      allow(i_env).to receive(:lock).and_yield
    end
  end

  let(:vm_config) do
    double("machine_vm_config").tap do |config|
      allow(config).to receive(:usable_port_range).and_return(1000..2000)
      allow(config).to receive(:networks).and_return([])
    end
  end

  let(:ui) do
    double("ui").tap do |result|
      allow(result).to receive(:info)
    end
  end

  let(:instance){ described_class.new(app, env) }

  describe "#call" do
    it "should create a lock while action runs" do
      expect(machine_env).to receive(:lock).with("fpcollision").and_yield
      instance.call(env)
    end

    context "with extra ports in use provided as Array type" do
      let(:extra_in_use){ [80] }

      it "should not generate an error" do
        expect{ instance.call(env) }.not_to raise_error
      end
    end

    context "with forwarded port defined" do
      let(:port_options){ {guest: 80, host: 8080} }
      before do
        expect(vm_config).to receive(:networks).and_return([[:forwarded_port, port_options]]).twice
        allow(instance).to receive(:ipv4_addresses).and_return(["127.0.0.1"])
      end

      it "should check if host port is in use" do
        expect(instance).to receive(:is_forwarded_already).and_return(false)
        expect(Vagrant::Util::IsPortOpen).to receive(:is_port_open?).and_return(false)
        instance.call(env)
      end

      context "with forwarded port already in use" do
        let(:extra_in_use){ [8080] }

        it "should raise a port collision error" do
          expect{ instance.call(env) }.to raise_error(Vagrant::Errors::ForwardPortCollision)
        end

        context "with auto_correct enabled" do
          before{ port_options[:auto_correct] = true }

          it "should raise a port collision error" do
            expect{ instance.call(env) }.to raise_error(Vagrant::Errors::ForwardPortCollision)
          end

          context "with collision repair enabled" do
            let(:collision_repair){ true }

            it "should automatically correct collision" do
              expect{ instance.call(env) }.not_to raise_error
            end
          end
        end
      end

      context "with custom port_check method" do
        let(:check_result){ [] }
        let(:port_options){ {guest: 80, host: 8080, host_ip: "127.0.1.1"} }

        context "that accepts two parameters" do
          let(:collision_port_check) do
            lambda do |host_ip, host_port|
              check_result.push(host_ip)
              check_result.push(host_port)
              false
            end
          end

          it "should receive both host_ip and host_port" do
            instance.call(env)
            expect(check_result).to include(port_options[:host])
            expect(check_result).to include(port_options[:host_ip])
          end
        end

        context "that accepts one parameter" do
          let(:collision_port_check) do
            lambda do |host_port|
              check_result.push(host_port)
              false
            end
          end

          it "should receive the host_port only" do
            instance.call(env)
            expect(check_result).to eq([port_options[:host]])
          end
        end
      end
    end
  end

  describe "#recover" do
  end

  describe "#port_check" do
    let(:host_ip){ "127.0.0.1" }
    let(:host_port){ 8080 }
    let(:interfaces) { [ ["lo0", "127.0.0.1"], ["eth0", "192.168.1.7"] ] }

    before do
      instance.instance_variable_set(:@machine, machine)
      allow(Vagrant::Util::IPv4Interfaces).to receive(:ipv4_interfaces).and_return(interfaces)
    end

    it "should check if the port is open" do
      expect(Vagrant::Util::IsPortOpen).to receive(:is_port_open?).with(host_ip, host_port).and_return(true)
      instance.send(:port_check, host_ip, host_port)
    end

    context "when host ip is 0.0.0.0" do
      let(:host_ip) { "0.0.0.0" }

      context "on windows" do
        before do
          expect(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
        end

        it "should check the port on every IPv4 interface" do
          expect(Vagrant::Util::IsPortOpen).to receive(:is_port_open?).with(interfaces[0][1], host_port)
          expect(Vagrant::Util::IsPortOpen).to receive(:is_port_open?).with(interfaces[1][1], host_port)
          instance.send(:port_check, host_ip, host_port)
        end

        it "should return false if the port is closed on any IPv4 interfaces" do
          expect(Vagrant::Util::IsPortOpen).to receive(:is_port_open?).with(interfaces[0][1], host_port).
            and_return(true)
          expect(Vagrant::Util::IsPortOpen).to receive(:is_port_open?).with(interfaces[1][1], host_port).
            and_return(false)
          expect(instance.send(:port_check, host_ip, host_port)).to be(false)
        end

        it "should return true if the port is open on all IPv4 interfaces" do
          expect(Vagrant::Util::IsPortOpen).to receive(:is_port_open?).with(interfaces[0][1], host_port).
            and_return(true)
          expect(Vagrant::Util::IsPortOpen).to receive(:is_port_open?).with(interfaces[1][1], host_port).
            and_return(true)
          expect(instance.send(:port_check, host_ip, host_port)).to be(true)
        end
      end
    end

    context "when host ip does not exist" do
      let(:host_ip) { "192.168.99.100" }
      let(:name) { "default" }

      it "should raise an error including the machine name" do
        allow(machine).to receive(:name).and_return(name)
        expect{ instance.send(:port_check, host_ip, host_port) }.
          to raise_error(Vagrant::Errors::ForwardPortHostIPNotFound, /#{name}/)
      end
    end

    context "with loopback address" do
      let (:host_ip) { "127.1.2.40" }

      it "should check if the port is open" do
        expect(Vagrant::Util::IsPortOpen).to receive(:is_port_open?).with(host_ip, host_port).and_return(true)
        instance.send(:port_check, host_ip, host_port)
      end
    end
  end
end
