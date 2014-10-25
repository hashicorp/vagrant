require_relative '../../../../base'

require Vagrant.source_root.join('plugins/provisioners/chef/config/chef_zero')

describe VagrantPlugins::Chef::Config::ChefZero do
  include_context 'unit'

  subject { described_class.new }

  before do
    subject.finalize!
  end

  describe '#binary' do
    it 'should be true' do
      expect(subject.local_mode).to eq true
    end
  end
end
