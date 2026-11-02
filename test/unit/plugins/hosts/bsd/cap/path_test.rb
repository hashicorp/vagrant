# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/bsd/cap/path"

describe VagrantPlugins::HostBSD::Cap::Path do
  describe ".resolve_host_path" do
    let(:env) { double("environment") }
    let(:path) { double("path") }

    it "should return the path object provided" do
      expect(described_class.resolve_host_path(env, path)).to eq(path)
    end
  end
end
