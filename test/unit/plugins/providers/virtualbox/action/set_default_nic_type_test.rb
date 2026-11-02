# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Action::SetDefaultNICType do
  include_context "unit"
  include_context "virtualbox"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :virtualbox).tap do |m|
      allow(m.provider).to receive(:driver).and_return(driver)
    end
  end

  let(:env)    {{ machine: machine, ui: machine.ui }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double("driver") }

  subject { described_class.new(app, env) }

  describe "#call" do
    let(:provider_config) {
      double("provider_config",
        default_nic_type: default_nic_type,
        network_adapters: network_adapters)
    }
    let(:default_nic_type) { nil }
    let(:network_adapters) { {} }
    let(:virtualbox_version) { "5.2.23" }

    before do
      allow(driver).to receive(:version).and_return(virtualbox_version)
      allow(machine).to receive(:provider_config).and_return(provider_config)
    end

    it "should call the next action" do
      expect(app).to receive(:call)
      subject.call(env)
    end

    context "when default_nic_type is set" do
      let(:default_nic_type) { "CUSTOM_NIC_TYPE" }

      context "when network adapters are defined" do
        let(:network_adapters) { {"1" => [:nat, {}], "2" => [:intnet, {nic_type: nil}]} }

        it "should set nic type if not defined" do
          subject.call(env)
          expect(network_adapters["1"].last[:nic_type]).to eq(default_nic_type)
        end

        it "should not set nic type if already defined" do
          subject.call(env)
          expect(network_adapters["2"].last[:nic_type]).to be_nil
        end
      end

      context "when vm networks are defined" do
        before do
          machine.config.vm.network :private_network
          machine.config.vm.network :public_network, nic_type: nil
          machine.config.vm.network :private_network, virtualbox__nic_type: "STANDARD"
        end

        it "should add namespaced nic type when not defined" do
          subject.call(env)
          networks = machine.config.vm.networks.map { |type, opts|
            opts if type.to_s.end_with?("_network") }.compact
          expect(networks.first[:virtualbox__nic_type]).to eq(default_nic_type)
        end

        it "should not add namespaced nic type when nic type defined" do
          subject.call(env)
          networks = machine.config.vm.networks.map { |type, opts|
            opts if type.to_s.end_with?("_network") }.compact
          expect(networks[1][:virtualbox__nic_type]).to be_nil
        end

        it "should not modify existing namespaced nic type" do
          subject.call(env)
          networks = machine.config.vm.networks.map { |type, opts|
            opts if type.to_s.end_with?("_network") }.compact
          expect(networks.last[:virtualbox__nic_type]).to eq("STANDARD")
        end
      end
    end

    context "when virtualbox version is has susceptible E1000" do
      let(:virtualbox_version) { "5.2.21" }

      it "should output a warning" do
        expect(machine.ui).to receive(:warn)
        subject.call(env)
      end

      context "when default_nic_type is set to E1000 type" do
        let(:default_nic_type) { "82540EM" }

        it "should output a warning" do
          expect(machine.ui).to receive(:warn)
          subject.call(env)
        end
      end

      context "when default_nic_type is set to non-E1000 type" do
        let(:default_nic_type) { "virtio" }

        it "should not output a warning" do
          expect(machine.ui).not_to receive(:warn)
          subject.call(env)
        end

        context "when network adapter is configured with E1000 type" do
          let(:network_adapters) { {"1" => [:nat, {nic_type: "82540EM" }]} }

          it "should output a warning" do
            expect(machine.ui).to receive(:warn)
            subject.call(env)
          end
        end

        context "when vm network is configured with E1000 type" do
          before { machine.config.vm.network :private_network, nic_type: "82540EM" }

          it "should output a warning" do
            expect(machine.ui).to receive(:warn)
            subject.call(env)
          end
        end

        context "when vm network is configured with E1000 type in namespaced argument" do
          before { machine.config.vm.network :private_network, virtualbox__nic_type: "82540EM" }

          it "should output a warning" do
            expect(machine.ui).to receive(:warn)
            subject.call(env)
          end
        end
      end
    end

  end
end
