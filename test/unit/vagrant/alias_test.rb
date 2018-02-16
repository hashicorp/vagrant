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
  end
end
