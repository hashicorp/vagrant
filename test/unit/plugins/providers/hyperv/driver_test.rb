# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/driver")

describe VagrantPlugins::HyperV::Driver do
  def generate_result(obj)
    "===Begin-Output===\n" +
      JSON.dump(obj) +
      "\n===End-Output==="
  end

  def generate_error(msg)
    "===Begin-Error===\n#{JSON.dump(error: msg)}\n===End-Error===\n"
  end

  let(:result){
    Vagrant::Util::Subprocess::Result.new(
      result_exit, result_stdout, result_stderr) }
  let(:subject){ described_class.new(vm_id) }
  let(:vm_id){ 1 }
  let(:result_stdout){ "" }
  let(:result_stderr){ "" }
  let(:result_exit){ 0 }

  context "public methods" do
    before{ allow(subject).to receive(:execute_powershell).and_return(result) }

    describe "#execute" do
      it "should convert symbol into path string" do
        expect(subject).to receive(:execute_powershell).with(kind_of(String), any_args)
          .and_return(result)
        subject.execute(:thing)
      end

      it "should append extension when converting symbol" do
        expect(subject).to receive(:execute_powershell).with("thing.ps1", any_args)
          .and_return(result)
        subject.execute(:thing)
      end

      context "when command returns non-zero exit code" do
        let(:result_exit){ 1 }

        it "should raise an error" do
          expect{ subject.execute(:thing) }.to raise_error(VagrantPlugins::HyperV::Errors::PowerShellError)
        end
      end

      context "when command stdout matches error pattern" do
        let(:result_stdout){ generate_error("Error Message") }

        it "should raise an error" do
          expect{ subject.execute(:thing) }.to raise_error(VagrantPlugins::HyperV::Errors::PowerShellError)
        end
      end

      context "with valid JSON output" do
        let(:result_stdout){ generate_result(:custom => "value") }

        it "should return parsed JSON data" do
          expect(subject.execute(:thing)).to eq("custom" => "value")
        end
      end

      context "with invalid JSON output" do
        let(:result_stdout){ "value" }
        it "should return nil" do
          expect(subject.execute(:thing)).to be_nil
        end
      end
    end

    describe "#has_vmcx_support?" do
      context "when support is available" do
        let(:result_stdout){ generate_result(:result => true) }

        it "should be true" do
          expect(subject.has_vmcx_support?).to eq(true)
        end
      end

      context "when support is not available" do
        let(:result_stdout){ generate_result(:result => false) }

        it "should be false" do
          expect(subject.has_vmcx_support?).to eq(false)
        end
      end
    end

    describe "#set_vm_integration_services" do
      it "should map known integration services names automatically" do
        expect(subject).to receive(:execute) do |name, args|
          expect(args[:Id]).to eq(VagrantPlugins::HyperV::Driver::INTEGRATION_SERVICES_MAP[:shutdown])
        end
        subject.set_vm_integration_services(shutdown: true)
      end

      it "should set enable when value is true" do
        expect(subject).to receive(:execute) do |name, args|
          expect(args[:Enable]).to eq(true)
        end
        subject.set_vm_integration_services(shutdown: true)
      end

      it "should not set enable when value is false" do
        expect(subject).to receive(:execute) do |name, args|
          expect(args[:Enable]).to be_nil
        end
        subject.set_vm_integration_services(shutdown: false)
      end

      it "should pass unknown key names directly through" do
        expect(subject).to receive(:execute) do |name, args|
          expect(args[:Id]).to eq("CustomKey")
        end
        subject.set_vm_integration_services(CustomKey: true)
      end
    end
  end

  describe "#execute_powershell" do
    before{ allow(Vagrant::Util::PowerShell).to receive(:execute) }

    it "should call the PowerShell module to execute" do
      expect(Vagrant::Util::PowerShell).to receive(:execute)
      subject.send(:execute_powershell, "path", {})
    end

    it "should modify the path separators" do
      expect(Vagrant::Util::PowerShell).to receive(:execute)
        .with("\\path\\to\\script.ps1", any_args)
      subject.send(:execute_powershell, "/path/to/script.ps1", {})
    end

    it "should include ErrorAction option as Stop" do
      expect(Vagrant::Util::PowerShell).to receive(:execute) do |path, *args|
        expect(args).to include("-ErrorAction")
        expect(args).to include("Stop")
      end
      subject.send(:execute_powershell, "path", {})
    end

    it "should automatically include module path" do
      expect(Vagrant::Util::PowerShell).to receive(:execute) do |path, *args|
        opts = args.detect{|i| i.is_a?(Hash)}
        expect(opts[:module_path]).not_to be_nil
      end
      subject.send(:execute_powershell, "path", {})
    end

    it "should covert hash options into arguments" do
      expect(Vagrant::Util::PowerShell).to receive(:execute) do |path, *args|
        expect(args).to include("-Custom")
        expect(args).to include("'Value'")
      end
      subject.send(:execute_powershell, "path", "Custom" => "Value")
    end

    it "should treat keys with `true` value as switches" do
      expect(Vagrant::Util::PowerShell).to receive(:execute) do |path, *args|
        expect(args).to include("-Custom")
        expect(args).not_to include("'true'")
      end
      subject.send(:execute_powershell, "path", "Custom" => true)
    end

    it "should not include keys with `false` value" do
      expect(Vagrant::Util::PowerShell).to receive(:execute) do |path, *args|
        expect(args).not_to include("-Custom")
      end
      subject.send(:execute_powershell, "path", "Custom" => false)
    end
  end
end
