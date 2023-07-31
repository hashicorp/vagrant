# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/map_command_options'

describe Vagrant::Util::MapCommandOptions do

  subject { described_class }

  it "should convert a map to a list of command options" do
    [
      [{a: "opt1", b: true, c: "opt3"}, "--", ["--a", "opt1", "--b", "--c", "opt3"]],
      [{a: "opt1", b: false, c: "opt3"}, "-", ["-a", "opt1", "-c", "opt3"]],
      [{a: "opt1", b: 1}, "--", ["--a", "opt1"]],
      [{a: 1, b: 1}, "--", []],
      [{}, "--", []],
      [nil, nil, []]
    ].each do |map, cmd_flag, expected_output|
      expect(subject.map_to_command_options(map, cmd_flag)).to eq(expected_output)
    end
  end
end
