require File.expand_path("../../../base", __FILE__)

require "vagrant/util/ansi_escape_code_remover"

describe Vagrant::Util::ANSIEscapeCodeRemover do
  let(:klass) do
    Class.new do
      extend Vagrant::Util::ANSIEscapeCodeRemover
    end
  end

  it "should remove ANSI escape codes" do
    expect(klass.remove_ansi_escape_codes("\e[Hyo")).to eq("yo")
  end
end

