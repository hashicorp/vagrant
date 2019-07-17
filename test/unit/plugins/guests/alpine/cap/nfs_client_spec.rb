
require 'spec_helper'

describe 'VagrantPlugins::GuestAlpine::Cap::NFSClient' do
    let(:described_class) do
        VagrantPlugins::GuestAlpine::Plugin.components.guest_capabilities[:alpine].get(:nfs_client_install)
    end

    let(:machine) { double('machine') }
    let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

    before do
        allow(machine).to receive(:communicate).and_return(communicator)
    end

    after do
        communicator.verify_expectations!
    end

    it 'should install nfs client' do
        x = <<-EOS.gsub(/^\s+\|\s?/, '')
            | # work around defunct repository in configuration
            | # box: maier/apline-3.3
            | repo_file="/etc/apk/repositories"
            | if [ $(grep -c "repos.dfw.lax-noc.com" $repo_file) -ne 0 ]; then
            |     repo_file_bak="${repo_file}.orig"
            |     echo "updating repositories"
            |     cp $repo_file $repo_file_bak
            |     sed -e 's/repos.dfw.lax-noc.com/dl-cdn.alpinelinux.org/' $repo_file_bak > $repo_file
            | fi
            |
            | echo "updating repository indices"
            | apk update
            | if [ $? -ne 0 ]; then
            |     exit 1
            | fi
            |
            | echo "installing nfs-utils"
            | apk add --upgrade nfs-utils
            | if [ $? -ne 0 ]; then
            |     exit 1
            | fi
            |
            | echo "installing rpc.statd"
            | rc-update add rpc.statd
            | if [ $? -ne 0 ]; then
            |     exit 1
            | fi
            |
            | echo "starting rpc.statd service"
            | rc-service rpc.statd start
            | if [ $? -ne 0 ]; then
            |     exit 1
            | fi
        EOS
        expect(communicator).to receive(:sudo).with(x)
        allow_message_expectations_on_nil
        described_class.nfs_client_install(machine)
    end
end
