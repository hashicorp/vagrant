require "pathname"
require "tmpdir"

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/box/command/update")

describe VagrantPlugins::CommandBox::Command::Update do
  include_context "unit"

  let(:argv)     { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    test_iso_env.vagrantfile("")
    test_iso_env.create_vagrant_env
  end
  let(:test_iso_env) { isolated_environment }

  let(:action_runner) { double("action_runner") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  subject { described_class.new(argv, iso_env) }

  before do
    iso_env.stub(action_runner: action_runner)
    machine.config.vm.box = "foo"
  end

  describe "execute" do
    context "updating specific box" do
      let(:argv) { ["--box", "foo"] }

      let(:metadata_url) { Pathname.new(Dir.mktmpdir).join("metadata.json") }

      before do
        metadata_url.open("w") do |f|
          f.write("")
        end

        test_iso_env.box3(
          "foo", "1.0", :virtualbox, metadata_url: metadata_url.to_s)
      end

      it "doesn't update if they're up to date" do
        called = false
        allow(action_runner).to receive(:run) do |callable, opts|
          if opts[:box_provider]
            called = true
          end

          opts
        end

        subject.execute

        expect(called).to be_false
      end

      it "does update if there is an update" do
        metadata_url.open("w") do |f|
          f.write(<<-RAW)
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
          }
        ]
      }
          RAW
        end

        action_called = false
        allow(action_runner).to receive(:run) do |action, opts|
          if opts[:box_provider]
            action_called = true
            expect(opts[:box_url]).to eq(metadata_url.to_s)
            expect(opts[:box_provider]).to eq("virtualbox")
            expect(opts[:box_version]).to eq("1.1")
          end

          opts
        end

        subject.execute

        expect(action_called).to be_true
      end

      it "raises an error if there are multiple providers" do
        test_iso_env.box3("foo", "1.0", :vmware)

        expect(action_runner).to receive(:run).never

        expect { subject.execute }.
          to raise_error(Vagrant::Errors::BoxUpdateMultiProvider)
      end

      context "with multiple providers and specifying the provider" do
        let(:argv) { ["--box", "foo", "--provider", "vmware"] }

        it "updates the proper box" do
          metadata_url.open("w") do |f|
            f.write(<<-RAW)
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
                "name": "vmware",
                "url": "bar"
              }
            ]
          }
        ]
      }
            RAW
          end

          test_iso_env.box3("foo", "1.0", :vmware)

          action_called = false
          allow(action_runner).to receive(:run) do |action, opts|
            if opts[:box_provider]
              action_called = true
              expect(opts[:box_url]).to eq(metadata_url.to_s)
              expect(opts[:box_provider]).to eq("vmware")
              expect(opts[:box_version]).to eq("1.1")
            end

            opts
          end

          subject.execute

          expect(action_called).to be_true
        end

        it "raises an error if that provider doesn't exist" do
          expect(action_runner).to receive(:run).never

          expect { subject.execute }.
            to raise_error(Vagrant::Errors::BoxNotFoundWithProvider)
        end
      end

      context "with a box that doesn't exist" do
        let(:argv) { ["--box", "nope"] }

        it "raises an exception" do
          expect(action_runner).to receive(:run).never

          expect { subject.execute }.
            to raise_error(Vagrant::Errors::BoxNotFound)
        end
      end
    end

    context "updating environment machines" do
      before do
        allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
      end

      let(:box) do
        box_dir = test_iso_env.box3("foo", "1.0", :virtualbox)
        box = Vagrant::Box.new(
          "foo", :virtualbox, "1.0", box_dir, metadata_url: "foo")
        box.stub(has_update?: nil)
        box
      end

      it "ignores machines without boxes" do
        expect(action_runner).to receive(:run).never

        subject.execute
      end

      it "doesn't update boxes if they're up-to-date" do
        machine.stub(box: box)
        expect(box).to receive(:has_update?).
          with(machine.config.vm.box_version).
          and_return(nil)

        expect(action_runner).to receive(:run).never

        subject.execute
      end

      it "updates boxes if they have an update" do
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
          }
        ]
      }
        RAW

        machine.stub(box: box)
        expect(box).to receive(:has_update?).
          with(machine.config.vm.box_version).
          and_return([md, md.version("1.1"), md.version("1.1").provider("virtualbox")])

        expect(action_runner).to receive(:run).with { |action, opts|
          expect(opts[:box_url]).to eq(box.metadata_url)
          expect(opts[:box_provider]).to eq("virtualbox")
          expect(opts[:box_version]).to eq("1.1")
          expect(opts[:ui]).to equal(machine.ui)
          true
        }

        subject.execute
      end
    end
  end
end
