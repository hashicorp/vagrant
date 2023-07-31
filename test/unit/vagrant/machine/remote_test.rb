# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

describe Vagrant::Machine::Remote do
  include_context "unit"

  let(:klass) { Class.new(Vagrant::Machine).tap { |c| c.prepend(described_class) }}

  # == Machine Setup
  #
  # This setup is all copied from Vagrant::Machine unit tests - the only
  # difference is the above klass is used so we can prepend the remote stuff

  let(:name)     { "foo" }
  let(:ui) { double(:ui) }
  let(:provider) { new_provider_mock }
  let(:provider_cls) do
    obj = double("provider_cls")
    allow(obj).to receive(:new).with(anything(), anything()) {}.and_return(provider)
    obj
  end
  let(:provider_config) { Object.new }
  let(:provider_name) { :dummy }
  let(:provider_options) { {} }
  let(:base)     { false }
  let(:box) do
    double("box").tap do |b|
      allow(b).to receive(:name).and_return("foo")
      allow(b).to receive(:provider).and_return(:dummy)
      allow(b).to receive(:version).and_return("1.0")
    end
  end
  let(:config) do
    double("config").tap do |c|
      allow(c).to receive(:trigger).and_return( double(:trigger) )
    end
  end
  let(:vagrantfile) do
    double("vagrantfile").tap do |v|
      allow(v).to receive(:config).and_return( config )
    end
  end

  let(:config)   { env.vagrantfile.config }
  let(:data_dir) { Pathname.new(Dir.mktmpdir("vagrant-machine-data-dir")) }
  let(:env)      do
    # We need to create a Vagrantfile so that this test environment
    # has a proper root path
    test_env.vagrantfile("""
      Vagrant.configure('2') do |config|
        config.vm.define 'foo' do |c|
          c.vm.box = 'foo'
        end
      end
""")

    # Create the Vagrant::Environment instance
    test_env.create_vagrant_env
  end

  let(:test_env) { isolated_environment }

  let(:instance) { new_instance }

  after do
    FileUtils.rm_rf(data_dir) if data_dir
  end

  subject { instance }

  def new_provider_mock
    double("provider").tap do |obj|
      allow(obj).to receive(:_initialize)
        .with(provider_name, anything).and_return(nil)
      allow(obj).to receive(:machine_id_changed).and_return(nil)
      allow(obj).to receive(:state).and_return(Vagrant::MachineState.new(
        :created, "", ""))
    end
  end

  # Returns a new instance with the test data
  def new_instance
    klass.new(name, provider_name, provider_cls, provider_config,
                        provider_options, config, data_dir, box,
                        env, env.vagrantfile, base, client: client)
  end

  # == Machine::Remote Setup
  #
  # Now we do the setup that's specific to the remote module.
  let(:client) { double(:client) }


  before do
    allow(env).to receive(:ui).and_return(ui)
    allow(env).to receive(:get_target) { client }
    allow(client).to receive(:box) { box }
    allow(client).to receive(:data_dir) { data_dir }
    allow(client).to receive(:name) { name }
    allow(client).to receive(:provider_name) { provider_name }
    allow(client).to receive(:provider) { nil }
    allow(client).to receive(:environment) { env }
    allow(client).to receive(:vagrantfile) { vagrantfile }
    allow(ui).to receive(:machine)

    allow(Vagrant.plugin("2").remote_manager).to receive(:providers) { {provider_name => provider_cls} }
  end

  describe "#synced_folders" do
    it "gets the synced_folders from the client" do
      expect(client).to receive(:synced_folders) { [] }
      subject.synced_folders
    end

    it "returns a hash with synced_folders returned from the client" do
      synced_folder_clients = [
        {
          plugin: double("plugin", name: "syncedfoldertype"),
          folder: {
            disabled: false,
            source: "/some/source",
            destination: "/some/destination",
          }
        }
      ]
      allow(client).to receive(:synced_folders) { synced_folder_clients }

      output = subject.synced_folders

      expect(output).to match(
        syncedfoldertype: a_hash_including(
          "/some/destination" => a_hash_including(
            disabled: false,
            guestpath: "/some/destination",
            hostpath: "/some/source",
            plugin: an_instance_of(Vagrant::Plugin::Remote::SyncedFolder),
          )
        )
      )
    end

    it "works with multiple folders for a given impl" do
      synced_folder_clients = [
        {
          plugin: double("pluginone", name: "syncedfoldertype"),
          folder: {
            disabled: false,
            source: "/one",
            destination: "/first",
          }
        },
        {
          plugin: double("plugintwo", name: "syncedfoldertype"),
          folder: {
            disabled: false,
            source: "/two",
            destination: "/second",
          }
        },
      ]
      allow(client).to receive(:synced_folders) { synced_folder_clients }

      output = subject.synced_folders

      expect(output).to match(
        syncedfoldertype: a_hash_including(
          "/first" => a_hash_including(
            disabled: false,
            guestpath: "/first",
            hostpath: "/one",
            plugin: an_instance_of(Vagrant::Plugin::Remote::SyncedFolder),
          ),
          "/second" => a_hash_including(
            disabled: false,
            guestpath: "/second",
            hostpath: "/two",
            plugin: an_instance_of(Vagrant::Plugin::Remote::SyncedFolder),
          ),
        )
      )
    end

    it "skips disabled folders" do
      synced_folder_clients = [
        {
          plugin: double("pluginone"),
          folder: {
            disabled: true,
            source: "/notme",
            destination: "/noway",
          }
        },
        {
          plugin: double("plugintwo", name: "syncedfoldertype"),
          folder: {
            disabled: false,
            source: "/yesme",
            destination: "/pickme",
          }
        },
      ]
      allow(client).to receive(:synced_folders) { synced_folder_clients }

      output = subject.synced_folders

      expect(output).to match(
        syncedfoldertype: a_hash_including(
          "/pickme" => a_hash_including(
            disabled: false,
            guestpath: "/pickme",
            hostpath: "/yesme",
            plugin: an_instance_of(Vagrant::Plugin::Remote::SyncedFolder),
          ),
        )
      )
      expect(output[:syncedfoldertype]).to_not have_key("/noway")
    end

    it "honors explicitly set folder type" do
      synced_folder_clients = [
        {
          plugin: double("pluginone"),
          folder: {
            disabled: false,
            source: "/imspecial",
            destination: "/ihaveatype",
            type: "specialtype",
          }
        },
        {
          plugin: double("plugintwo", name: "syncedfoldertype"),
          folder: {
            disabled: false,
            source: "/imnormal",
            destination: "/iamdefaulttype",
          }
        },
      ]
      allow(client).to receive(:synced_folders) { synced_folder_clients }

      output = subject.synced_folders

      expect(output).to match(
        syncedfoldertype: a_hash_including(
          "/iamdefaulttype" => a_hash_including(
            disabled: false,
            guestpath: "/iamdefaulttype",
            hostpath: "/imnormal",
            plugin: an_instance_of(Vagrant::Plugin::Remote::SyncedFolder),
          ),
        ),
        specialtype: a_hash_including(
          "/ihaveatype" => a_hash_including(
            disabled: false,
            guestpath: "/ihaveatype",
            hostpath: "/imspecial",
            plugin: an_instance_of(Vagrant::Plugin::Remote::SyncedFolder),
          ),
        )
      )
    end
  end
end
