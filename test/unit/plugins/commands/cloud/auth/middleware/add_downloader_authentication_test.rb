# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/auth/middleware/add_downloader_authentication")
require "vagrant/util/downloader"

describe VagrantPlugins::CloudCommand::AddDownloaderAuthentication do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:ui) { Vagrant::UI::Silent.new }
  let(:env) { {
    env: iso_env,
    ui: ui
  } }

  let(:iso_env) { isolated_environment.create_vagrant_env }
  let(:server_url) { "http://vagrantcloud.com/box.box" }
  let(:dwnloader) { Vagrant::Util::Downloader.new(server_url, "/some/path", {}) }

  subject { described_class.new(app, env) }

  before do
    allow(Vagrant).to receive(:server_url).and_return(server_url)
    stub_env("ATLAS_TOKEN" => nil)
    stub_env("VAGRANT_SERVER_ACCESS_TOKEN_BY_URL" => nil)
  end

  describe "#call" do
    context "non full paths" do
      let(:server_url) { "http://vagrantcloud.com" }
      let(:dwnloader) { Vagrant::Util::Downloader.new(server_url, "/some/path", {}) }

      it "does nothing if we have no server set" do
        allow(Vagrant).to receive(:server_url).and_return(nil)
        VagrantPlugins::CloudCommand::Client.new(iso_env).store_token("fooboohoo")

        env[:downloader] = dwnloader
        subject.call(env)
        expect(env[:downloader].headers.empty?).to eq(true)
      end

      it "does nothing if we aren't logged in" do
        env[:downloader] = dwnloader
        subject.call(env)
        expect(env[:downloader].headers.empty?).to eq(true)
      end
    end

    context "custom server" do
      let(:server_url) { "http://surprise.com/box.box" }
      let(:dwnloader) { Vagrant::Util::Downloader.new(server_url, "/some/path", {}) }

      it "warns when adding token to custom server" do
        server_url = "https://surprise.com"
        allow(Vagrant).to receive(:server_url).and_return(server_url)

        token = "foobarbaz"
        VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)

        expect(subject).to receive(:sleep).once
        expect(ui).to receive(:warn).once.and_call_original

        env[:downloader] = dwnloader
        subject.call(env)

        expect(env[:downloader].headers).to eq(["Authorization: Bearer #{token}"])
      end
    end

    context "replacement hosts" do
      let(:dwnloader) { Vagrant::Util::Downloader.new("https://app.vagrantup.com", "/some/path", {}) }

      it "modifies host URL to target if authorized host" do
        token = "foobarbaz"
        VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)
        env[:downloader] = dwnloader
        subject.call(env)
        expect(env[:downloader].headers).to eq(["Authorization: Bearer #{token}"])
        expect(URI.parse(env[:downloader].source).host).to eq(VagrantPlugins::CloudCommand::AddDownloaderAuthentication::TARGET_HOST)
      end
    end

    context "malformed url" do
      let(:bad_url) { "this is not a valid url" }
      let(:dwnloader) { Vagrant::Util::Downloader.new(bad_url, "/some/path", {}) }

      it "ignores urls that it cannot parse" do
        # Ensure the bad URL does cause an exception
        expect{ URI.parse(bad_url) }.to raise_error URI::Error
        env[:downloader] = dwnloader
        subject.call(env)
        expect(env[:downloader].source).to eq(bad_url)
      end
    end

    context "with an headers already added" do
      let(:auth_header) { "Authorization Bearer: token" }
      let(:other_header) {"some: thing"}
      let(:dwnloader) { Vagrant::Util::Downloader.new(server_url, "/some/path", {headers: [other_header]}) }

      it "appends the auth header" do
        token = "foobarbaz"
        VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)

        env[:downloader] = dwnloader
        subject.call(env)

        expect(env[:downloader].headers).to eq([other_header, "Authorization: Bearer #{token}"])
      end

      context "with local file path" do
        let(:file_path) { "file:////path/to/box.box" }
        let(:dwnloader) { Vagrant::Util::Downloader.new(file_path, "/some/path", {}) }

        it "returns original urls when not modified" do
          env[:downloader] = dwnloader
          subject.call(env)

          expect(env[:downloader].source).to eq(file_path)
          expect(env[:downloader].headers.empty?).to eq(true)
        end
      end

      it "does not append multiple access_tokens" do
        dwnloader.headers << auth_header
        token = "foobarbaz"
        VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)

        env[:downloader] = dwnloader
        subject.call(env)

        expect(env[:downloader].headers).to eq([other_header, auth_header])
      end
    end

    it "adds a token to the headers" do
      token = "foobarbaz"
      VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)
      env[:downloader] = dwnloader
      subject.call(env)
      expect(env[:downloader].headers).to eq(["Authorization: Bearer #{token}"])
    end

    it "does not append the access token to vagrantcloud.com URLs if Atlas" do
      server_url = "https://atlas.hashicorp.com"
      allow(Vagrant).to receive(:server_url).and_return(server_url)
      allow(subject).to receive(:sleep)
      token = "foobarbaz"
      VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)
      env[:downloader] = dwnloader
      subject.call(env)
      expect(env[:downloader].headers.empty?).to eq(true)
    end

    context "with VAGRANT_SERVER_ACCESS_TOKEN_BY_URL environment variable set" do
      before do
        stub_env("VAGRANT_SERVER_ACCESS_TOKEN_BY_URL" => "1")
      end

      it "does not add a token to the headers" do
        token = "foobarbaz"
        VagrantPlugins::CloudCommand::Client.new(iso_env).store_token(token)
        env[:downloader] = dwnloader
        subject.call(env)
        expect(env[:downloader].headers).to eq([])
      end
    end
  end
end
