# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

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
        described_class.nfs_client_install(machine)

        expect(communicator.received_commands[0]).to match(/apk update/)
        expect(communicator.received_commands[1]).to match(/apk add --upgrade nfs-utils/)
        expect(communicator.received_commands[2]).to match(/rc-update add rpc.statd/)
        expect(communicator.received_commands[3]).to match(/rc-service rpc.statd start/)
    end
end
