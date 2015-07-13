require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/omnibus")

describe VagrantPlugins::Chef::Omnibus do
  let(:prefix) { "curl -sL #{described_class.const_get(:OMNITRUCK)}" }

  let(:version) { :latest }
  let(:prerelease) { false }
  let(:download_path) { nil }

  let(:build_command) { described_class.build_command(version, prerelease, download_path) }

  context "when prerelease is given" do
    let(:prerelease) { true }

    it "returns the correct command" do
      expect(build_command).to eq("#{prefix} | sudo bash -s -- -p")
    end
  end

  context "when download_path is given" do
    let(:download_path) { '/tmp/path/to/omnibuses' }

    it "returns the correct command" do
      expect(build_command).to eq("#{prefix} | sudo bash -s -- -d \"/tmp/path/to/omnibuses\"")
    end
  end

  context "when version is :latest" do
    let(:version) { :latest }

    it "returns the correct command" do
      expect(build_command).to eq("#{prefix} | sudo bash")
    end
  end

  context "when version is a string" do
    let(:version) { "1.2.3" }

    it "returns the correct command" do
      expect(build_command).to eq("#{prefix} | sudo bash -s -- -v \"1.2.3\"")
    end
  end

  context "when prerelease and version and download_path are given" do
    let(:version) { "1.2.3" }
    let(:prerelease) { true }
    let(:download_path) { "/some/path" }

    it "returns the correct command" do
      expect(build_command).to eq("#{prefix} | sudo bash -s -- -p -v \"1.2.3\" -d \"/some/path\"")
    end
  end
end
