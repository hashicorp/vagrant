require File.expand_path("../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/provisioners/shell/provisioner")

describe "Vagrant::Shell::Provisioner" do

  let(:machine) {
    double(:machine).tap { |machine|
      machine.stub_chain(:config, :vm, :communicator).and_return(:not_winrm)
      machine.stub_chain(:communicate, :tap) {}
    }
  }


  context "with a script that contains invalid us-ascii byte sequences" do
    let(:config) {
      double(
        :config,
        :args        => "doesn't matter",
        :upload_path => "arbitrary",
        :remote?     => false,
        :path        => nil,
        :inline      => script_that_is_incorrectly_us_ascii_encoded,
        :binary      => false,
      )
    }

    let(:script_that_is_incorrectly_us_ascii_encoded) {
      [207].pack("c*").force_encoding("US-ASCII")
    }

    it "does not raise an exception when normalizing newlines" do
      vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

      expect {
        vsp.provision
      }.not_to raise_error
    end
  end
end
