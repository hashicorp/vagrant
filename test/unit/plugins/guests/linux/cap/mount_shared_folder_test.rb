require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::GuestLinux::Cap::MountSharedFolder" do
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:guest) { double("guest") }

  before do
    allow(machine).to receive(:guest).and_return(guest)
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(guest).to receive(:capability).and_return(nil)
  end

  describe "smb" do
    let(:described_class) do
      VagrantPlugins::GuestLinux::Plugin.components.guest_capabilities[:linux].get(:mount_smb_shared_folder)
    end

    describe ".mount_shared_folder" do
      describe "with a domain" do
        let(:mount_command) { "mount -t cifs -o uid=`id -u `,gid=`getent group  | cut -d: -f3`,sec=ntlm,username=user,password=pass,domain=domain //host/name " }
        before do
          communicator.expect_command mount_command
          communicator.stub_command mount_command, exit_code: 0
        end
        after { communicator.verify_expectations! }
        it "should call mount with correct args" do
          described_class.mount_smb_shared_folder(machine, 'name', 'guestpath', {:smb_username => "user@domain", :smb_password => "pass", :smb_host => "host"})
        end
      end
      describe "without a domain" do
        let(:mount_command) { "mount -t cifs -o uid=`id -u `,gid=`getent group  | cut -d: -f3`,sec=ntlm,username=user,password=pass //host/name " }
        before do
          communicator.expect_command mount_command
          communicator.stub_command mount_command, exit_code: 0
        end
        after { communicator.verify_expectations! }
        it "should call mount with correct args" do
          described_class.mount_smb_shared_folder(machine, 'name', 'guestpath', {:smb_username => "user", :smb_password => "pass", :smb_host => "host"})
        end
      end
    end
  end
end
