# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe 'VagrantPlugins::GuestAlpine::Cap::RSync' do
    let(:machine) { double('machine') }
    let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

    before do
        allow(machine).to receive(:communicate).and_return(communicator)
    end

    after do
        communicator.verify_expectations!
    end

    let(:described_class) do
        VagrantPlugins::GuestAlpine::Plugin.components.guest_capabilities[:alpine].get(:rsync_install)
    end

    it 'should install rsync with --update-cache flag' do
        # communicator.should_receive(:sudo).with('apk add rsync')
        expect(communicator).to receive(:sudo).with('apk add --update-cache rsync')
        allow_message_expectations_on_nil
        described_class.rsync_install(machine)
    end

    let(:described_class) do
        VagrantPlugins::GuestAlpine::Plugin.components.guest_capabilities[:alpine].get(:rsync_installed)
    end

    it 'should verify rsync installed' do
        # communicator.should_receive(:test).with('test -f /usr/bin/rsync')
        expect(communicator).to receive(:test).with('test -f /usr/bin/rsync')
        allow_message_expectations_on_nil
        described_class.rsync_installed(machine)
    end
end
