require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/command_builder_windows")

describe VagrantPlugins::Chef::CommandBuilderWindows do

  let(:machine) { double("machine") }
  let(:chef_config) { double("chef_config") }

  subject do
    VagrantPlugins::Chef::CommandBuilderWindows.new(machine, chef_config, :client)
  end

  before(:each) do
    allow(chef_config).to receive(:provisioning_path).and_return('/tmp/vagrant-chef-1')
    allow(chef_config).to receive(:arguments).and_return(nil)
    allow(chef_config).to receive(:binary_env).and_return(nil)
    allow(chef_config).to receive(:binary_path).and_return(nil)
  end

  describe '.initialize' do
    it 'should raise when chef type is not client or solo' do
      expect { VagrantPlugins::Chef::CommandBuilderWindows.new(machine, chef_config, :client_bad) }.
        to raise_error
    end
  end

  describe '.build_command' do
    it "executes the chef-client in PATH by default" do
      expect(subject.build_command()).to match(/^chef-client/)
    end

    it "executes the chef-client using full path if binary_path is specified" do
      allow(chef_config).to receive(:binary_path).and_return(
        "c:\\opscode\\chef\\bin\\chef-client")
      expect(subject.build_command()).to match(/^c:\\opscode\\chef\\bin\\chef-client\\chef-client/)
    end

    it "builds a windows friendly client.rb path" do
      expect(subject.build_command()).to include(
        '-c c:\\tmp\\vagrant-chef-1\\client.rb')
    end

    it "builds a windows friendly solo.json path" do
      expect(subject.build_command()).to include(
        '-j c:\\tmp\\vagrant-chef-1\\dna.json')
    end

    it 'includes Chef arguments if specified' do
      allow(chef_config).to receive(:arguments).and_return("-l DEBUG")
      expect(subject.build_command()).to include(
        '-l DEBUG')
    end
  end
end
