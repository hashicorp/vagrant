# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/search")

describe VagrantPlugins::CloudCommand::Command::Search do
  include_context "unit"

  let(:token) { double("token") }
  let(:argv)     { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  subject { described_class.new(argv, iso_env) }

  describe "#search" do
    let(:query) { double("query") }
    let(:options) { {} }
    let(:account) { double("account", searcher: searcher) }
    let(:searcher) { double("searcher") }
    let(:results) { double("results", boxes: boxes) }
    let(:boxes) { [] }

    before do
      allow(VagrantCloud::Account).to receive(:new).
        with(custom_server: anything, access_token: token).and_return(account)
      allow(searcher).to receive(:search).and_return(results)
      allow(subject).to receive(:format_search_results)
    end

    it "should perform search" do
      expect(searcher).to receive(:search).with(hash_including(query: query)).and_return(results)
      subject.search(query, token, options)
    end

    it "should print a warning when no results are found" do
      expect(iso_env.ui).to receive(:warn)
      subject.search(query, token, options)
    end

    context "with valid options" do
      let(:provider) { double("provider") }
      let(:sort) { double("sort") }
      let(:order) { double("order") }
      let(:limit) { double("limit") }
      let(:page) { double("page") }

      let(:options) { {
        provider: provider,
        sort: sort,
        order: order,
        limit: limit,
        page: page
      } }

      it "should use options when performing search" do
        expect(searcher).to receive(:search) do |**args|
          options.each_pair do |k, v|
            expect(args[k]).to eq(v)
          end
          results
        end
        subject.search(query, token, options)
      end

      context "with invalid options" do
        before { options[:invalid_option] = "testing" }

        it "should only pass supported options to search" do
          expect(searcher).to receive(:search) do |**args|
            options.each_pair do |k, v|
              next if k == :invalid_option
              expect(args[k]).to eq(v)
            end
            expect(args.key?(:invalid_option)).to be_falsey
            results
          end
          subject.search(query, token, options)
        end
      end
    end

    context "with search results" do
      let(:results) { double("results", boxes: [double("result")]) }

      it "should format the results" do
        expect(subject).to receive(:format_search_results).with(results.boxes, any_args)
        subject.search(query, token, options)
      end

      context "with format options" do
        let(:options) { {short: true, json: false} }

        it "should pass options to format" do
          expect(subject).to receive(:format_search_results).with(results.boxes, true, false, iso_env)
          subject.search(query, token, options)
        end
      end
    end
  end

  describe "#execute" do
    let(:argv)     { [] }
    let(:iso_env) do
      # We have to create a Vagrantfile so there is a root path
      env = isolated_environment
      env.vagrantfile("")
      env.create_vagrant_env
    end

    subject { described_class.new(argv, iso_env) }

    let(:action_runner) { double("action_runner") }

    let(:client) { double("client", token: token) }
    let(:box) { double("box") }

    before do
      allow(iso_env).to receive(:action_runner).and_return(action_runner)
      allow(subject).to receive(:client_login).and_return(client)
      allow(subject).to receive(:search)
    end

    context "with no arguments" do
      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "with query argument" do
      let(:query_arg) { "search-query" }

      before { argv << query_arg }

      it "should run the search" do
        expect(subject).to receive(:search).with(query_arg, any_args)
        subject.execute
      end

      it "should setup client login quietly by default" do
        expect(subject).to receive(:client_login).with(iso_env, hash_including(quiet: true))
        subject.execute
      end

      context "with --auth flag" do
        before { argv << "--auth" }

        it "should not setup login client quietly" do
          expect(subject).to receive(:client_login).with(iso_env, hash_including(quiet: false))
          subject.execute
        end
      end
    end
  end
end
