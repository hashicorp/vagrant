# encoding: UTF-8
# Copyright (c) 2015 VMware, Inc. All Rights Reserved.

require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::GuestPhoton::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestPhoton::Plugin.components.guest_capabilities[:photon].get(:change_host_name)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  after do
    communicator.verify_expectations!
  end

  it 'should change hostname when hostname is differ from current' do
    hostname = 'vagrant-photon'
    expect(communicator).to receive(:test).with("sudo hostname --fqdn | grep 'vagrant-photon'")
    communicator.should_receive(:sudo).with("hostname #{hostname.split('.')[0]}")
    described_class.change_host_name(machine, hostname)
  end

  it 'should not change hostname when hostname equals current' do
    hostname = 'vagrant-photon'
    communicator.stub(:test).and_return(true)
    communicator.should_not_receive(:sudo)
    described_class.change_host_name(machine, hostname)
  end
end
