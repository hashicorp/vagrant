# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/box/command/outdated")

describe VagrantPlugins::CommandBox::Command::Outdated do
  include_context "unit"

  let(:argv)     { [] }
  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  subject { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }

  before do
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
  end

  context "with force argument" do
    let(:argv) { ["--force"] }

    it "passes along the force update option" do
      expect(action_runner).to receive(:run).with(any_args) { |action, opts|
        expect(opts[:box_outdated_force]).to be_truthy
        true
      }
      subject.execute
    end
  end

  context "with global argument" do
    let(:argv) { ["--global"] }

    it "calls outdated_global" do
      expect(subject).to receive(:outdated_global)

      subject.execute
    end

    describe ".outdated_global" do
      let(:test_iso_env) { isolated_environment }

      let(:md) {
        md = Vagrant::BoxMetadata.new(StringIO.new(<<-RAW))
      {
        "name": "foo",
        "versions": [
          {
            "version": "1.0"
          },
          {
            "version": "1.1",
            "providers": [
              {
                "name": "virtualbox",
                "url": "bar"
              }
            ]
          },
          {
            "version": "1.2",
            "providers": [
              {
                "name": "vmware",
                "url": "baz"
              }
            ]
          }
        ]
      }
        RAW
      }

      let(:collection) do
        collection = double("collection")
        allow(collection).to receive(:all).and_return([box])
        allow(collection).to receive(:find).and_return(box)
        collection
      end

      context "when latest version is available for provider" do
        let(:box) do
          box_dir = test_iso_env.box3("foo", "1.0", :vmware)
          box = Vagrant::Box.new(
            "foo", :vmware, "1.0", box_dir, metadata_url: "foo")
          allow(box).to receive(:load_metadata).and_return(md)
          box
        end

        it "displays the latest version" do
          allow(iso_env).to receive(:boxes).and_return(collection)

          expect(I18n).to receive(:t).with(/box_outdated$/, hash_including(latest: "1.2"))

          subject.outdated_global({})
        end
      end

      context "when latest version isn't available for provider" do
        let(:box) do
          box_dir = test_iso_env.box3("foo", "1.0", :virtualbox)
          box = Vagrant::Box.new(
            "foo", :virtualbox, "1.0", box_dir, metadata_url: "foo")
          allow(box).to receive(:load_metadata).and_return(md)
          box
        end

        it "displays the latest version for that provider" do
          allow(iso_env).to receive(:boxes).and_return(collection)

          expect(I18n).to receive(:t).with(/box_outdated$/, hash_including(latest: "1.1"))

          subject.outdated_global({})
        end
      end

      context "when no versions are available for provider" do
        let(:box) do
          box_dir = test_iso_env.box3("foo", "1.0", :libvirt)
          box = Vagrant::Box.new(
            "foo", :libvirt, "1.0", box_dir, metadata_url: "foo")
          allow(box).to receive(:load_metadata).and_return(md)
          box
        end

        it "displays up to date message" do
          allow(iso_env).to receive(:boxes).and_return(collection)

          expect(I18n).to receive(:t).with(/box_up_to_date$/, hash_including(version: "1.0"))

          subject.outdated_global({})
        end
      end
    end
  end
end
