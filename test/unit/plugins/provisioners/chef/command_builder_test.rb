require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/command_builder")

describe VagrantPlugins::Chef::CommandBuilder do

  let(:machine) { double("machine") }
  let(:chef_config) { double("chef_config") }

  before(:each) do
    allow(chef_config).to receive(:install).and_return(true)
    allow(chef_config).to receive(:version).and_return("12.0.0")
    allow(chef_config).to receive(:provisioning_path).and_return("/tmp/vagrant-chef-1")
    allow(chef_config).to receive(:arguments).and_return(nil)
    allow(chef_config).to receive(:binary_env).and_return(nil)
    allow(chef_config).to receive(:binary_path).and_return(nil)
    allow(chef_config).to receive(:binary_env).and_return(nil)
    allow(chef_config).to receive(:log_level).and_return(:info)
  end

  describe ".initialize" do
    it "raises an error when chef type is not client or solo" do
      expect { VagrantPlugins::Chef::CommandBuilder.new(:client_bad, chef_config) }.
        to raise_error(RuntimeError)
    end

    it "does not raise an error for :client" do
      expect {
        VagrantPlugins::Chef::CommandBuilder.new(:client, chef_config)
      }.to_not raise_error
    end

    it "does not raise an error for :solo" do
      expect {
        VagrantPlugins::Chef::CommandBuilder.new(:solo, chef_config)
      }.to_not raise_error
    end
  end

  describe "#command" do
    describe "windows" do
      subject do
        VagrantPlugins::Chef::CommandBuilder.new(:client, chef_config, windows: true)
      end

      it "executes the chef-client in PATH by default" do
        expect(subject.command).to match(/^chef-client/)
      end

      it "executes the chef-client using full path if binary_path is specified" do
        allow(chef_config).to receive(:binary_path).and_return(
          "c:\\opscode\\chef\\bin\\chef-client")
        expect(subject.command).to match(/^c:\\opscode\\chef\\bin\\chef-client\\chef-client/)
      end

      it "builds a guest friendly client.rb path" do
        expect(subject.command).to include(
          '--config c:\\tmp\\vagrant-chef-1\\client.rb')
      end

      it "builds a guest friendly solo.json path" do
        expect(subject.command).to include(
          '--json-attributes c:\\tmp\\vagrant-chef-1\\dna.json')
      end

      it "includes Chef arguments if specified" do
        allow(chef_config).to receive(:arguments).and_return("bacon pants")
        expect(subject.command).to include(
          " bacon pants")
      end

      it "includes --no-color if UI is not colored" do
        expect(subject.command).to include(
          " --no-color")
      end

      it "includes --force-formatter if Chef > 10" do
        expect(subject.command).to include(
          " --force-formatter")
      end

      it "does not include --force-formatter if Chef < 11" do
        allow(chef_config).to receive(:version).and_return("10.0")
        expect(subject.command).to_not include(
          " --force-formatter")
      end

      it "does not include --force-formatter if we did not install Chef" do
        allow(chef_config).to receive(:install).and_return(false)
        expect(subject.command).to_not include(
          " --force-formatter")
      end
    end

    describe "linux" do
      subject do
        VagrantPlugins::Chef::CommandBuilder.new(:client, chef_config, windows: false)
      end

      it "executes the chef-client in PATH by default" do
        expect(subject.command).to match(/^chef-client/)
      end

      it "executes the chef-client using full path if binary_path is specified" do
        allow(chef_config).to receive(:binary_path).and_return(
          "/opt/chef/chef-client")
        expect(subject.command).to match(/^\/opt\/chef\/chef-client/)
      end

      it "builds a guest friendly client.rb path" do
        expect(subject.command).to include(
          "--config /tmp/vagrant-chef-1/client.rb")
      end

      it "builds a guest friendly solo.json path" do
        expect(subject.command).to include(
          "--json-attributes /tmp/vagrant-chef-1/dna.json")
      end

      it "includes Chef arguments if specified" do
        allow(chef_config).to receive(:arguments).and_return("bacon")
        expect(subject.command).to include(
          " bacon")
      end

      it "includes --no-color if UI is not colored" do
        expect(subject.command).to include(
          " --no-color")
      end

      it "includes environment variables if specified" do
        allow(chef_config).to receive(:binary_env).and_return("ENVVAR=VAL")
        expect(subject.command).to match(/^ENVVAR=VAL /)
      end

      it "does not include --force-formatter if Chef < 11" do
        allow(chef_config).to receive(:version).and_return("10.0")
        expect(subject.command).to_not include(
          " --force-formatter")
      end

      it "does not include --force-formatter if we did not install Chef" do
        allow(chef_config).to receive(:install).and_return(false)
        expect(subject.command).to_not include(
          " --force-formatter")
      end
    end
  end
end
