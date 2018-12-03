require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/publish")

describe VagrantPlugins::CloudCommand::Command::Publish do
  include_context "unit"

  let(:argv)     { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:client) { double("client", token: "1234token1234") }

  subject { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }
  let(:box_path) { "path/to/the/virtualbox.box" }

  let(:box) { double("box", create: true, read: {}) }
  let(:version) { double("version", create_version: true, release: true) }
  let(:provider) { double("provider", create_provider: true, upload_file: true) }
  let(:uploader) { double("uploader") }

  before do
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
    allow(VagrantPlugins::CloudCommand::Util).to receive(:client_login).
      and_return(client)
    allow(VagrantPlugins::CloudCommand::Util).to receive(:format_box_results).
      and_return(true)
    allow(iso_env.ui).to receive(:ask).
      and_return("y")
    allow(VagrantCloud::Box).to receive(:new).and_return(box)
    allow(VagrantCloud::Version).to receive(:new).and_return(version)
    allow(VagrantCloud::Provider).to receive(:new).and_return(provider)

    allow(File).to receive(:absolute_path).and_return("/full/#{box_path}")
    allow(File).to receive(:file?).and_return(true)
  end

  context "with no arguments" do
    it "shows help" do
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::CLIInvalidUsage)
    end
  end

  context "missing required arguments" do
    let(:argv) { ["vagrant/box", "1.0.0", "virtualbox"] }

    it "shows help" do
      allow(File).to receive(:file?).and_return(false)
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::BoxFileNotExist)
    end
  end

  context "with arguments" do
    let(:argv) { ["vagrant/box", "1.0.0", "virtualbox", box_path] }

    it "publishes a box given options" do
      allow(provider).to receive(:upload_url).and_return("http://upload.here/there")
      allow(Vagrant::Util::Uploader).to receive(:new).
        with("http://upload.here/there", "/full/path/to/the/virtualbox.box", {ui: anything}).
        and_return(uploader)
      allow(uploader).to receive(:upload!)
      expect(VagrantPlugins::CloudCommand::Util).to receive(:format_box_results)
      expect(subject.execute).to eq(0)
    end

    it "catches a ClientError if something goes wrong" do
      allow(provider).to receive(:upload_url).and_return("http://upload.here/there")
      allow(Vagrant::Util::Uploader).to receive(:new).
        with("http://upload.here/there", "/full/path/to/the/virtualbox.box", {ui: anything}).
        and_return(uploader)
      allow(uploader).to receive(:upload!)
      allow(box).to receive(:create).
        and_raise(VagrantCloud::ClientError.new("Fail Message", "Message", 404))
      expect(subject.execute).to eq(1)
    end

    it "calls update if entity already exists" do
      allow(provider).to receive(:upload_url).and_return("http://upload.here/there")
      allow(Vagrant::Util::Uploader).to receive(:new).
        with("http://upload.here/there", "/full/path/to/the/virtualbox.box", {ui: anything}).
        and_return(uploader)
      allow(uploader).to receive(:upload!)
      allow(box).to receive(:create).
        and_raise(VagrantCloud::ClientError.new("Fail Message", "Message", 422))
      expect(box).to receive(:update)
      expect(subject.execute).to eq(0)
    end
  end

  context "with arguments and releasing a box" do
    let(:argv) { ["vagrant/box", "1.0.0", "virtualbox", box_path, "--release"] }

    it "releases the box" do
      allow(provider).to receive(:upload_url).and_return("http://upload.here/there")
      allow(Vagrant::Util::Uploader).to receive(:new).
        with("http://upload.here/there", "/full/path/to/the/virtualbox.box", {ui: anything}).
        and_return(uploader)
      allow(uploader).to receive(:upload!)
      expect(VagrantPlugins::CloudCommand::Util).to receive(:format_box_results)
      expect(version).to receive(:release)
      expect(subject.execute).to eq(0)
    end
  end

  context "with arguments and a remote url" do
    let(:argv) { ["vagrant/box", "1.0.0", "virtualbox", "--url", "https://www.boxes.com/path/to/the/virtualbox.box"] }

    it "does not upload a file" do
      expect(VagrantPlugins::CloudCommand::Util).to receive(:format_box_results)
      expect(subject.execute).to eq(0)
      expect(provider).not_to receive(:upload_file)
    end
  end
end
