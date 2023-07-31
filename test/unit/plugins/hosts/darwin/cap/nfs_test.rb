# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require_relative "../../../../../../plugins/hosts/darwin/cap/nfs"

describe VagrantPlugins::HostDarwin::Cap::NFS do
  include_context "unit"

  let(:subject){ VagrantPlugins::HostDarwin::Cap::NFS }

  it "exists" do
    expect(subject).to_not be(nil)
  end

  it "should use nfs/exports_darwin as its template" do
    expect(subject.nfs_exports_template(nil)).to eq("nfs/exports_darwin")
  end
end
