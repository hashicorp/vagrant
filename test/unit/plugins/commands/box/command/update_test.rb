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
  end

  describe "execute" do
    context "updating environment machines" do
      before do
        subject.stub(:with_target_vms) { |&block| block.call machine }
      end

      let(:box) do
        box_dir = test_iso_env.box3("foo", "1.0", :virtualbox)
        box = Vagrant::Box.new(
          "foo", :virtualbox, "1.0", box_dir, metadata_url: "foo")
        box.stub(has_update?: nil)
        box
      end

      it "ignores machines without boxes" do
        action_runner.should_receive(:run).never

        subject.execute
      end

      it "doesn't update boxes if they're up-to-date" do
        machine.stub(box: box)
        box.should_receive(:has_update?).
          with(machine.config.vm.box_version).
          and_return(nil)

        action_runner.should_receive(:run).never

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
        box.should_receive(:has_update?).
          with(machine.config.vm.box_version).
          and_return([md, md.version("1.1"), md.version("1.1").provider("virtualbox")])

        action_runner.should_receive(:run).with do |action, opts|
          expect(opts[:box_url]).to eq(box.metadata_url)
          expect(opts[:box_provider]).to eq("virtualbox")
          expect(opts[:box_version]).to eq("1.1")
          expect(opts[:ui]).to equal(machine.ui)
          true
        end

        subject.execute
      end
    end
  end
end
