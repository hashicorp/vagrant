require_relative "../../../base"
require "fake_ftp"

require Vagrant.source_root.join("plugins/pushes/ftp/adapter")

describe VagrantPlugins::FTPPush::Adapter do
  include_context "unit"

  subject do
    described_class.new("127.0.0.1:2345", "sethvargo", "bacon",
      foo: "bar",
    )
  end

  describe "#initialize" do
    it "sets the instance variables" do
      expect(subject.host).to eq("127.0.0.1")
      expect(subject.port).to eq(2345)
      expect(subject.username).to eq("sethvargo")
      expect(subject.password).to eq("bacon")
      expect(subject.options).to eq(foo: "bar")
      expect(subject.server).to be(nil)
    end
  end

  describe "#parse_host" do
    it "has a default value" do
      allow(subject).to receive(:default_port)
        .and_return(5555)

      result = subject.parse_host("127.0.0.1")
      expect(result[0]).to eq("127.0.0.1")
      expect(result[1]).to eq(5555)
    end
  end
end

describe VagrantPlugins::FTPPush::FTPAdapter do
  include_context "unit"

  before(:all) do
    @server = FakeFtp::Server.new(21212, 21213)
    @server.start
  end

  after(:all) { @server.stop }

  let(:server) { @server }

  before { server.reset }

  subject do
    described_class.new("127.0.0.1:#{server.port}", "sethvargo", "bacon")
  end

  describe "#default_port" do
    it "is 21" do
      expect(subject.default_port).to eq(21)
    end
  end

  describe "#upload" do
    before do
      @dir = Dir.mktmpdir
      FileUtils.touch("#{@dir}/file")
    end

    after do
      FileUtils.rm_rf(@dir)
    end

    it "uploads the file" do
      subject.connect do |ftp|
        ftp.upload("#{@dir}/file", "/file")
      end

      expect(server.files).to include("file")
    end

    it "uploads in passive mode" do
      subject.options[:passive] = true
      subject.connect do |ftp|
        ftp.upload("#{@dir}/file", "/file")
      end

      expect(server.file("file")).to be_passive
    end
  end
end

describe VagrantPlugins::FTPPush::SFTPAdapter do
  include_context "unit"

  subject do
    described_class.new("127.0.0.1:2345", "sethvargo", "bacon",
      foo: "bar",
    )
  end

  describe "#default_port" do
    it "is 22" do
      expect(subject.default_port).to eq(22)
    end
  end

  describe "#upload" do
    it "uploads the file" do
      pending "a way to mock an SFTP server"
    end
  end
end
