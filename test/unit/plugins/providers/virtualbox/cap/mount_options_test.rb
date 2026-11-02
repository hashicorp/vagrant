# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::ProviderVirtualBox::Cap::MountOptions" do
  let(:caps) do
    VagrantPlugins::ProviderVirtualBox::Plugin
      .components
      .synced_folder_capabilities[:virtualbox]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:mount_owner){ "vagrant" }
  let(:mount_group){ "vagrant" }
  let(:mount_uid){ "1000" }
  let(:mount_gid){ "1000" }
  let(:mount_name){ "vagrant" }
  let(:mount_guest_path){ "/vagrant" }
  let(:folder_options) do
    {
      owner: mount_owner,
      group: mount_group,
      hostpath: "/host/directory/path"
    }
  end
  let(:cap){ caps.get(:mount_options) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".mount_options" do

    before do
      allow(comm).to receive(:sudo).with(any_args)
      allow(comm).to receive(:execute).with(any_args)
    end

    context "with owner user ID explicitly defined" do

      before do
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
      end

      context "with user ID provided as Integer" do
        let(:mount_owner){ 2000 }
        it "generates the expected mount command using mount_owner directly" do
          out_mount_options, out_mount_uid, out_mount_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
          expect(out_mount_options).to eq("uid=#{mount_owner},gid=#{mount_gid},_netdev")
          expect(out_mount_uid).to eq(mount_owner)
          expect(out_mount_gid).to eq(mount_gid)
        end
      end

      context "with user ID provided as String" do
        let(:mount_owner){ "2000" }
        it "generates the expected mount command using mount_owner directly" do
          out_mount_options, out_mount_uid, out_mount_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
          expect(out_mount_options).to eq("uid=#{mount_owner},gid=#{mount_gid},_netdev")
          expect(out_mount_uid).to eq(mount_owner)
          expect(out_mount_gid).to eq(mount_gid)
        end
      end

    end

    context "with owner group ID explicitly defined" do

      before do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
      end

      context "with owner group ID provided as Integer" do
        let(:mount_group){ 2000 }

        it "generates the expected mount command using mount_group directly" do
          out_mount_options, out_mount_uid, out_mount_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
          expect(out_mount_options).to eq("uid=#{mount_uid},gid=#{mount_group},_netdev")
          expect(out_mount_uid).to eq(mount_uid)
          expect(out_mount_gid).to eq(mount_group)
        end
      end

      context "with owner group ID provided as String" do
        let(:mount_group){ "2000" }

        it "generates the expected mount command using mount_group directly" do
          out_mount_options, out_mount_uid, out_mount_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
          expect(out_mount_options).to eq("uid=#{mount_uid},gid=#{mount_group},_netdev")
          expect(out_mount_uid).to eq(mount_uid)
          expect(out_mount_gid).to eq(mount_group)
        end
      end

    end

    context "with non-existent default owner group" do
      it "fetches the effective group ID of the user" do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_raise(Vagrant::Errors::VirtualBoxMountFailed, {command: '', output: ''})
        expect(comm).to receive(:execute).with("id -g #{mount_owner}", anything).and_yield(:stdout, "1").and_return(0)
        out_mount_options, out_mount_uid, out_mount_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
        expect(out_mount_options).to eq("uid=#{mount_uid},gid=1,_netdev")
      end
    end

    context "with non-existent owner group" do
      it "raises an error" do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_raise(Vagrant::Errors::VirtualBoxMountFailed, {command: '', output: ''})
        expect do
          cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
        end.to raise_error Vagrant::Errors::VirtualBoxMountFailed
      end
    end

    context "with read-only option defined" do
      it "does not chown mounted guest directory" do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
        out_mount_options, out_mount_uid, out_mount_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options.merge(mount_options: ["ro"]))
        expect(out_mount_options).to eq("ro,uid=#{mount_uid},gid=#{mount_gid},_netdev")
        expect(out_mount_uid).to eq(mount_uid)
        expect(out_mount_gid).to eq(mount_gid)
      end
    end

    context "with custom mount options" do
      let(:ui){ Vagrant::UI::Silent.new }
      before do
        allow(machine).to receive(:ui).and_return(ui)
      end

      context "with uid defined" do
        let(:options_uid){ '1234' }

        it "should only include uid defined within mount options" do
          expect(comm).not_to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
          expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
          out_mount_options, out_mount_uid, out_mount_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options.merge(mount_options: ["uid=#{options_uid}"]) )
          expect(out_mount_options).to eq("uid=#{options_uid},gid=#{mount_gid},_netdev")
          expect(out_mount_uid).to eq(options_uid)
          expect(out_mount_gid).to eq(mount_gid)
        end
      end

      context "with gid defined" do
        let(:options_gid){ '1234' }

        it "should only include gid defined within mount options" do
          expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
          expect(comm).not_to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
          out_mount_options, out_mount_uid, out_mount_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options.merge(mount_options: ["gid=#{options_gid}"]) )
          expect(out_mount_options).to eq("uid=#{mount_uid},gid=#{options_gid},_netdev")
          expect(out_mount_uid).to eq(mount_uid)
          expect(out_mount_gid).to eq(options_gid)
        end
      end

      context "with uid and gid defined" do
        let(:options_gid){ '1234' }
        let(:options_uid){ '1234' }

        it "should only include uid and gid defined within mount options" do
          expect(comm).not_to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
          expect(comm).not_to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{options_gid}:")
          out_mount_options, out_mount_uid, out_mount_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options.merge(mount_options: ["uid=#{options_uid}", "gid=#{options_gid}"]) )
          expect(out_mount_options).to eq("uid=#{options_uid},gid=#{options_gid},_netdev")
          expect(out_mount_uid).to eq(options_uid)
          expect(out_mount_gid).to eq(options_gid)
        end
      end
    end
  end
end
