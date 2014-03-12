require Vagrant.source_root.join('plugins/provisioners/chef/provisioner/chef_zero')

describe VagrantPlugins::Chef::Provisioner::ChefZero do
  include_context 'unit'

  let(:machine) { double("machine") }
  let(:config)  { double("config") }

  subject { described_class.new(machine, config) }

  describe '#chef_binary_config' do
    let(:binary) { 'chef-solo' }
    it 'returns proper binary config' do
      config.should_receive(:binary_path).and_return(nil)
      expect(subject.chef_binary_path(binary)).to eq 'chef-client'
    end
  end
end
