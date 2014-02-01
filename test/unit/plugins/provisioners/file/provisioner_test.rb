require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/file/provisioner")

describe VagrantPlugins::FileUpload::Provisioner do
  include_context "unit"

  subject { described_class.new(machine, config) }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:config)       { double("config") }
  let(:communicator) { double("comm") }
  let(:guest)        { double("guest") }

  before do
    machine.stub(communicate: communicator)
    machine.stub(guest: guest)

    communicator.stub(execute: true)
    communicator.stub(upload: true)

    guest.stub(capability?: false)
  end

  describe "#provision" do
    it "creates the destination directory" do
      config.stub(source: "/source")
      config.stub(destination: "/foo/bar")

      expect(communicator).to receive(:execute).with("mkdir -p /foo")

      subject.provision
    end

    it "uploads the file" do
      config.stub(source: "/source")
      config.stub(destination: "/foo/bar")

      expect(communicator).to receive(:upload).with("/source", "/foo/bar")

      subject.provision
    end

    it "expands the source file path" do
      config.stub(source: "source")
      config.stub(destination: "/foo/bar")

      expect(communicator).to receive(:upload).with(
        File.expand_path("source"), "/foo/bar")

      subject.provision
    end

    it "expands the destination file path if capable" do
      config.stub(source: "/source")
      config.stub(destination: "$HOME/foo")

      expect(guest).to receive(:capability?).
        with(:shell_expand_guest_path).and_return(true)
      expect(guest).to receive(:capability).
        with(:shell_expand_guest_path, "$HOME/foo").and_return("/home/foo")

      expect(communicator).to receive(:upload).with("/source", "/home/foo")

      subject.provision
    end
  end
end
