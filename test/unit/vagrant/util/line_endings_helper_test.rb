require File.expand_path("../../../base", __FILE__)

require "vagrant/util/line_ending_helpers"

describe Vagrant::Util::LineEndingHelpers do
  let(:klass) do
    Class.new do
      extend Vagrant::Util::LineEndingHelpers
    end
  end

  it "should convert DOS to unix-style line endings" do
    expect(klass.dos_to_unix("foo\r\nbar\r\n")).to eq("foo\nbar\n")
  end
end

