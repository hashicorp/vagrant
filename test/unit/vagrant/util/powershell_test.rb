require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/powershell'

describe Vagrant::Util::PowerShell do
  include_context "unit"

  after{ described_class.reset! }

  describe ".version" do
    before do
      allow(described_class).to receive(:executable)
        .and_return("powershell")
      allow(Vagrant::Util::Subprocess).to receive(:execute)
    end

    after do
      described_class.version
    end

    it "should execute powershell command" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("powershell", any_args)
    end

    it "should use the default timeout" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args, hash_including(
        timeout: Vagrant::Util::PowerShell::DEFAULT_VERSION_DETECTION_TIMEOUT))
    end

    it "should use environment variable provided timeout" do
      with_temp_env("VAGRANT_POWERSHELL_VERSION_DETECTION_TIMEOUT" => "1") do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args, hash_including(
          timeout: 1))
        described_class.version
      end
    end

    it "should use default timeout when environment variable value is invalid" do
      with_temp_env("VAGRANT_POWERSHELL_VERSION_DETECTION_TIMEOUT" => "invalid value") do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args, hash_including(
          timeout: Vagrant::Util::PowerShell::DEFAULT_VERSION_DETECTION_TIMEOUT))
        described_class.version
      end
    end
  end

  describe ".executable" do
    before{ allow(Vagrant::Util::Platform).to receive(:wsl?).and_return(false) }

    context "when found in PATH" do
      before{ expect(Vagrant::Util::Which).to receive(:which).with("powershell").and_return(true) }

      it "should return powershell string" do
        expect(described_class.executable).to eq("powershell")
      end
    end

    context "when not found in PATH" do
      before{ expect(Vagrant::Util::Which).to receive(:which).with("powershell").and_return(nil) }

      it "should return nil" do
        expect(described_class.executable).to be_nil
      end

      context "when within WSL" do
        before do
          allow(Vagrant::Util::Which).to receive(:which).with(/powershell/).and_return(nil)
          expect(Vagrant::Util::Platform).to receive(:wsl?).and_return(true)
        end

        it "should check PATH with .exe extension" do
          expect(Vagrant::Util::Which).to receive(:which).with("powershell.exe")
          described_class.executable
        end

        it "should return powershell.exe when found" do
          expect(Vagrant::Util::Which).to receive(:which).with("powershell.exe").and_return(true)
          expect(described_class.executable).to eq("powershell.exe")
        end

        it "should return nil when not found" do
          expect(described_class.executable).to be_nil
        end

        it "should check for powershell with full path" do
          expect(Vagrant::Util::Which).to receive(:which).with(/Windows\/System32.+powershell.exe/)
          described_class.executable
        end
      end
    end
  end

  describe ".available?" do
    context "when powershell executable is available" do
      before{ expect(described_class).to receive(:executable).and_return("powershell") }

      it "should be true" do
        expect(described_class.available?).to be(true)
      end
    end

    context "when powershell executable is not available" do
      before{ expect(described_class).to receive(:executable).and_return(nil) }

      it "should be false" do
        expect(described_class.available?).to be(false)
      end
    end
  end

  describe ".execute" do
    before do
      allow(described_class).to receive(:validate_install!)
      allow(Vagrant::Util::Subprocess).to receive(:execute)
    end

    it "should validate installation before use" do
      expect(described_class).to receive(:validate_install!)
      described_class.execute("command")
    end

    it "should include command to execute" do
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        comm = args.detect{|s| s.to_s.include?("custom-command") }
        expect(comm.to_s).to include("custom-command")
      end
      described_class.execute("custom-command")
    end

    it "should accept custom environment" do
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        comm = args.detect{|s| s.to_s.include?("custom-command") }
        expect(comm.to_s).to include("$env:TEST_KEY=test-value")
      end
      described_class.execute("custom-command", env: {"TEST_KEY" => "test-value"})
    end

    it "should define a custom module path" do
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        comm = args.detect{|s| s.to_s.include?("custom-command") }
        expect(comm.to_s).to include("$env:PSModulePath+';C:\\My-Path'")
      end
      described_class.execute("custom-command", module_path: "C:\\My-Path")
    end
  end

  describe ".execute_cmd" do
    let(:result) do
      Vagrant::Util::Subprocess::Result.new(
        exit_code, stdout, stderr)
    end
    let(:exit_code){ 0 }
    let(:stdout){ "" }
    let(:stderr){ "" }

    before do
      allow(described_class).to receive(:validate_install!)
      allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(result)
    end

    it "should validate installation before use" do
      expect(described_class).to receive(:validate_install!)
      described_class.execute_cmd("command")
    end

    it "should include command to execute" do
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        comm = args.detect{|s| s.to_s.include?("custom-command") }
        expect(comm.to_s).to include("custom-command")
        result
      end
      described_class.execute_cmd("custom-command")
    end

    it "should accept custom environment" do
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        comm = args.detect{|s| s.to_s.include?("custom-command") }
        expect(comm.to_s).to include("$env:TEST_KEY=test-value")
        result
      end
      described_class.execute_cmd("custom-command", env: {"TEST_KEY" => "test-value"})
    end

    it "should define a custom module path" do
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        comm = args.detect{|s| s.to_s.include?("custom-command") }
        expect(comm.to_s).to include("$env:PSModulePath+';C:\\My-Path'")
        result
      end
      described_class.execute_cmd("custom-command", module_path: "C:\\My-Path")
    end

    context "with command output" do
      let(:stdout){ "custom-output" }

      it "should return stdout" do
        expect(described_class.execute_cmd("cmd")).to eq(stdout)
      end
    end

    context "with failed command" do
      let(:exit_code){ 1 }

      it "should return nil" do
        expect(described_class.execute_cmd("cmd")).to be_nil
      end
    end
  end

  describe ".execute_inline" do
    let(:result) do
      Vagrant::Util::Subprocess::Result.new(
        exit_code, stdout, stderr)
    end
    let(:exit_code){ 0 }
    let(:stdout){ "" }
    let(:stderr){ "" }
    let(:command) { ["run", "--this", "custom-command"] }

    before do
      allow(described_class).to receive(:validate_install!)
      allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(result)
    end

    it "should validate installation before use" do
      expect(described_class).to receive(:validate_install!)
      described_class.execute_inline(command)
    end

    it "should include command to execute" do
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        comm = args.detect{|s| s.to_s.include?("custom-command") }
        expect(comm.to_s).to include("custom-command")
        result
      end
      described_class.execute_inline(command)
    end

    it "should accept custom environment" do
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        comm = args.detect{|s| s.to_s.include?("custom-command") }
        expect(comm.to_s).to include("$env:TEST_KEY=test-value")
        result
      end
      described_class.execute_inline(command, env: {"TEST_KEY" => "test-value"})
    end

    it "should define a custom module path" do
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        comm = args.detect{|s| s.to_s.include?("custom-command") }
        expect(comm.to_s).to include("$env:PSModulePath+';C:\\My-Path'")
        result
      end
      described_class.execute_inline(command, module_path: "C:\\My-Path")
    end

    it "should return a result instance" do
      expect(described_class.execute_inline(command)).to eq(result)
    end
  end

  describe ".validate_install!" do
    before do
      allow(described_class).to receive(:available?).and_return(true)
    end

    context "with version under minimum required" do
      before{ expect(described_class).to receive(:version).and_return("2.1").at_least(:once) }

      it "should raise an error" do
        expect{ described_class.validate_install! }.to raise_error(Vagrant::Errors::PowerShellInvalidVersion)
      end
    end

    context "with version above minimum required" do
      before{ expect(described_class).to receive(:version).and_return("3.1").at_least(:once) }

      it "should return true" do
        expect(described_class.validate_install!).to be(true)
      end
    end

  end
end
