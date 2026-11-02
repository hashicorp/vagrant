# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../base"

require Vagrant.source_root.join("plugins/synced_folders/unix_mount_helpers")

describe VagrantPlugins::SyncedFolder::UnixMountHelpers do
  include_context "unit"

  subject{
    Class.new do |c|
      def self.name; "UnixMountHelpersTest"; end
      extend VagrantPlugins::SyncedFolder::UnixMountHelpers
    end
  }


  describe ".merge_mount_options" do
    let(:base){ ["opt1", "opt2=on", "opt3", "opt4,opt5=off"] }
    let(:override){ ["opt8", "opt4=on,opt6,opt7=true"] }

    context "with no override" do
      it "should split options into individual options" do
        result = subject.merge_mount_options(base, [])
        expect(result.size).to eq(5)
      end
    end

    context "with overrides" do
      it "should merge all options" do
        result = subject.merge_mount_options(base, override)
        expect(result.size).to eq(8)
      end

      it "should override options defined in base" do
        result = subject.merge_mount_options(base, override)
        expect(result).to include("opt4=on")
      end
    end
  end
end
