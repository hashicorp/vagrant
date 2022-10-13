require File.expand_path("../../../base", __FILE__)

require "vagrant/util/platform"
require "vagrant/util/ssh"

describe Vagrant::Util::SSH do
  include_context "unit"
  let(:private_key_path) { temporary_file.to_s }

  describe "checking key permissions" do
    let(:key_path) { temporary_file }

    it "should do nothing on Windows" do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)

      key_path.chmod(0700)

      # Get the mode now and verify that it is untouched afterwards
      mode = key_path.stat.mode
      described_class.check_key_permissions(key_path)
      expect(key_path.stat.mode).to eq(mode)
    end

    it "should fix the permissions", :skip_windows do
      key_path.chmod(0644)

      described_class.check_key_permissions(key_path)
      expect(key_path.stat.mode).to eq(0100600)
    end
  end

  describe "#exec" do
    let(:ssh_info) {{
      host: "localhost",
      port: 2222,
      username: "vagrant",
      private_key_path: [private_key_path],
      compression: true,
      dsa_authentication: true
    }}

    let(:ssh_path) { /.*ssh/ }

    before {
      allow(Vagrant::Util::Which).to receive(:which).with("ssh", any_args).and_return(ssh_path)
    }

    it "searches original PATH for executable" do
      expect(Vagrant::Util::Which).to receive(:which).with("ssh", original_path: true).and_return("valid-return")
      allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)
      described_class.exec(ssh_info)
    end

    it "searches current PATH if original PATH did not result in valid executable" do
      expect(Vagrant::Util::Which).to receive(:which).with("ssh", original_path: true).and_return(nil)
      expect(Vagrant::Util::Which).to receive(:which).with("ssh").and_return("valid-return")
      allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)
      described_class.exec(ssh_info)
    end

    it "raises an exception if there is no ssh" do
      allow(Vagrant::Util::Which).to receive(:which).and_return(nil)

      expect { described_class.exec(ssh_info) }.
        to raise_error Vagrant::Errors::SSHUnavailable
    end

    it "raises an exception if there is no ssh and platform is windows" do
      allow(Vagrant::Util::Which).to receive(:which).and_return(nil)
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)

      expect { described_class.exec(ssh_info) }.
        to raise_error Vagrant::Errors::SSHUnavailableWindows
    end

    it "raises an exception if the platform is windows and uses PuTTY Link" do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_return(double("output", stdout: 'PuTTY Link'))

      expect { described_class.exec(ssh_info) }.
        to raise_error Vagrant::Errors::SSHIsPuttyLink
    end

    it "invokes SSH with options if subprocess is not allowed" do
      allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)

      expect(described_class.exec(ssh_info)).to eq(nil)
      expect(Vagrant::Util::SafeExec).to have_received(:exec)
        .with(ssh_path, "vagrant@localhost", "-p", "2222", "-o", "LogLevel=FATAL","-o", "Compression=yes", "-o", "DSAAuthentication=yes", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", ssh_info[:private_key_path][0])
    end

    context "when using '%' in a private_key_path" do
      let(:private_key_path) { "/tmp/percent%folder" }
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        private_key_path: [private_key_path],
        compression: true,
        dsa_authentication: true
      }}

      it "uses the IdentityFile argument and escapes the '%' character" do
        allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)
        described_class.exec(ssh_info)

        expect(Vagrant::Util::SafeExec).to have_received(:exec)
          .with(ssh_path, "vagrant@localhost", "-p", "2222", "-o", "LogLevel=FATAL","-o", "Compression=yes", "-o", "DSAAuthentication=yes", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-o", "IdentityFile=\"/tmp/percent%%folder\"")
      end
    end

    context "when disabling compression or dsa_authentication flags" do
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        private_key_path: [private_key_path],
        compression: false,
        dsa_authentication: false
      }}

      it "does not include compression or dsa_authentication flags if disabled" do
        allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)

        expect(described_class.exec(ssh_info)).to eq(nil)
        expect(Vagrant::Util::SafeExec).to have_received(:exec)
          .with(ssh_path, "vagrant@localhost", "-p", "2222", "-o", "LogLevel=FATAL", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", ssh_info[:private_key_path][0])
      end
    end

    context "when verify_host_key is true" do
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        private_key_path: [private_key_path],
        verify_host_key: true
      }}

      it "does not disable StrictHostKeyChecking or set UserKnownHostsFile" do
        allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)

        expect(described_class.exec(ssh_info)).to eq(nil)
        expect(Vagrant::Util::SafeExec).to have_received(:exec)
          .with(ssh_path, "vagrant@localhost", "-p", "2222", "-o", "LogLevel=FATAL", "-i", ssh_info[:private_key_path][0])
      end
    end

    context "when not on solaris not using plain mode or with keys_only enabled" do
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        private_key_path: [private_key_path],
        keys_only: true
      }}

      it "adds IdentitiesOnly as an option for ssh" do
        allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)
        allow(Vagrant::Util::Platform).to receive(:solaris?).and_return(false)

        expect(described_class.exec(ssh_info, {plain_mode: true})).to eq(nil)
        expect(Vagrant::Util::SafeExec).to have_received(:exec)
          .with(ssh_path, "localhost", "-p", "2222", "-o", "LogLevel=FATAL", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null")
      end
    end

    context "when forward_x11 is enabled" do
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        private_key_path: [private_key_path],
        forward_x11: true
      }}

      it "enables ForwardX11 options" do
        allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)

        expect(described_class.exec(ssh_info)).to eq(nil)
        expect(Vagrant::Util::SafeExec).to have_received(:exec)
          .with(ssh_path, "vagrant@localhost", "-p", "2222", "-o", "LogLevel=FATAL", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", ssh_info[:private_key_path][0],"-o", "ForwardX11=yes", "-o", "ForwardX11Trusted=yes")
      end
    end

    context "when forward_agent is enabled" do
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        private_key_path: [private_key_path],
        forward_agent: true
      }}

      it "enables agent forwarding options" do
        allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)

        expect(described_class.exec(ssh_info)).to eq(nil)
        expect(Vagrant::Util::SafeExec).to have_received(:exec)
          .with(ssh_path, "vagrant@localhost", "-p", "2222", "-o", "LogLevel=FATAL", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", ssh_info[:private_key_path][0],"-o", "ForwardAgent=yes")
      end
    end

    context "when extra_args is provided as an array" do
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        private_key_path: [private_key_path],
        extra_args: ["-L", "8008:localhost:80"]
      }}

      it "enables agent forwarding options" do
        allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)

        expect(described_class.exec(ssh_info)).to eq(nil)
        expect(Vagrant::Util::SafeExec).to have_received(:exec)
          .with(ssh_path, "vagrant@localhost", "-p", "2222", "-o", "LogLevel=FATAL", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", ssh_info[:private_key_path][0], "-L", "8008:localhost:80")
      end
    end

    context "when extra_args is provided as a string" do
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        private_key_path: [private_key_path],
        extra_args: "-6"
      }}

      it "enables agent forwarding options" do
        allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)

        expect(described_class.exec(ssh_info)).to eq(nil)
        expect(Vagrant::Util::SafeExec).to have_received(:exec)
          .with(ssh_path, "vagrant@localhost", "-p", "2222", "-o", "LogLevel=FATAL", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", ssh_info[:private_key_path][0], "-6")
      end
    end

    context "when config is provided" do
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        config: "/path/to/config"
      }}

      it "enables ssh config loading" do
        allow(Vagrant::Util::SafeExec).to receive(:exec).and_return(nil)
        expect(Vagrant::Util::SafeExec).to receive(:exec) do |exe_path, *args|
          expect(exe_path).to match(ssh_path)
          config_options = ["-F", "/path/to/config"]
          expect(args & config_options).to eq(config_options)
        end

        expect(described_class.exec(ssh_info)).to eq(nil)
      end
    end

    context "with subprocess enabled" do
      let(:ssh_info) {{
        host: "localhost",
        port: 2222,
        username: "vagrant",
        private_key_path: [private_key_path],
      }}

      it "executes SSH in a subprocess with options and returns an exit code Fixnum" do
        # mock out ChildProcess
        process = double()
        allow(ChildProcess).to receive(:build).and_return(process)
        allow(process).to receive(:io).and_return(true)
        allow(process.io).to receive(:inherit!).and_return(true)
        allow(process).to receive(:start).and_return(true)
        allow(process).to receive(:wait).and_return(true)

        allow(process).to receive(:exit_code).and_return(0)

        expect(described_class.exec(ssh_info, {subprocess: true})).to eq(0)
      end
    end
  end
end
