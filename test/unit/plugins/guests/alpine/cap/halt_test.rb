# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe 'VagrantPlugins::GuestAlpine::Cap::Halt' do
    let(:described_class) do
        VagrantPlugins::GuestAlpine::Plugin.components.guest_capabilities[:alpine].get(:halt)
    end
    let(:machine) { double('machine') }
    let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

    before do
        allow(machine).to receive(:communicate).and_return(communicator)
    end

    after do
        communicator.verify_expectations!
    end

    it 'should halt guest' do
        expect(communicator).to receive(:sudo).with('poweroff')
        allow_message_expectations_on_nil
        described_class.halt(machine)
    end
end
