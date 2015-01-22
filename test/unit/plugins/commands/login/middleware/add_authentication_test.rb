require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/login/middleware/add_authentication")

describe VagrantPlugins::LoginCommand::AddAuthentication do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:env) { {
    env: iso_env,
  } }

  let(:iso_env) { isolated_environment.create_vagrant_env }
  let(:server_url) { "http://foo.com" }

  subject { described_class.new(app, env) }

  before do
    allow(Vagrant).to receive(:server_url).and_return(server_url)
    stub_env("ATLAS_TOKEN" => nil)
  end

  describe "#call" do
    it "does nothing if we have no server set" do
      allow(Vagrant).to receive(:server_url).and_return(nil)
      VagrantPlugins::LoginCommand::Client.new(iso_env).store_token("foo")

      original = ["foo", "#{server_url}/bar"]
      env[:box_urls] = original.dup

      subject.call(env)

      expect(env[:box_urls]).to eq(original)
    end

    it "does nothing if we aren't logged in" do
      original = ["foo", "#{server_url}/bar"]
      env[:box_urls] = original.dup

      subject.call(env)

      expect(env[:box_urls]).to eq(original)
    end

    it "appends the access token to the URL of server URLs" do
      token = "foobarbaz"
      VagrantPlugins::LoginCommand::Client.new(iso_env).store_token(token)

      original = [
        "http://google.com/box.box",
        "#{server_url}/foo.box",
        "#{server_url}/bar.box?arg=true",
      ]

      expected = original.dup
      expected[1] = "#{original[1]}?access_token=#{token}"
      expected[2] = "#{original[2]}&access_token=#{token}"

      env[:box_urls] = original.dup
      subject.call(env)

      expect(env[:box_urls]).to eq(expected)
    end

    it "appends the access token to vagrantcloud.com URLs if Atlas" do
      server_url = "https://atlas.hashicorp.com"
      allow(Vagrant).to receive(:server_url).and_return(server_url)

      token = "foobarbaz"
      VagrantPlugins::LoginCommand::Client.new(iso_env).store_token(token)

      original = [
        "http://google.com/box.box",
        "http://vagrantcloud.com/foo.box",
        "http://vagrantcloud.com/bar.box?arg=true",
      ]

      expected = original.dup
      expected[1] = "#{original[1]}?access_token=#{token}"
      expected[2] = "#{original[2]}&access_token=#{token}"

      env[:box_urls] = original.dup
      subject.call(env)

      expect(env[:box_urls]).to eq(expected)
    end
  end
end
