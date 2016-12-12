require_relative "../../../../base"

require_relative "../../../../../../plugins/hosts/darwin/cap/rdp"

describe VagrantPlugins::HostDarwin::Cap::RDP do
  let(:rdp_info) do
    {
      host: "host",
      port: "port",
      username: "username",
    }
  end

  it "includes the default options" do
    path = described_class.generate_config_file(rdp_info)
    result = File.readlines(path).map(&:chomp)
    expect(result).to include("drivestoredirect:s:*")
    expect(result).to include("full address:s:host:port")
    expect(result).to include("prompt for credentials:i:1")
    expect(result).to include("username:s:username")
  end

  it "includes extra RDP arguments" do
    rdp_info.merge!(extra_args: ["screen mode id:i:0"])
    path = described_class.generate_config_file(rdp_info)
    result = File.readlines(path).map(&:chomp)
    expect(result).to include("screen mode id:i:0")
  end

  it "opens the RDP file" do
    env = double(:env)
    allow(described_class).to receive(:generate_config_file).and_return("/path")
    expect(Vagrant::Util::Subprocess).to receive(:execute).with("open", "/path")
    described_class.rdp_client(env, rdp_info)
  end
end
