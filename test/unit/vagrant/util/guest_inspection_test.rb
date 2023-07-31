# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/guest_inspection"

describe Vagrant::Util::GuestInspection::Linux do
  include_context "unit"

  let(:comm) { double("comm") }

  subject{ Class.new { extend Vagrant::Util::GuestInspection::Linux } }

  describe "#systemd?" do
    it "should execute the command with sudo" do
      expect(comm).to receive(:test).with(/ps/, {sudo: true}).and_return(true)
      expect(subject.systemd?(comm)).to be(true)
    end
  end
end
