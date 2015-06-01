# encoding: UTF-8
# Copyright (c) 2015 VMware, Inc. All Rights Reserved.

require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::GuestPhoton::Cap::Docker" do
  let(:described_class) do
    VagrantPlugins::GuestPhoton::Plugin.components.guest_capabilities[:photon].get(:docker_daemon_running)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:old_hostname) { 'oldhostname.olddomain.tld' }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  after do
    communicator.verify_expectations!
  end

  it 'should check docker' do
    expect(communicator).to receive(:test).with('test -S /run/docker.sock')
    described_class.docker_daemon_running(machine)
  end
end
