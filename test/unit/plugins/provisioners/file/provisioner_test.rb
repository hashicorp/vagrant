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
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(machine).to receive(:guest).and_return(guest)

    allow(communicator).to receive(:execute).and_return(true)
    allow(communicator).to receive(:upload).and_return(true)

    allow(guest).to receive(:capability?).and_return(false)
  end

  describe "#provision" do
    it "creates the destination directory" do
      allow(config).to receive(:source).and_return("/source")
      allow(config).to receive(:destination).and_return("/foo/bar")

      expect(communicator).to receive(:execute).with("mkdir -p \"/foo\"")

      subject.provision
    end

    it "creates the destination directory with a space" do
      allow(config).to receive(:source).and_return("/source")
      allow(config).to receive(:destination).and_return("/foo bar/bar")

      expect(communicator).to receive(:execute).with("mkdir -p \"/foo bar\"")

      subject.provision
    end

    it "creates the destination directory above file" do
      allow(config).to receive(:source).and_return("/source/file.sh")
      allow(config).to receive(:destination).and_return("/foo/bar/file.sh")

      expect(communicator).to receive(:execute).with("mkdir -p \"/foo/bar\"")

      subject.provision
    end

    it "uploads the file" do
      allow(config).to receive(:source).and_return("/source")
      allow(config).to receive(:destination).and_return("/foo/bar")

      expect(communicator).to receive(:upload).with("/source", "/foo/bar")

      subject.provision
    end

    it "expands the source file path" do
      allow(config).to receive(:source).and_return("source")
      allow(config).to receive(:destination).and_return("/foo/bar")

      expect(communicator).to receive(:upload).with(
        File.expand_path("source"), "/foo/bar")

      subject.provision
    end

    it "expands the destination file path if capable" do
      allow(config).to receive(:source).and_return("/source")
      allow(config).to receive(:destination).and_return("$HOME/foo")

      expect(guest).to receive(:capability?).
        with(:shell_expand_guest_path).and_return(true)
      expect(guest).to receive(:capability).
        with(:shell_expand_guest_path, "$HOME/foo").and_return("/home/foo")

      expect(communicator).to receive(:upload).with("/source", "/home/foo")

      subject.provision
    end

    it "appends a '/.' if the destination doesnt end with a file separator" do
      allow(config).to receive(:source).and_return("/source")
      allow(config).to receive(:destination).and_return("/foo/bar")
      allow(File).to receive(:directory?).with("/source").and_return(true)

      expect(guest).to receive(:capability?).
        with(:shell_expand_guest_path).and_return(true)
      expect(guest).to receive(:capability).
        with(:shell_expand_guest_path, "/foo/bar").and_return("/foo/bar")

      expect(communicator).to receive(:upload).with("/source/.", "/foo/bar")

      subject.provision
    end

    it "sends an array of files and folders if winrm and destination doesn't end with file separator" do
      files = ["/source/file.py", "/source/folder"]
      allow(Dir).to receive(:[]).and_return(files)
      allow(config).to receive(:source).and_return("/source")
      allow(config).to receive(:destination).and_return("/foo/bar")
      allow(File).to receive(:directory?).with("/source").and_return(true)
      allow(machine.config.vm).to receive(:communicator).and_return(:winrm)

      expect(guest).to receive(:capability?).
        with(:shell_expand_guest_path).and_return(true)
      expect(guest).to receive(:capability).
        with(:shell_expand_guest_path, "/foo/bar").and_return("/foo/bar")

      expect(communicator).to receive(:upload)
        .with(files, "/foo/bar")

      subject.provision
    end
  end
end
