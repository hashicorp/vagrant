# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/docker/synced_folder")

describe VagrantPlugins::DockerProvider::SyncedFolder do
  subject { described_class.new }

  let(:provider_config) { double("provider_config", volumes: []) }
  let(:machine) { double("machine") }

  before do
    allow(machine).to receive(:provider_name).and_return(:docker)
    allow(machine).to receive(:provider_config).and_return(provider_config)
  end

  describe "#usable?" do
    it "is usable" do
      expect(subject).to be_usable(machine)
    end

    it "is not usable if provider isn't docker" do
      allow(machine).to receive(:provider_name).and_return(:virtualbox)
      expect(subject).to_not be_usable(machine)
    end

    it "raises an error if bad provider if specified" do
      allow(machine).to receive(:provider_name).and_return(:virtualbox)
      expect { subject.usable?(machine, true) }.
        to raise_error(VagrantPlugins::DockerProvider::Errors::SyncedFolderNonDocker)
    end
  end

  describe "#prepare" do
    let(:folders) {{"/guest/dir1"=>
                    {:guestpath=>"/guest/dir1",
                     :hostpath=>"/Users/brian/code/vagrant-sandbox",
                     :disabled=>false,
                     :__vagrantfile=>true},
                     "/dev/vagrant"=>
                    {:guestpath=>"/dev/vagrant",
                     :hostpath=>"/Users/brian/code/vagrant",
                     :disabled=>false,
                     :__vagrantfile=>true}}}

    let(:consistency_folders) {{"/guest/dir1"=>
                                {:docker_consistency=>"cached",
                                 :guestpath=>"/guest/dir1",
                                 :hostpath=>"/Users/brian/code/vagrant-sandbox",
                                 :disabled=>false,
                                 :__vagrantfile=>true},
                                 "/dev/vagrant"=>
                                {:docker_consistency=>"delegated",
                                 :guestpath=>"/dev/vagrant",
                                 :hostpath=>"/Users/brian/code/vagrant",
                                 :disabled=>false,
                                 :__vagrantfile=>true}}}
    let(:options) { {} }

    let(:volumes) { ["/Users/brian/code/vagrant-sandbox:/guest/dir1",
                     "/Users/brian/code/vagrant:/dev/vagrant"] }
    let(:consistency_volumes) { ["/Users/brian/code/vagrant-sandbox:/guest/dir1:cached",
                                 "/Users/brian/code/vagrant:/dev/vagrant:delegated"] }

    it "prepares folders to mount" do
      subject.prepare(machine, folders, options)
      expect(machine.provider_config.volumes).to eq(volumes)
    end

    it "sets volume consistency if specified" do
      subject.prepare(machine, consistency_folders, options)
      expect(machine.provider_config.volumes).to eq(consistency_volumes)
    end
  end
end
