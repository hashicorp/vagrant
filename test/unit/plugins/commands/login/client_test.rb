require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/login/command")

describe VagrantPlugins::LoginCommand::Client do
  include_context "unit"

  let(:env) { isolated_environment.create_vagrant_env }

  subject { described_class.new(env) }

  describe "#logged_in?" do
    it "quickly returns false if no token is set" do
      expect(subject).to_not be_logged_in
    end

    it "returns true if the endpoint returns 200" do
      subject.store_token("foo")

      response = {
        "token" => "baz",
      }

      headers = { "Content-Type" => "application/json" }
      url = "#{Vagrant.server_url}/api/v1/authenticate?access_token=foo"
      stub_request(:get, url).
        with(headers: headers).
        to_return(status: 200, body: JSON.dump(response))

      expect(subject).to be_logged_in
    end

    it "returns false if 401 is returned" do
      subject.store_token("foo")

      url = "#{Vagrant.server_url}/api/v1/authenticate?access_token=foo"
      stub_request(:get, url).
        to_return(status: 401, body: "")

      expect(subject).to_not be_logged_in
    end

    it "raises an exception if it can't reach the sever" do
      subject.store_token("foo")

      url = "#{Vagrant.server_url}/api/v1/authenticate?access_token=foo"
      stub_request(:get, url).to_raise(SocketError)

      expect { subject.logged_in? }.
        to raise_error(VagrantPlugins::LoginCommand::Errors::ServerUnreachable)
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

      expect(subject.login("foo", "bar")).to be_nil
    end

    it "raises an exception if it can't reach the sever" do
      stub_request(:post, "#{Vagrant.server_url}/api/v1/authenticate").
        to_raise(SocketError)

      expect { subject.login("foo", "bar") }.
        to raise_error(VagrantPlugins::LoginCommand::Errors::ServerUnreachable)
    end
  end

  describe "#token, #store_token, #clear_token" do
    it "returns nil if there is no token" do
      expect(subject.token).to be_nil
    end

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
