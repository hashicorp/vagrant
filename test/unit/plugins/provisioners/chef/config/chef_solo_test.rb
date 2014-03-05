require_relative '../../../../base'

require Vagrant.source_root.join('plugins/provisioners/chef/config/chef_solo')

describe VagrantPlugins::Chef::Config::ChefSolo do
  include_context 'unit'

  subject { described_class.new }

  before do
    subject.finalize!
  end

  describe '#local_mode' do
    it 'should be false' do
      expect(subject.local_mode).to eq false
    end
  end
end
