require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/search")

describe VagrantPlugins::CloudCommand::Command::Search do
  include_context "unit"

  let(:argv)     { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:client) { double("client", token: "1234token1234") }

  subject { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }

  before do
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
    allow(VagrantPlugins::CloudCommand::Util).to receive(:client_login).
      and_return(client)
    allow(VagrantPlugins::CloudCommand::Util).to receive(:format_search_results).
      and_return(true)
  end

  context "with no arguments" do
    let (:search) { double("search", search: {"boxes"=>["all of them"]}) }

    it "makes a request to search all boxes and formats them" do
      allow(VagrantCloud::Search).to receive(:new).
        and_return(search)
      expect(VagrantPlugins::CloudCommand::Util).to receive(:format_search_results)
      expect(subject.execute).to eq(0)
    end
  end

  context "with no arguments and an error occurs making requests" do
    let (:search) { double("search") }

    it "catches a ClientError if something goes wrong" do
      allow(VagrantCloud::Search).to receive(:new).
        and_return(search)
      allow(search).to receive(:search).
        and_raise(VagrantCloud::ClientError.new("Fail Message", "Message", 404))

      expect(subject.execute).to eq(1)
    end
  end

  context "with no arguments and no results" do
    let (:search) { double("search", search: {"boxes"=>[]}) }

    it "makes a request to search all boxes and formats them" do
      allow(VagrantCloud::Search).to receive(:new).
        and_return(search)
      expect(VagrantPlugins::CloudCommand::Util).not_to receive(:format_search_results)
      subject.execute
    end
  end

  context "with arguments" do
    let (:search) { double("search", search: {"boxes"=>["all of them"]}) }
    let (:argv) { ["ubuntu", "--page",  "1", "--order",  "desc", "--limit", "100", "--provider", "provider", "--sort", "downloads"] }

    it "sends the options to make a request with" do
      allow(VagrantCloud::Search).to receive(:new).
        and_return(search)
      expect(search).to receive(:search).
        with("ubuntu", "provider", "downloads", "desc", 100, 1)
      subject.execute
    end
  end
end
