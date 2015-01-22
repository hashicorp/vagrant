require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/login/command")

describe VagrantPlugins::LoginCommand::Client do
  include_context "unit"

  let(:env) { isolated_environment.create_vagrant_env }

  subject { described_class.new(env) }

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

      it "returns false if the endpoint returns a non-200" do
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
    it "returns the access token after successful login" do
      request = {
        "user" => {
          "login" => "foo",
          "password" => "bar",
        },
      }

      response = {
        "token" => "baz",
      }

      headers = { "Content-Type" => "application/json" }

      stub_request(:post, "#{Vagrant.server_url}/api/v1/authenticate").
        with(body: JSON.dump(request), headers: headers).
        to_return(status: 200, body: JSON.dump(response))

      expect(subject.login("foo", "bar")).to eq("baz")
    end

    it "returns nil on bad login" do
      stub_request(:post, "#{Vagrant.server_url}/api/v1/authenticate").
        to_return(status: 401, body: "")

      expect(subject.login("foo", "bar")).to be(false)
    end

    it "raises an exception if it can't reach the sever" do
      stub_request(:post, "#{Vagrant.server_url}/api/v1/authenticate").
        to_raise(SocketError)

      expect { subject.login("foo", "bar") }.
        to raise_error(VagrantPlugins::LoginCommand::Errors::ServerUnreachable)
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
      stub_env("ATLAS_TOKEN" => "ABCD1234")
      subject.store_token("EFGH5678")
      expect(subject.token).to eq("ABCD1234")
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
