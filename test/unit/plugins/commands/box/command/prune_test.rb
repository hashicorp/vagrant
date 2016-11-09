require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/box/command/prune")

describe VagrantPlugins::CommandBox::Command::Prune do
  include_context "unit"
  include_context "command plugin helpers"

  let(:entry_klass) { Vagrant::MachineIndex::Entry }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    isolated_environment.tap do |env|
      env.vagrantfile("")
    end
  end

  let(:iso_vagrant_env) { iso_env.create_vagrant_env }

  let(:argv) { [] }

  # Seems this way of providing a box version triggers box in use.
  def new_entry(name, box_name, box_provider, version)
    entry_klass.new.tap do |e|
      e.name = name
      e.vagrantfile_path = "/bar"
      e.extra_data["box"] = {
          "name" => box_name,
          "provider" => box_provider,
          "version" => version,
      }
    end
  end

  subject { described_class.new(argv, iso_vagrant_env) }

  describe "execute" do
    context "with no args" do
      it "removes the old version and keeps the current one" do

        # Let's put some things in the index
        iso_env.box3("foobox", "1.0", :virtualbox);
        iso_env.box3("foobox", "1.1", :virtualbox);
        iso_env.box3("barbox", "1.0", :vmware);
        iso_env.box3("barbox", "1.1", :vmware);

        iso_vagrant_env.machine_index.set(new_entry("foo", "foobox", "virtualbox", 1))

        output = ""
        allow(iso_vagrant_env.ui).to receive(:info) do |data|
          output << data
        end
        expect(iso_vagrant_env.boxes.all.count).to eq(4)
        expect(subject.execute).to eq(0)
        expect(iso_vagrant_env.boxes.all.count).to eq(2)

        expect(output).to include("barbox (vmware, 1.1)")
        expect(output).to include("Removing box 'barbox' (v1.0) with provider 'vmware'...")
        expect(output).to include("foobox (virtualbox, 1.1)")
        expect(output).to include("Removing box 'foobox' (v1.0) with provider 'virtualbox'...")
      end

      it "removes nothing" do
        # Let's put some things in the index
        iso_env.box3("foobox", "1.0", :virtualbox);
        iso_env.box3("barbox", "1.0", :vmware);

        iso_vagrant_env.machine_index.set(new_entry("foo", "foobox", "virtualbox", 1))

        output = ""
        allow(iso_vagrant_env.ui).to receive(:info) do |data|
          output << data
        end
        expect(iso_vagrant_env.boxes.all.count).to eq(2)
        expect(subject.execute).to eq(0)
        expect(iso_vagrant_env.boxes.all.count).to eq(2)

        expect(output).to include("No old versions of boxes to remove...")

      end
    end

    context "with --provider" do
      let(:argv) { ["--provider", "virtualbox"] }

      it "removes the old versions of the specified provider" do

        # Let's put some things in the index
        iso_env.box3("foobox", "1.0", :virtualbox);
        iso_env.box3("foobox", "1.1", :virtualbox);
        iso_env.box3("barbox", "1.0", :vmware);
        iso_env.box3("barbox", "1.1", :vmware);

        iso_vagrant_env.machine_index.set(new_entry("foo", "foobox", "virtualbox", 1))

        output = ""
        allow(iso_vagrant_env.ui).to receive(:info) do |data|
          output << "\n" + data
        end

        expect(iso_vagrant_env.boxes.all.count).to eq(4)
        expect(subject.execute).to eq(0)
        expect(iso_vagrant_env.boxes.all.count).to eq(3)

        expect(output).to include("foobox (virtualbox, 1.1)")
        expect(output).to include("Removing box 'foobox' (v1.0) with provider 'virtualbox'...")

      end
    end

    context "with --dry-run" do
      let(:argv) { ["--dry-run"] }

      it "removes the old versions of the specified provider" do

        # Let's put some things in the index
        iso_env.box3("foobox", "1.0", :virtualbox);
        iso_env.box3("foobox", "1.1", :virtualbox);

        iso_vagrant_env.machine_index.set(new_entry("foo", "foobox", "virtualbox", 1))

        output = ""
        allow(iso_vagrant_env.ui).to receive(:info) do |data|
          output << "\n" + data
        end

        expect(iso_vagrant_env.boxes.all.count).to eq(2)
        expect(subject.execute).to eq(0)
        expect(iso_vagrant_env.boxes.all.count).to eq(2)


        expect(output).to include("foobox (virtualbox, 1.1)")
        expect(output).to include("Would remove foobox virtualbox 1.0")


      end
    end

    context "with --name" do
      let(:argv) { ["--name", "barbox"] }

      it "removes the old versions of the specified provider" do

        # Let's put some things in the index
        iso_env.box3("foobox", "1.0", :virtualbox);
        iso_env.box3("foobox", "1.1", :virtualbox);
        iso_env.box3("barbox", "1.0", :vmware);
        iso_env.box3("barbox", "1.1", :vmware);

        iso_vagrant_env.machine_index.set(new_entry("foo", "foobox", "virtualbox", 1))

        output = ""
        allow(iso_vagrant_env.ui).to receive(:info) do |data|
          output << "\n" + data
        end

        expect(iso_vagrant_env.boxes.all.count).to eq(4)
        expect(subject.execute).to eq(0)
        expect(iso_vagrant_env.boxes.all.count).to eq(3)

        expect(output).to include("barbox (vmware, 1.1)")
        expect(output).to include("Removing box 'barbox' (v1.0) with provider 'vmware'...")
      end
    end


    context "with --name and --provider" do
      let(:argv) { ["--name", "foobox", "--provider", "virtualbox"] }

      it "removed the old versions of that name and provider only" do
        # Let's put some things in the index
        iso_env.box3("foobox", "1.0", :virtualbox);
        iso_env.box3("foobox", "1.1", :virtualbox);
        iso_env.box3("foobox", "1.0", :vmware);
        iso_env.box3("foobox", "1.1", :vmware);
        iso_env.box3("barbox", "1.0", :vmware);
        iso_env.box3("barbox", "1.1", :vmware);

        iso_vagrant_env.machine_index.set(new_entry("foo", "foobox", "virtualbox", 1))

        output = ""
        allow(iso_vagrant_env.ui).to receive(:info) do |data|
          output << "\n" + data
        end

        expect(iso_vagrant_env.boxes.all.count).to eq(6)
        expect(subject.execute).to eq(0)
        expect(iso_vagrant_env.boxes.all.count).to eq(5)

        expect(output).to include("Removing box 'foobox' (v1.0) with provider 'virtualbox'...")
      end
    end
  end
end
