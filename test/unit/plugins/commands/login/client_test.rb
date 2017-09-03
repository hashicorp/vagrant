require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/login/command")

describe VagrantPlugins::LoginCommand::Client do
  include_context "unit"

  let(:env) { isolated_environment.create_vagrant_env }

  subject(:client) { described_class.new(env) }

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/commands/login/locales/en.yml")
    I18n.reload!
  end

  before do
    stub_env("ATLAS_TOKEN" => nil)
    subject.clear_token
  end

  describe "#logged_in?" do
    let(:url) { "#{Vagrant.server_url}/api/v1/authenticate?access_token=#{token}" }
    let(:headers) { { "Content-Type" => "application/json" } }

    before { allow(subject).to receive(:token).and_return(token) }

    context "when there is no token" do
      let(:token) { nil }

      it "returns false" do
        expect(subject.logged_in?).to be(false)
      end
    end

    context "when there is a token" do
      let(:token) { "ABCD1234" }

      it "returns true if the endpoint returns a 200" do
        stub_request(:get, url)
          .with(headers: headers)
          .to_return(body: JSON.pretty_generate("token" => token))
        expect(subject.logged_in?).to be(true)
      end

      it "raises an error if the endpoint returns a non-200" do
        stub_request(:get, url)
          .with(headers: headers)
          .to_return(body: JSON.pretty_generate("bad" => true), status: 401)
        expect(subject.logged_in?).to be(false)
      end

      it "raises an exception if the server cannot be found" do
        stub_request(:get, url)
          .to_raise(SocketError)
        expect { subject.logged_in? }
          .to raise_error(VagrantPlugins::LoginCommand::Errors::ServerUnreachable)
      end
    end
  end

  describe "#login" do
    let(:request) {
      {
        user: {
          login: login,
          password: password,
        },
        token: {
          description: description,
        },
        two_factor: {
          code: nil
        }
      }
    }

    let(:login) { "foo" }
    let(:password) { "bar" }
    let(:description) { "Token description" }

    let(:headers) {
      {
        "Accept" => "application/json",
        "Content-Type" => "application/json",
      }
    }
    let(:response) {
      {
        token: "baz"
      }
    }

    it "returns the access token after successful login" do
      stub_request(:post, "#{Vagrant.server_url}/api/v1/authenticate").
        with(body: JSON.dump(request), headers: headers).
        to_return(status: 200, body: JSON.dump(response))

      client.username_or_email = login
      client.password = password

      expect(client.login(description: "Token description")).to eq("baz")
    end

    context "when 2fa is required" do
      let(:response) {
        {
          two_factor: {
            default_delivery_method: default_delivery_method,
            delivery_methods: delivery_methods
          }
        }
      }
      let(:default_delivery_method) { "app" }
      let(:delivery_methods) { ["app"] }

      before do
        stub_request(:post, "#{Vagrant.server_url}/api/v1/authenticate").
          to_return(status: 406, body: JSON.dump(response))
      end

      it "raises a two-factor required error" do
        expect {
          client.login
        }.to raise_error(VagrantPlugins::LoginCommand::Errors::TwoFactorRequired)
      end

      context "when the default delivery method is not app" do
        let(:default_delivery_method) { "sms" }
        let(:delivery_methods) { ["app", "sms"] }

        it "requests a code and then raises a two-factor required error" do
          expect(client)
            .to receive(:request_code)
            .with(default_delivery_method)

          expect {
            client.login
          }.to raise_error(VagrantPlugins::LoginCommand::Errors::TwoFactorRequired)
        end
      end
    end

    context "on bad login" do
      before do
        stub_request(:post, "#{Vagrant.server_url}/api/v1/authenticate").
          to_return(status: 401, body: "")
      end

      it "raises an error" do
        expect {
          client.login
        }.to raise_error(VagrantPlugins::LoginCommand::Errors::Unauthorized)
      end
    end

    context "if it can't reach the server" do
      before do
        stub_request(:post, "#{Vagrant.server_url}/api/v1/authenticate").
          to_raise(SocketError)
      end

      it "raises an exception" do
        expect {
          subject.login
        }.to raise_error(VagrantPlugins::LoginCommand::Errors::ServerUnreachable)
      end
    end
  end

  describe "#request_code" do
    let(:request) {
      {
        user: {
          login: login,
          password: password,
        },
        two_factor: {
          delivery_method: delivery_method
        }
      }
    }

    let(:login) { "foo" }
    let(:password) { "bar" }
    let(:delivery_method) { "sms" }

    let(:headers) {
      {
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
    }

    let(:response) {
      {
        two_factor: {
          obfuscated_destination: "SMS number ending in 1234"
        }
      }
    }

    it "displays that the code was sent" do
      expect(env.ui)
        .to receive(:success)
        .with("2FA code sent to SMS number ending in 1234.")

      stub_request(:post, "#{Vagrant.server_url}/api/v1/two-factor/request-code").
        with(body: JSON.dump(request), headers: headers).
        to_return(status: 201, body: JSON.dump(response))

      client.username_or_email = login
      client.password = password

      client.request_code delivery_method
    end
  end

  describe "#token" do
    it "reads ATLAS_TOKEN" do
      stub_env("ATLAS_TOKEN" => "ABCD1234")
      expect(subject.token).to eq("ABCD1234")
    end

    it "reads the stored file" do
      subject.store_token("EFGH5678")
      expect(subject.token).to eq("EFGH5678")
    end

    it "prefers the environment variable" do
      stub_env("VAGRANT_CLOUD_TOKEN" => "ABCD1234")
      subject.store_token("EFGH5678")
      expect(subject.token).to eq("ABCD1234")
    end

    it "prints a warning if the envvar and stored file are both present" do
      stub_env("VAGRANT_CLOUD_TOKEN" => "ABCD1234")
      subject.store_token("EFGH5678")
      expect(env.ui).to receive(:warn).with(/detected both/)
      subject.token
    end

    it "returns nil if there's no token set" do
      expect(subject.token).to be(nil)
    end
  end

  describe "#store_token, #clear_token" do
    it "stores the token and can re-access it" do
      subject.store_token("foo")
      expect(subject.token).to eq("foo")
      expect(described_class.new(env).token).to eq("foo")
    end

    it "deletes the token" do
      subject.store_token("foo")
      subject.clear_token
      expect(subject.token).to be_nil
    end
  end
end
