# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestDarwin::Cap::MountVmwareSharedFolder" do
  let(:described_class) do
    VagrantPlugins::GuestDarwin::Plugin
      .components
      .guest_capabilities[:darwin]
      .get(:mount_vmware_shared_folder)
  end

  let(:machine) { double("machine", communicate: communicator, id: "MACHINE_ID", guest: guest) }
  let(:guest) {double("guest")}
  let(:communicator) { double("communicator") }

  before do
    allow(communicator).to receive(:test)
    allow(communicator).to receive(:sudo)
    allow(VagrantPlugins::GuestDarwin::Plugin).to receive(:action_hook)
  end

  describe ".mount_vmware_shared_folder" do
    let(:name) { "-vagrant" }
    let(:guestpath) { "/vagrant" }
    let(:options) { {} }

    before do
      allow(described_class).to receive(:system_firmlink?)
      described_class.reset!
    end

    after { 
      described_class.mount_vmware_shared_folder(machine, name, guestpath, options) 
    }

    context "with APFS root container" do
      before do
        expect(communicator).to receive(:test).with("test -d /System/Volumes/Data").and_return(true)
      end

      it "should check for existing entry" do
        expect(communicator).to receive(:test).with(/synthetic\.conf/)
      end

      context "with guest path within existing directory" do
        let(:guestpath) { "/Users/vagrant/workspace" }

        it "should test if guest path is a symlink" do
          expect(communicator).to receive(:test).with(/test -L/)
        end

        it "should remove guest path if it is a symlink" do
          expect(communicator).to receive(:test).with(/test -L/).and_return(true)
          expect(communicator).to receive(:sudo).with(/rm -f/)
        end

        it "should not test if guest path is a directory if guest path is symlink" do
          expect(communicator).to receive(:test).with(/test -L/).and_return(true)
          expect(communicator).not_to receive(:test).with(/test -d/)
        end

        it "should test if guest path is directory if not a symlink" do
          expect(communicator).to receive(:test).with(/test -d/)
        end

        it "should remove guest path if it is a directory" do
          expect(communicator).to receive(:test).with(/test -d/).and_return(true)
          expect(communicator).to receive(:sudo).with(/rm -Rf/)
        end

        it "should create the symlink to the vmware folder" do
          expect(communicator).to receive(:sudo).with(/ln -s/)
        end

        it "should create the symlink within the writable APFS container" do
          expect(communicator).to receive(:sudo).with(%r{ln -s .+/System/Volumes/Data.+})
        end

        {
          19 => "-B",
          20 => "-t",
          21 => "-t",
          nil => "-B"
        }.each do |version, expected_flag|
          it "should re-bootstrap root dir for darwin version #{version}" do
            expect(communicator).to receive(:sudo).with(/apfs.util #{expected_flag}/, any_args)
            expect(guest).to receive(:capability).with("darwin_major_version").and_return(version)

            described_class.mount_vmware_shared_folder(machine, name, guestpath, options) 
            described_class.apfs_firmlinks_delayed[machine.id].call
          end
        end

        context "when firmlink is provided by the system" do
          before { expect(described_class).to receive(:system_firmlink?).and_return(true) }

          it "should not register an action hook" do
            expect(VagrantPlugins::GuestDarwin::Plugin).not_to receive(:action_hook).with(:apfs_firmlinks, :after_synced_folders)
          end
        end
      end
    end

    context "with non-APFS root container" do
      before do
        expect(communicator).to receive(:test).with("test -d /System/Volumes/Data").and_return(false)
      end

      it "should test if guest path is a symlink" do
        expect(communicator).to receive(:test).with(/test -L/)
      end

      it "should remove guest path if it is a symlink" do
        expect(communicator).to receive(:test).with(/test -L/).and_return(true)
        expect(communicator).to receive(:sudo).with(/rm -f/)
      end

      it "should not test if guest path is a directory if guest path is symlink" do
        expect(communicator).to receive(:test).with(/test -L/).and_return(true)
        expect(communicator).not_to receive(:test).with(/test -d/)
      end

      it "should test if guest path is directory if not a symlink" do
        expect(communicator).to receive(:test).with(/test -d/)
      end

      it "should remove guest path if it is a directory" do
        expect(communicator).to receive(:test).with(/test -d/).and_return(true)
        expect(communicator).to receive(:sudo).with(/rm -Rf/)
      end

      it "should create the symlink to the vmware folder" do
        expect(communicator).to receive(:sudo).with(/ln -s/)
      end

      it "should not register an action hook" do
        expect(VagrantPlugins::GuestDarwin::Plugin).not_to receive(:action_hook).with(:apfs_firmlinks, :after_synced_folders)
      end
    end
  end

  describe ".system_firmlink?" do
    before { described_class.reset! }

    context "when file does not exist" do
      before { allow(File).to receive(:exist?).with("/usr/share/firmlinks").and_return(false) }

      it "should always return false" do
        expect(described_class.system_firmlink?("test")).to be_falsey
      end
    end

    context "when file does exist" do
      let(:content) {
        ["/Users\tUsers",
          "/usr/local\tusr/local"]
      }

      before do
        expect(File).to receive(:exist?).with("/usr/share/firmlinks").and_return(true)
        expect(File).to receive(:readlines).with("/usr/share/firmlinks").and_return(content)
      end

      it "should return true when firmlink exists" do
        expect(described_class.system_firmlink?("/Users")).to be_truthy
      end

      it "should return true when firmlink is not prefixed with /" do
        expect(described_class.system_firmlink?("Users")).to be_truthy
      end

      it "should return false when firmlink does not exist" do
        expect(described_class.system_firmlink?("/testing")).to be_falsey
      end
    end
  end

  describe ".write_apfs_firmlinks" do
    let(:env) { nil }
    let(:action) { double("action", call: nil) }
    let(:machine) { double("machine", id: machine_id) }
    let(:machine_id) { double("machine_id") }
    let(:delayed) { {} }

    context "when env is nil" do
      it "should be a no-op" do
        expect(described_class).not_to receive(:apfs_firmlinks_delayed)
        described_class.write_apfs_firmlinks(env)
      end
    end

    context "when env is empty hash" do
      let(:env) { {} }

      it "should be a no-op" do
        expect(described_class).not_to receive(:apfs_firmlinks_delayed)
        described_class.write_apfs_firmlinks(env)
      end
    end

    context "when machine is defined within env" do
      let(:env) { {machine: machine} }

      it "should request the stored delayed actions" do
        expect(described_class).to receive(:apfs_firmlinks_delayed).and_return(delayed)
        described_class.write_apfs_firmlinks(env)
      end
    end

    context "when delayed action is stored for machine" do
      let(:env) { {machine: machine} }

      before { described_class.apfs_firmlinks_delayed[machine_id] = action }
      after { described_class.apfs_firmlinks_delayed.clear }

      it "should call the delayed action" do
        expect(action).to receive(:call)
        described_class.write_apfs_firmlinks(env)
      end

      it "should remove the action after calling" do
        expect(action).to receive(:call)
        described_class.write_apfs_firmlinks(env)
        expect(delayed).to be_empty
      end
    end
  end
end
