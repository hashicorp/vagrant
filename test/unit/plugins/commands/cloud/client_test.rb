# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/client/client")

describe VagrantPlugins::CloudCommand::Client do
  include_context "unit"

  let(:env) { isolated_environment.create_vagrant_env }
  let(:token) { nil }
  let(:vc_client) { double("vagrantcloud-client", access_token: token) }

  subject(:client) { described_class.new(env) }

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/commands/cloud/locales/en.yml")
    I18n.reload!
  end

  before do
    stub_env("ATLAS_TOKEN" => nil)
    stub_env("VAGRANT_CLOUD_TOKEN" => nil)
    allow(VagrantCloud::Client).to receive(:new).and_return(vc_client)
    allow(Vagrant::Util::CredentialScrubber).to receive(:sensitive)
  end

  after do
    described_class.reset!
    Vagrant::Util::CredentialScrubber.reset!
  end

  describe "#logged_in?" do
    before { allow(subject).to receive(:token).and_return(token) }

    context "when token is not set" do
      it "should return false" do
        expect(subject.logged_in?).to be_falsey
      end
    end

    context "when token is set" do
      let(:token) { double("token") }

      before do
        allow(vc_client).to receive(:authentication_token_validate)
      end

      it "should return true when token is valid" do
        expect(subject.logged_in?).to be_truthy
      end

      it "should validate the set token" do
        expect(vc_client).to receive(:authentication_token_validate)
        subject.logged_in?
      end

      it "should return false when token does not validate" do
        expect(vc_client).to receive(:authentication_token_validate).
          and_raise(Excon::Error::Unauthorized.new(StandardError.new))
        expect(subject.logged_in?).to be_falsey
      end

      it "should add token to scrubber" do
        expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with(token)
        subject.logged_in?
      end
    end
  end

  describe "#login" do
    let(:new_token) { double("new-token") }
    let(:result) { {token: new_token} }
    let(:password) { double("password") }
    let(:username) { double("username") }

    before do
      subject.username_or_email = username
      subject.password = password
      allow(vc_client).to receive(:authentication_token_create).
        and_return(result)
    end

    it "should add password to scrubber" do
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with(password)
      subject.login
    end

    it "should create an authentication token" do
      expect(vc_client).to receive(:authentication_token_create).
        and_return(result)
      subject.login
    end

    it "should wrap remote request to handle errors" do
      expect(subject).to receive(:with_error_handling)
      subject.login
    end

    it "should add new token to scrubber" do
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with(new_token)
      subject.login
    end

    it "should create a new internal client" do
      expect(VagrantCloud::Client).to receive(:new).with(access_token: new_token, url_base: anything)
      subject.login
    end

    it "should create authentication token using username and password" do
      expect(vc_client).to receive(:authentication_token_create).
        with(hash_including(username: username, password: password)).and_return(result)
      subject.login
    end

    it "should return the new token" do
      expect(subject.login).to eq(new_token)
    end

    context "with description and code" do
      let(:description) { double("description") }
      let(:code) { double("code") }

      it "should create authentication token using description and code" do
        expect(vc_client).to receive(:authentication_token_create).with(
          hash_including(username: username, password: password,
            description: description, code: code))
        subject.login(description: description, code: code)
      end
    end
  end

  describe "#request_code" do
    let(:password) { double("password") }
    let(:username) { double("username") }
    let(:delivery_method) { double("delivery-method", upcase: nil) }
    let(:result) { {two_factor: two_factor} }
    let(:two_factor) { {obfuscated_destination: obfuscated_destination} }
    let(:obfuscated_destination) { double("obfuscated-destination", to_s: "2FA_DESTINATION") }

    before do
      subject.password = password
      subject.username_or_email = username
      allow(vc_client).to receive(:authentication_request_2fa_code).and_return(result)
    end

    it "should add password to scrubber" do
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with(password)
      subject.request_code(delivery_method)
    end

    it "should request the code" do
      expect(vc_client).to receive(:authentication_request_2fa_code).with(
        hash_including(username: username, password: password, delivery_method: delivery_method))
      subject.request_code(delivery_method)
    end

    it "should print the destination" do
      expect(env.ui).to receive(:success).with(/2FA_DESTINATION/)
      subject.request_code(delivery_method)
    end
  end

  describe "#store_token" do
    let(:token_path) { double("token-path") }
    let(:new_token) { double("new-token") }

    before do
      allow(subject).to receive(:token_path).and_return(token_path)
      allow(token_path).to receive(:open)
    end

    it "should add token to scrubber" do
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with(new_token)
      subject.store_token(new_token)
    end

    it "should create a new internal client with token" do
      expect(VagrantCloud::Client).to receive(:new).with(access_token: new_token, url_base: anything)
      subject.store_token(new_token)
    end

    it "should open the token path and write the new token" do
      f = double("file")
      expect(token_path).to receive(:open).with("w").and_yield(f)
      expect(f).to receive(:write).with(new_token)
      subject.store_token(new_token)
    end
  end

  describe "#token" do
    let(:env_token) { "ENV_TOKEN" }
    let(:file_token) { "FILE_TOKEN" }
    let(:token_path) { double("token-path", read: file_token) }
    let(:path_exists) { false }

    before do
      allow(subject).to receive(:token).and_call_original
      allow(subject).to receive(:token_path).and_return(token_path)
      allow(token_path).to receive(:exist?).and_return(path_exists)
    end

    context "when VAGRANT_CLOUD_TOKEN env var is set" do
      before { stub_env("VAGRANT_CLOUD_TOKEN" => env_token) }

      it "should return the env token" do
        expect(subject.token).to eq(env_token)
      end

      context "when token path exists" do
        let(:path_exists) { true }

        it "should return the env token" do
          expect(subject.token).to eq(env_token)
        end

        it "should print warning of two tokens" do
          expect(env.ui).to receive(:warn)
          subject.token
        end

        it "should only print warning of two tokens once" do
          expect(env.ui).to receive(:warn).with(/detected/).once
          3.times { subject.token }
        end
      end
    end

    context "when token path exists" do
      let(:path_exists) { true }

      it "should return the stored token" do
        expect(subject.token).to eq(file_token)
      end

      context "when VAGRANT_CLOUD_TOKEN env var is set" do
        before { stub_env("VAGRANT_CLOUD_TOKEN" => env_token) }

        it "should return the env token" do
          expect(subject.token).to eq(env_token)
        end
      end
    end

    context "when ATLAS_TOKEN env var is set" do
      before { stub_env("ATLAS_TOKEN" => env_token) }

      it "should return the env token" do
        expect(subject.token).to eq(env_token)
      end

      context "when VAGRANT_CLOUD_TOKEN is set" do
        let(:vc_token) { "VC_TOKEN" }

        before { stub_env("VAGRANT_CLOUD_TOKEN" => vc_token) }

        it "should return the VAGRANT_CLOUD_TOKEN value" do
          expect(subject.token).to eq(vc_token)
        end
      end

      context "when file exists" do
        let(:path_exists) { true }

        it "should return the file token" do
          expect(subject.token).to eq(file_token)
        end
      end
    end
  end
end
