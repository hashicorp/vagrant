# encoding: UTF-8
# Copyright (c) 2015 VMware, Inc. All Rights Reserved.

require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::GuestPhoton::Cap::ConfigureNetworks" do
  let(:described_class) do
    VagrantPlugins::GuestPhoton::Plugin.components.guest_capabilities[:photon].get(:configure_networks)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  after do
    communicator.verify_expectations!
  end

  it 'should configure networks' do
    networks = [
      { :type => :static, :ip => '192.168.10.10', :netmask => '255.255.255.0', :interface => 1, :name => 'eth0' },
      { :type => :dhcp, :interface => 2, :name => 'eth1' },
      { :type => :static, :ip => '10.168.10.10', :netmask => '255.255.0.0', :interface => 3, :name => 'docker0' }
    ]
    communicator.should_receive(:sudo).with("ifconfig | grep 'eth' | cut -f1 -d' '")
    communicator.should_receive(:sudo).with('ifconfig  192.168.10.10 netmask 255.255.255.0')
    communicator.should_receive(:sudo).with('ifconfig   netmask ')
    communicator.should_receive(:sudo).with('ifconfig  10.168.10.10 netmask 255.255.0.0')

    allow_message_expectations_on_nil
    machine.should_receive(:env).at_least(5).times
    machine.env.should_receive(:active_machines).at_least(:twice)
    machine.env.active_machines.should_receive(:first)
    machine.env.should_receive(:machine)

    described_class.configure_networks(machine, networks)
  end
end
