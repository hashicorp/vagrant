# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/provisioners/shell/provisioner")

describe "Vagrant::Shell::Provisioner" do
  include_context "unit"

  let(:default_win_path) { "C:/tmp/vagrant-shell" }
  let(:env){ isolated_environment }
  let(:machine) {
    double(:machine, env: env, id: "ID").tap { |machine|
      allow(machine).to receive_message_chain(:config, :vm, :communicator).and_return(:not_winrm)
      allow(machine).to receive_message_chain(:config, :vm, :guest).and_return(:linux)
      allow(machine).to receive_message_chain(:communicate, :tap) {}
    }
  }

  before do
    allow(env).to receive(:tmp_path).and_return(Pathname.new("/dev/null"))
  end

  context "when reset is enabled" do
    let(:path) { nil }
    let(:inline) { "" }
    let(:communicator) { double("communicator") }

    let(:config) {
      double(
        :config,
        :args        => "doesn't matter",
        :env         => {},
        :upload_path => "arbitrary",
        :remote?     => false,
        :path        => path,
        :inline      => inline,
        :binary      => false,
        :reset       => true,
        :reboot      => false,
      )
    }

    let(:vsp) {
      VagrantPlugins::Shell::Provisioner.new(machine, config)
    }

    before {
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(vsp).to receive(:provision_ssh)
    }

    it "should provision and then reset the connection" do
      expect(vsp).to receive(:provision_ssh)
      expect(communicator).to receive(:reset!)
      vsp.provision
    end

    context "when path and inline are not set" do
      let(:path) { nil }
      let(:inline) { nil }

      it "should reset the connection and not provision" do
        expect(vsp).not_to receive(:provision_ssh)
        expect(communicator).to receive(:reset!)
        vsp.provision
      end
    end
  end

  context "when reboot is enabled" do
    let(:path) { nil }
    let(:inline) { "" }
    let(:communicator) { double("communicator") }
    let(:guest) { double("guest") }

    let(:config) {
      double(
        :config,
        :args        => "doesn't matter",
        :env         => {},
        :upload_path => "arbitrary",
        :remote?     => false,
        :path        => path,
        :inline      => inline,
        :binary      => false,
        :reset       => false,
        :reboot      => true
      )
    }

    let(:vsp) {
      VagrantPlugins::Shell::Provisioner.new(machine, config)
    }

    before {
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(machine).to receive(:guest).and_return(guest)
      allow(vsp).to receive(:provision_ssh)
    }

    it "should provision and then reboot the guest" do
      expect(vsp).to receive(:provision_ssh)
      expect(guest).to receive(:capability).with(:reboot)
      vsp.provision
    end

    context "when path and inline are not set" do
      let(:path) { nil }
      let(:inline) { nil }

      it "should reboot the guest and not provision" do
        expect(vsp).not_to receive(:provision_ssh)
        expect(guest).to receive(:capability).with(:reboot)
        vsp.provision
      end
    end
  end

  context "with a script that contains invalid us-ascii byte sequences" do
    let(:config) {
      double(
        :config,
        :args        => "doesn't matter",
        :env         => {},
        :upload_path => "arbitrary",
        :remote?     => false,
        :path        => nil,
        :inline      => script_that_is_incorrectly_us_ascii_encoded,
        :binary      => false,
        :reset       => false,
        :reboot      => false
      )
    }

    let(:script_that_is_incorrectly_us_ascii_encoded) {
      [207].pack("c*").force_encoding("US-ASCII")
    }

    it "does not raise an exception when normalizing newlines" do
      vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

      expect {
        vsp.provision
      }.not_to raise_error
    end
  end

  context "with a script that was set to freeze the string" do
    TEST_CONSTANT_VARIABLE = <<-TEST_CONSTANT_VARIABLE.freeze
      echo test
    TEST_CONSTANT_VARIABLE

    let(:script) { TEST_CONSTANT_VARIABLE }
    let(:config) {
      double(
        :config,
        :args        => "doesn't matter",
        :env         => {},
        :upload_path => "arbitrary",
        :remote?     => false,
        :path        => nil,
        :inline      => script,
        :binary      => false,
        :reset       => false,
        :reboot      => false
      )
    }

    it "does not raise an exception" do
      vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

      RSpec::Expectations.configuration.on_potential_false_positives = :nothing
      # This test should be fine, since we are specifically looking for the
      # string 'freeze' when RuntimeError is raised
      expect {
        vsp.provision
      }.not_to raise_error(RuntimeError)
    end
  end

  context "with remote script" do
    let(:filechecksum) { double("filechecksum", checksum: checksum_value) }
    let(:checksum_value) { double("checksum_value") }

    before do
      allow(FileChecksum).to receive(:new).and_return(filechecksum)
      allow_any_instance_of(Vagrant::Util::Downloader).to receive(:execute_curl).and_return(true)
    end

    context "that does not have matching sha1 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
      let(:config) {
        double(
          :config,
          :args        => "doesn't matter",
          :env         => {},
          :upload_path => "arbitrary",
          :remote?     => true,
          :path        => "http://example.com/script.sh",
          :binary      => false,
          :md5         => nil,
          :sha1        => 'EXPECTED_VALUE',
          :sha256      => nil,
          :sha384      => nil,
          :sha512      => nil,
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end

    context "that does not have matching sha256 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
      let(:config) {
        double(
          :config,
          :args        => "doesn't matter",
          :env         => {},
          :upload_path => "arbitrary",
          :remote?     => true,
          :path        => "http://example.com/script.sh",
          :binary      => false,
          :md5         => nil,
          :sha1        => nil,
          :sha256      => 'EXPECTED_VALUE',
          :sha384      => nil,
          :sha512      => nil,
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end

    context "that does not have matching sha384 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
      let(:config) {
        double(
          :config,
          :args        => "doesn't matter",
          :env         => {},
          :upload_path => "arbitrary",
          :remote?     => true,
          :path        => "http://example.com/script.sh",
          :binary      => false,
          :md5         => nil,
          :sha1        => nil,
          :sha256      => nil,
          :sha384      => 'EXPECTED_VALUE',
          :sha512      => nil,
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end

    context "that does not have matching sha512 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
      let(:config) {
        double(
          :config,
          :args        => "doesn't matter",
          :env         => {},
          :upload_path => "arbitrary",
          :remote?     => true,
          :path        => "http://example.com/script.sh",
          :binary      => false,
          :md5         => nil,
          :sha1        => nil,
          :sha256      => nil,
          :sha384      => nil,
          :sha512      => 'EXPECTED_VALUE',
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end

    context "that does not have matching md5 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
      let(:config) {
        double(
          :config,
          :args        => "doesn't matter",
          :env         => {},
          :upload_path => "arbitrary",
          :remote?     => true,
          :path        => "http://example.com/script.sh",
          :binary      => false,
          :md5         => 'EXPECTED_VALUE',
          :sha1        => nil,
          :sha256      => nil,
          :sha384      => nil,
          :sha512      => nil,
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end
  end

  describe "#upload_path" do
    context "when upload path is not set" do
      let(:vsp) {
        VagrantPlugins::Shell::Provisioner.new(machine, config)
      }

      let(:config) {
        double(
          :config,
          :args        => "doesn't matter",
          :env         => {},
          :upload_path => nil,
          :remote?     => false,
          :path        => "doesn't matter",
          :inline      => "doesn't matter",
          :binary      => false,
          :reset       => true,
          :reboot      => false,
        )
      }

      it "should default to /tmp/vagrant-shell" do
        expect(vsp.upload_path).to eq("/tmp/vagrant-shell")
      end

      context "windows" do
        before do
          allow(machine).to receive_message_chain(:config, :vm, :guest).and_return(:windows)
        end

        it "should default to C:/tmp/vagrant-shell" do
          expect(vsp.upload_path).to eq("C:/tmp/vagrant-shell")
        end
      end
    end

    context "when upload_path is set" do
      let(:upload_path) { "arbitrary" }

      let(:config) {
        double(
          :config,
          :args        => "doesn't matter",
          :env         => {},
          :upload_path => upload_path,
          :remote?     => false,
          :path        => "doesn't matter",
          :inline      => "doesn't matter",
          :binary      => false,
          :reset       => true,
          :reboot      => false,
        )
      }

      let(:vsp) {
        VagrantPlugins::Shell::Provisioner.new(machine, config)
      }

      it "should use the value from from config" do
        expect(vsp.upload_path).to eq("arbitrary")
      end

      context "windows" do
        let(:upload_path) { "C:\\Windows\\Temp" }

        before do
          allow(machine).to receive_message_chain(:config, :vm, :guest).and_return(:windows)
        end

        it "should normalize the slashes" do
          expect(vsp.upload_path).to eq("C:/Windows/Temp")
        end
      end
    end

    context "with cached value" do
      let(:config) { double(:config) }

      let(:vsp) {
        VagrantPlugins::Shell::Provisioner.new(machine, config)
      }

      before do
        vsp.instance_variable_set(:@_upload_path, "anything")
      end

      it "should use cached value" do
        expect(vsp.upload_path).to eq("anything")
      end
    end
  end

  describe "#provision_winrm" do
    let(:config) {
      double(
        :config,
        :args                            => "doesn't matter",
        :env                             => {},
        :upload_path                     => "arbitrary",
        :remote?                         => false,
        :path                            => "script/info.ps1",
        :binary                          => false,
        :md5                             => nil,
        :sha1                            => 'EXPECTED_VALUE',
        :sha256                          => nil,
        :sha384                          => nil,
        :sha512                          => nil,
        :reset                           => false,
        :reboot                          => false,
        :powershell_args                 => "",
        :name                            => nil,
        :privileged                      => false,
        :powershell_elevated_interactive => false,
        :keep_color                      => true,
      )
    }

    let(:vsp) {
      VagrantPlugins::Shell::Provisioner.new(machine, config)
    }

    let(:communicator) { double("communicator") }
    let(:guest) { double("guest") }
    let(:ui) { Vagrant::UI::Silent.new }

    before {
      allow(guest).to receive(:capability?).with(:wait_for_reboot).and_return(false)
      allow(communicator).to receive(:sudo)
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(machine).to receive(:guest).and_return(guest)
      allow(machine).to receive(:ui).and_return(ui)
      allow(vsp).to receive(:with_script_file).and_yield(config.path)
      allow(communicator).to receive(:upload).with(config.path, /arbitrary.ps1$/)
    }

    it "should output all received output" do
      stdout = ["two lines\n", "from stdout\n"]
      stderr = ["one line\n", "and partial from stderr"]
      expect(communicator).to receive(:sudo).
        and_yield(:stdout, stdout.first).
        and_yield(:stderr, stderr.first).
        and_yield(:stderr, stderr.last).
        and_yield(:stdout, stdout.last)
      allow(ui).to receive(:detail)
      expect(ui).to receive(:detail).with("two lines", any_args)
      expect(ui).to receive(:detail).with("from stdout", any_args)
      expect(ui).to receive(:detail).with("one line", any_args)
      expect(ui).to receive(:detail).with("and partial from stderr", any_args)
      vsp.send(:provision_winrm, "")
    end

    it "ensures that files are uploaded with an extension" do
      allow(vsp).to receive(:with_script_file).and_yield(config.path)
      expect(communicator).to receive(:upload).with(config.path, /arbitrary.ps1$/)
      vsp.send(:provision_winrm, "")
    end

    context "bat file being uploaded" do
      before do
        allow(config).to receive(:path).and_return("script/info.bat")
        allow(vsp).to receive(:with_script_file).and_yield(config.path)
      end

      it "ensures that files are uploaded same extension as provided path.bat" do
        expect(communicator).to receive(:upload).with(config.path, /arbitrary/)
        expect(communicator).to receive(:sudo).with(/arbitrary.bat/, anything)
        vsp.send(:provision_winrm, "")
      end
    end

    context "inline option set" do
      let(:config) {
        double(
          :config,
          :args                            => "doesn't matter",
          :env                             => {},
          :remote?                         => false,
          :inline                          => "some commands",
          :upload_path                     => nil,
          :path                            => nil,
          :binary                          => false,
          :md5                             => nil,
          :sha1                            => 'EXPECTED_VALUE',
          :sha256                          => nil,
          :sha384                          => nil,
          :sha512                          => nil,
          :reset                           => false,
          :reboot                          => false,
          :powershell_args                 => "",
          :name                            => nil,
          :privileged                      => false,
          :powershell_elevated_interactive => false
        )
      }

      it "creates an executable with an extension" do
        allow(machine).to receive_message_chain(:config, :winssh, :shell).and_return(nil)
        allow(vsp).to receive(:with_script_file).and_yield(default_win_path)
        allow(communicator).to receive(:upload).with(default_win_path, /vagrant-shell/)
        expect(communicator).to receive(:sudo).with(/vagrant-shell.ps1/, anything)
        vsp.send(:provision_winrm, "")
      end
    end
  end

  describe "#provision_winssh" do
    let(:config) {
      double(
        :config,
        :args                            => "doesn't matter",
        :env                             => {},
        :upload_path                     => "arbitrary",
        :remote?                         => false,
        :path                            => nil,
        :inline                          => "something",
        :binary                          => false,
        :md5                             => nil,
        :sha1                            => 'EXPECTED_VALUE',
        :sha256                          => nil,
        :sha384                          => nil,
        :sha512                          => nil,
        :reset                           => false,
        :reboot                          => false,
        :powershell_args                 => "",
        :name                            => nil,
        :privileged                      => false,
        :powershell_elevated_interactive => false,
        :keep_color                      => true,
      )
    }

    let(:vsp) {
      VagrantPlugins::Shell::Provisioner.new(machine, config)
    }

    let(:communicator) { double("communicator") }
    let(:guest) { double("guest") }
    let(:ui) { Vagrant::UI::Silent.new }

    before {
      allow(guest).to receive(:capability?).with(:wait_for_reboot).and_return(false)
      allow(communicator).to receive(:sudo)
      allow(communicator).to receive(:upload)
      allow(communicator).to receive_message_chain(:machine_config_ssh, :shell)
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(machine).to receive(:guest).and_return(guest)
      allow(machine).to receive(:ui).and_return(ui)
      allow(machine).to receive(:ssh_info).and_return(true)
    }

    context "ps1 file being uploaded" do
      before do
        allow(config).to receive(:path).and_return("script/info.ps1")
        allow(vsp).to receive(:with_script_file).and_yield(config.path)
      end

      it "ensures that files are uploaded same extension as provided path.ps1" do
        allow(machine).to receive_message_chain(:config, :winssh, :shell).and_return("cmd")
        expect(communicator).to receive(:upload).with(config.path, /arbitrary.ps1/)
        expect(communicator).to receive(:execute).with(/powershell.*arbitrary.ps1/, anything)
        vsp.send(:provision_winssh, "")
      end

      it "should output all received output" do
        stdout = ["two lines\n", "from stdout\n"]
        stderr = ["one line\n", "and partial from stderr"]
        expect(communicator).to receive(:execute).
          and_yield(:stdout, stdout.first).
          and_yield(:stderr, stderr.first).
          and_yield(:stderr, stderr.last).
          and_yield(:stdout, stdout.last)
        allow(ui).to receive(:detail)
        expect(ui).to receive(:detail).with("two lines", any_args)
        expect(ui).to receive(:detail).with("from stdout", any_args)
        expect(ui).to receive(:detail).with("one line", any_args)
        expect(ui).to receive(:detail).with("and partial from stderr", any_args)
        vsp.send(:provision_winssh, "")
      end
    end

    context "bat file being uploaded" do
      before do
        allow(config).to receive(:path).and_return("script/info.bat")
        allow(vsp).to receive(:with_script_file).and_yield(config.path)
      end

      it "ensures that files are uploaded same extension as provided path.bat" do
        allow(machine).to receive_message_chain(:config, :winssh, :shell).and_return("cmd")
        expect(communicator).to receive(:upload).with(config.path, /arbitrary.bat/)
        expect(communicator).to receive(:execute).with(/cmd.*arbitrary.bat/, anything)
        vsp.send(:provision_winssh, "")
      end
    end

    context "with inline script" do
      before do
        allow(vsp).to receive(:with_script_file).and_yield("/tmp/file/contents")
      end

      context "when upload path has a .ps1 extension" do
        before do
          allow(config).to receive(:upload_path).and_return("c:/tmp/vagrant-shell.ps1")
        end

        it "executes the remote script with powershell" do
          expect(communicator).to receive(:upload).with(anything, config.upload_path)
          expect(communicator).to receive(:execute).with(/powershell.*\.ps1/, anything)
          vsp.send(:provision_winssh, "")
        end
      end

      context "when upload path has a .bat extension" do
        before do
          allow(config).to receive(:upload_path).and_return("c:/tmp/vagrant-shell.bat")
        end

        it "executes the remote script with cmd" do
          expect(communicator).to receive(:upload).with(anything, config.upload_path)
          expect(communicator).to receive(:execute).with(/cmd.*\.bat/, anything)
          vsp.send(:provision_winssh, "")
        end
      end

      context "when upload path has no extension" do
        before do
          allow(config).to receive(:upload_path).and_return("c:/tmp/vagrant-shell")
        end

        context "when winssh shell is cmd" do
          before do
            allow(machine).to receive_message_chain(:config, :winssh, :shell).and_return("cmd")
          end

          it "adds an extension and executes the remote script with cmd" do
            expect(communicator).to receive(:upload).with(anything, /\.bat$/)
            expect(communicator).to receive(:execute).with(/cmd.*\.bat/, anything)
            vsp.send(:provision_winssh, "")
          end
        end

        context "when winssh shell is powershell" do
          before do
            allow(machine).to receive_message_chain(:config, :winssh, :shell).and_return("powershell")
          end

          it "adds an extension executes the remote script with powershell" do
            expect(communicator).to receive(:upload).with(anything, /\.ps1$/)
            expect(communicator).to receive(:execute).with(/powershell.*\.ps1/, anything)
            vsp.send(:provision_winssh, "")
          end
        end
      end
    end
  end

  describe "#handle_comm" do
    let(:ui) { Vagrant::UI::Silent.new }
    let(:keep_color) { false }
    let(:config) {
      double(
        :config,
        :keep_color  => keep_color,
      )
    }
    let(:env){ isolated_environment }
    let(:machine) { double(:machine, env: env, id: "ID") }
    let(:vsp) {
      VagrantPlugins::Shell::Provisioner.new(machine, config)
    }

    before do
      allow(machine).to receive(:ui).and_return(ui)
    end

    context "when type is stdout" do
      let(:type) { :stdout }
      let(:data) { "output data" }

      it "should output data through the ui" do
        expect(ui).to receive(:detail).and_call_original
        vsp.send(:handle_comm, type, data)
      end

      it "should color the output" do
        expect(ui).to receive(:detail).with(data, hash_including(color: :green)).
          and_call_original
        vsp.send(:handle_comm, type, data)
      end

      context "when configured to keep color" do
        let(:keep_color) { true }

        it "should not color the output" do
          expect(ui).to receive(:detail) do |msg, **opts|
            expect(msg).to eq(data)
            expect(opts).to be_empty
          end
          vsp.send(:handle_comm, type, data)
        end
      end
    end

    context "when type is stderr" do
      let(:type) { :stderr }
      let(:data) { "output data" }

      it "should output data through the ui" do
        expect(ui).to receive(:detail).and_call_original
        vsp.send(:handle_comm, type, data)
      end

      it "should color the output" do
        expect(ui).to receive(:detail).with(data, hash_including(color: :red)).
          and_call_original
        vsp.send(:handle_comm, type, data)
      end

      context "when configured to keep color" do
        let(:keep_color) { true }

        it "should not color the output" do
          expect(ui).to receive(:detail) do |msg, **opts|
            expect(msg).to eq(data)
            expect(opts).to be_empty
          end
          vsp.send(:handle_comm, type, data)
        end
      end
    end

    context "when type is not stdout or stderr" do
      let(:type) { :stdnull }
      let(:data) { "output data" }

      it "should not output data through the ui" do
        expect(ui).not_to receive(:detail)
        vsp.send(:handle_comm, type, data)
      end
    end
  end
end
