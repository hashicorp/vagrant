# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/auth/middleware/add_authentication")

describe VagrantPlugins::CloudCommand::AddAuthentication do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:ui) { Vagrant::UI::Silent.new }
  let(:env) { {
    env: iso_env,
    ui: ui
  } }

  let(:iso_env) { isolated_environment.create_vagrant_env }
  let(:server_url) { "http://vagrantcloud.com" }
  let(:client) { double("client", token: token) }
  let(:token) { "TEST_TOKEN" }

  subject { described_class.new(app, env) }

  before do
    allow(Vagrant).to receive(:server_url).and_return(server_url)
    allow(VagrantPlugins::CloudCommand::Client).to receive(:new).
      with(iso_env).and_return(client)
    stub_env("ATLAS_TOKEN" => nil)
  end

  describe "#call" do
    it "does nothing if we have no server set" do
      allow(Vagrant).to receive(:server_url).and_return(nil)

      original = [token, "#{server_url}/bar"]
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

    context "when urls are set" do
      it "does not modify urls" do
        original = ["https://example.com/boxes/test.box",
          "file://C:/my/box/path/local.box"]
        env[:box_urls] = original.dup
        subject.call(env)
        expect(env[:box_urls]).to eq(original)
      end

      it "should remove access_token parameters when found" do
        env[:box_urls] = ["https://example.com/boxes/test.box?access_token=TEST",
          "file://C:/my/box/path/local.box"]
        subject.call(env)
        expect(env[:box_urls]).to eq([
          "https://example.com/boxes/test.box",
          "file://C:/my/box/path/local.box"])
      end
    end

    context "with VAGRANT_SERVER_ACCESS_TOKEN_BY_URL set" do

      before { stub_env("VAGRANT_SERVER_ACCESS_TOKEN_BY_URL" => "1") }

      it "appends the access token to the URL of server URLs" do
        original = [
          "http://example.com/box.box",
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

        original = [
          "http://example.com/box.box",
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

        original = [
          "http://example.org/box.box",
          "http://vagrantcloud.com/foo.box",
          "http://example.com/bar.box",
          "http://example.com/foo.box"
        ]

        expected = original.dup
        expected[2] = expected[2] + "?access_token=#{token}"
        expected[3] = expected[3] + "?access_token=#{token}"

        expect(subject).to receive(:sleep).once
        expect(ui).to receive(:warn).once.and_call_original

        env[:box_urls] = original.dup
        subject.call(env)

        expect(env[:box_urls]).to eq(expected)
      end

      it "ignores urls that it cannot parse" do
        bad_url = "this is not a valid url"
        # Ensure the bad URL does cause an exception
        expect{ URI.parse(bad_url) }.to raise_error URI::Error
        env[:box_urls] = [bad_url]
        subject.call(env)
        expect(env[:box_urls].first).to eq(bad_url)
      end

      it "does not append multiple access_tokens" do
        original = [
          "#{server_url}/foo.box?access_token=existing",
          "#{server_url}/bar.box?arg=true",
        ]

        env[:box_urls] = original.dup
        subject.call(env)

        expect(env[:box_urls][0]).to eq("#{server_url}/foo.box?access_token=existing")
        expect(env[:box_urls][1]).to eq("#{server_url}/bar.box?arg=true&access_token=#{token}")
      end


      context "when token is not set" do
        let(:token) { nil }

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
      end
    end


    context "with VAGRANT_SERVER_ACCESS_TOKEN_BY_URL unset" do

      before { stub_env("VAGRANT_SERVER_ACCESS_TOKEN_BY_URL" => nil) }

      it "returns the original urls" do
        box1 = "http://vagrantcloud.com/box.box"
        box2 = "http://app.vagrantup.com/box.box"

        env = {
          box_urls: [
            box1.dup,
            box2.dup
          ]
        }
        subject.call(env)

        expect(env[:box_urls]).to eq([box1, box2])
      end

      it "removes access_token parameters if set" do
        box1 = "http://vagrantcloud.com/box.box"
        box2 = "http://app.vagrantup.com/box.box"
        box3 = "http://app.vagrantup.com/box.box?arg1=value1"

        env = {
          box_urls: [
            "#{box1}?access_token=TEST_TOKEN",
            box2.dup,
            "#{box3}&access_token=TEST_TOKEN"
          ]
        }
        subject.call(env)

        expect(env[:box_urls]).to eq([box1, box2, box3])
      end
    end
  end
end
