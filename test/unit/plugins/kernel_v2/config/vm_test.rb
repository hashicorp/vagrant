require File.expand_path("../../../../base", __FILE__)
require File.expand_path("../../../../../../plugins/kernel_v2/config/vm", __FILE__)

describe VagrantPlugins::Kernel_V2::VMConfig do
  let(:instance) { described_class.new }
  describe '.synced_folder' do
    let(:hostpath) { 'hostpath' }
    let(:guestpath) { 'guestpath' }
    let(:options) { nil }
    subject { instance.synced_folder(hostpath, guestpath, options ) }

    it { should eq({guestpath: guestpath, hostpath: hostpath}) }

    context 'when passed {nfs: true} as options' do
      let(:options) { {nfs: true} }

      context 'when on windows' do
        before { Vagrant::Util::Platform.stub(:windows?) { true } }
        it { should eq({guestpath: guestpath, hostpath: hostpath, nfs: false}) }
      end

      context 'when not on windows' do
        before { Vagrant::Util::Platform.stub(:windows?) { false } }
        it { should eq({guestpath: guestpath, hostpath: hostpath, nfs: true}) }
      end
    end
  end
end
