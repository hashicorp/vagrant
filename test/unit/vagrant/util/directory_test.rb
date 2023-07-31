# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)
require "vagrant/util/directory"
require "time"

describe Vagrant::Util::Directory do
  include_context "unit"
  
  let(:subject){ Vagrant::Util::Directory }
  
  describe ".directory_changed?" do

    it "should return false if the threshold time is larger the all mtimes" do
      t = Time.new("3008", "09", "09")
      expect(subject.directory_changed?(Dir.getwd, t)).to eq(false)
    end

    it "should return true if the threshold time is less than any mtimes" do
      t = Time.new("1990", "06", "06")
      expect(subject.directory_changed?(Dir.getwd, t)).to eq(true)
    end
  end
end
