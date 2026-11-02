# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../base"

require "vagrant/alias"

describe Vagrant::Alias do
  include_context "unit"
  include_context "command plugin helpers"

  let(:iso_env) { isolated_environment }
  let(:env)     { iso_env.create_vagrant_env }

  describe "#interpret" do
    let(:interpreter) { described_class.new(env) }

    it "returns nil for comments" do
      comments = [
        "# this is a comment",
        "# so is this       ",
        "       # and this",
        "       # this too       "
      ]

      comments.each do |comment|
        expect(interpreter.interpret(comment)).to be_nil
      end
    end

    it "raises an error on invalid keywords" do
      keywords = [
        "keyword with a space = command",
        "keyword\twith a tab = command",
        "keyword\nwith a newline = command",
      ]

      keywords.each do |keyword|
        expect { interpreter.interpret(keyword) }.to raise_error(Vagrant::Errors::AliasInvalidError)
      end
    end

    it "properly interprets a simple alias" do
      keyword, command = interpreter.interpret("keyword=command")

      expect(keyword).to eq("keyword")
      expect(command).to eq("command")
    end

    it "properly interprets an alias with excess whitespace" do
      keyword, command = interpreter.interpret("     keyword      =     command    ")

      expect(keyword).to eq("keyword")
      expect(command).to eq("command")
    end

    it "properly interprets an alias with an equals sign in the command" do
      keyword, command = interpreter.interpret("     keyword      =     command = command    ")

      expect(keyword).to eq("keyword")
      expect(command).to eq("command = command")
    end

    it "allows keywords with non-alpha-numeric characters" do
      keyword, command = interpreter.interpret("keyword! = command")

      expect(keyword).to eq("keyword!")
      expect(command).to eq("command")
    end
  end
end
