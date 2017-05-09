require_relative "../../../../base"

require Vagrant.source_root.join("lib/vagrant/action/builtin/mixin_synced_folders")
require Vagrant.source_root.join("plugins/provisioners/chef/provisioner/chef_solo")

describe VagrantPlugins::Chef::Provisioner::ChefSolo do
  include_context "unit"

  let(:machine) { double("machine") }
  let(:config)  { double("config") }
  let(:vm)      { double("vm") }

  subject { described_class.new(machine, config) }

  before(:each) do
    allow(config).to receive(:vm).and_return(vm)

    allow(subject.class).to receive(:get_and_update_counter).and_return(1, 2, 3, 4)

    allow(subject).to receive(:expanded_folders).and_return(
                          [[:host, '/tmp/chef/cookbooks', '/tmp/vagrant-chef-1/cookbooks']],
                          [[:host, '/tmp/chef/roles', '/tmp/vagrant-chef-1/roles']],
                          [[:host, '/tmp/chef/data_bags', '/tmp/vagrant-chef-1/data_bags']],
                          [[:host, '/tmp/chef/environments', '/tmp/vagrant-chef-1/environments']]
                        )

    allow(config).to receive(:cookbooks_path).and_return('/tmp/chef/cookbooks')
    allow(config).to receive(:roles_path).and_return('/tmp/chef/roles')
    allow(config).to receive(:data_bags_path).and_return('/tmp/chef/data_bags')
    allow(config).to receive(:environments_path).and_return('/tmp/chef/environments')
    allow(config).to receive(:synced_folder_type).and_return('nfs')
  end

  describe "#share_folders" do
    it "adds shared_folders" do
      expect(subject).to receive(:synced_folders).and_return([])

      expect(vm).to receive(:synced_folder)
                      .with('/tmp/chef/cookbooks', '/tmp/vagrant-chef-1/cookbooks', {id: 'v-csc-1', type: 'nfs'})
                      .and_return(true)

      expect(vm).to receive(:synced_folder)
                      .with('/tmp/chef/roles', '/tmp/vagrant-chef-1/roles', {id: 'v-csr-2', type: 'nfs'})
                      .and_return(true)

      expect(vm).to receive(:synced_folder)
                      .with('/tmp/chef/data_bags', '/tmp/vagrant-chef-1/data_bags', {id: 'v-csdb-3', type: 'nfs'})
                      .and_return(true)

      expect(vm).to receive(:synced_folder)
                      .with('/tmp/chef/environments', '/tmp/vagrant-chef-1/environments', {id: 'v-cse-4', type: 'nfs'})
                      .and_return(true)

      subject.configure(config)
    end

    it "doesn't add duplicate shared_folders" do
      expect(subject).to receive(:synced_folders)
                          .and_return({"nfs" =>  { "/tmp/chef/cookbooks" => {guestpath: '/tmp/vagrant-chef-1/cookbooks'}}})

      expect(vm).to_not receive(:synced_folder)
                      .with('/tmp/chef/cookbooks', '/tmp/vagrant-chef-1/cookbooks', {id: 'v-csc-1', type: 'nfs'})

      expect(vm).to receive(:synced_folder)
                      .with('/tmp/chef/roles', '/tmp/vagrant-chef-1/roles', {id: 'v-csr-1', type: 'nfs'})
                      .and_return(true)

      expect(vm).to receive(:synced_folder)
                      .with('/tmp/chef/data_bags', '/tmp/vagrant-chef-1/data_bags', {id: 'v-csdb-2', type: 'nfs'})
                      .and_return(true)

      expect(vm).to receive(:synced_folder)
                      .with('/tmp/chef/environments', '/tmp/vagrant-chef-1/environments', {id: 'v-cse-3', type: 'nfs'})
                      .and_return(true)

      subject.configure(config)
    end
  end
end