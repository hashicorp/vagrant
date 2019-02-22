require File.expand_path("../../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/auth/middleware/add_authentication")

describe VagrantPlugins::CloudCommand::AddAuthentication do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:ui) { double("ui") }
  let(:env) { {
    env: iso_env,
    ui: ui
  } }

  let(:iso_env) { isolated_environment.create_vagrant_env }
  let(:server_url) { "http://vagrantcloud.com" }

  subject { described_class.new(app, env) }

  before do
    allow(Vagrant).to receive(:server_url).and_return(server_url)
    allow(ui).to receive(:warn)
    stub_env("ATLAS_TOKEN" => nil)
  end

  describe "#call" do
    it "does nothing if we have no server set" do
      allow(Vagrant).to receive(:server_url).and_return(nil)
      VagrantPlugins::CloudCommand::Client.new(iso_env).store_token("foo")

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
      VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)

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

    it "does not append the access token to vagrantcloud.com URLs if Atlas" do
      server_url = "https://atlas.hashicorp.com"
      allow(Vagrant).to receive(:server_url).and_return(server_url)
      allow(subject).to receive(:sleep)

      token = "foobarbaz"
      VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)

      original = [
        "http://google.com/box.box",
        "http://vagrantcloud.com/foo.box",
        "http://vagrantcloud.com/bar.box?arg=true",
      ]

      expected = original.dup

      env[:box_urls] = original.dup
      subject.call(env)

      expect(env[:box_urls]).to eq(expected)
    end

    it "warns when adding token to custom server" do
      server_url = "https://example.com"
      allow(Vagrant).to receive(:server_url).and_return(server_url)

      token = "foobarbaz"
      VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)

      original = [
        "http://google.com/box.box",
        "http://vagrantcloud.com/foo.box",
        "http://example.com/bar.box",
        "http://example.com/foo.box"
      ]

      expected = original.dup
      expected[2] = expected[2] + "?access_token=#{token}"
      expected[3] = expected[3] + "?access_token=#{token}"

      expect(subject).to receive(:sleep).once
      expect(ui).to receive(:warn).once

      env[:box_urls] = original.dup
      subject.call(env)

      expect(env[:box_urls]).to eq(expected)
    end

    it "modifies host URL to target if authorized host" do
      originals = VagrantPlugins::CloudCommand::AddAuthentication::
        REPLACEMENT_HOSTS.map{ |h| "http://#{h}/box.box" }
      expected = "http://#{VagrantPlugins::CloudCommand::AddAuthentication::TARGET_HOST}/box.box"
      env[:box_urls] = originals
      subject.call(env)
      env[:box_urls].each do |url|
        expect(url).to eq(expected)
      end
    end

    it "ignores urls that it cannot parse" do
      bad_url = "this is not a valid url"
      # Ensure the bad URL does cause an exception
      expect{ URI.parse(bad_url) }.to raise_error URI::Error
      env[:box_urls] = [bad_url]
      subject.call(env)
      expect(env[:box_urls].first).to eq(bad_url)
    end

    it "returns original urls when not modified" do
      to_persist = "file:////path/to/box.box"
      to_change = VagrantPlugins::CloudCommand::AddAuthentication::
        REPLACEMENT_HOSTS.map{ |h| "http://#{h}/box.box" }.first
      expected = "http://#{VagrantPlugins::CloudCommand::AddAuthentication::TARGET_HOST}/box.box"
      env[:box_urls] = [to_persist, to_change]
      subject.call(env)
      check_persist, check_change = env[:box_urls]
      expect(check_change).to eq(expected)
      expect(check_persist).to eq(to_persist)
      # NOTE: The behavior of URI.parse changes on Ruby 2.5 to produce
      # the same string value. To make the test worthwhile in checking
      # for the same value, check that the object IDs are still the same.
      expect(check_persist.object_id).to eq(to_persist.object_id)
    end

    it "does not append multiple access_tokens" do
      token = "foobarbaz"
      VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)

      original = [
        "#{server_url}/foo.box?access_token=existing",
        "#{server_url}/bar.box?arg=true",
      ]

      env[:box_urls] = original.dup
      subject.call(env)

      expect(env[:box_urls][0]).to eq("#{server_url}/foo.box?access_token=existing")
      expect(env[:box_urls][1]).to eq("#{server_url}/bar.box?arg=true&access_token=foobarbaz")
    end
  end
end
