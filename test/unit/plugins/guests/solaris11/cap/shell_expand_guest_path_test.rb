require_relative "../../../../base"

describe "VagrantPlugins::GuestSolaris11::Cap::ShellExpandGuestPath" do
  let(:caps) do
    VagrantPlugins::GuestSolaris11::Plugin
      .components
      .guest_capabilities[:solaris11]
  end

  let(:machine) { double("machine", config: double("config", solaris11: double("solaris11", suexec_cmd: 'sudo', device: 'net'))) }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  describe "#shell_expand_guest_path" do
    let(:cap) { caps.get(:shell_expand_guest_path) }

    it "expands the path" do
      path = "/export/home/vagrant/folder"
      allow(machine.communicate).to receive(:execute).
        with(any_args).and_yield(:stdout, "/export/home/vagrant/folder")

      cap.shell_expand_guest_path(machine, path)
    end

    it "expands a path with tilde" do
      path = "~/folder"
      allow(machine.communicate).to receive(:execute).
          with(any_args).and_yield(:stdout, "/export/home/vagrant/folder")

      cap.shell_expand_guest_path(machine, path)
    end

    it "raises an exception if no path was detected" do
      path = "/export/home/vagrant/folder"
      expect { cap.shell_expand_guest_path(machine, path) }.
        to raise_error(Vagrant::Errors::ShellExpandFailed)
    end

    it "returns a path with a space in it" do
      path = "/export/home/vagrant folder/folder"
      path_with_spaces = "/export/home/vagrant\\ folder/folder"
      allow(machine.communicate).to receive(:execute).
        with(any_args).and_yield(:stdout, path_with_spaces)

      expect(machine.communicate).to receive(:execute).with("echo; printf #{path_with_spaces}")
      cap.shell_expand_guest_path(machine, path)
    end
  end
end
