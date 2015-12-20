require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/omnibus")

describe VagrantPlugins::Chef::Omnibus do
  describe "#sh_command" do
    it "includes the project name" do
      command = described_class.sh_command("chef", nil, "stable")
      expect(command).to include %|-P "chef"|
    end

    it "includes the channel" do
      command = described_class.sh_command("chef", nil, "stable")
      expect(command).to include %|-c "stable"|
    end

    it "includes the version" do
      command = described_class.sh_command("chef", "1.2.3", "stable")
      expect(command).to include %|-v "1.2.3"|
    end

    it "includes the download path" do
      command = described_class.sh_command("chef", "1.2.3", "stable",
        download_path: "/some/path",
      )
      expect(command).to include %|-d "/some/path"|
    end
  end

  describe "#ps_command" do
    it "includes the project name" do
      command = described_class.ps_command("chef", nil, "stable")
      expect(command).to include %|-project 'chef'|
    end

    it "includes the channel" do
      command = described_class.ps_command("chef", nil, "stable")
      expect(command).to include %|-channel 'stable'|
    end

    it "includes the version" do
      command = described_class.ps_command("chef", "1.2.3", "stable")
      expect(command).to include %|-version '1.2.3'|
    end
  end
end
