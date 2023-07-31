# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/shell_quote"

describe Vagrant::Util::ShellQuote do
  subject { described_class }

  it "quotes properly" do
    expected = "foo '\\''bar'\\''"
    expect(subject.escape("foo 'bar'", "'")).to eql(expected)
  end
end
