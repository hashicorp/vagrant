# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Driver::Version_4_1 do
  include_context "virtualbox"
  let(:vbox_version) { "4.1.0" }
  subject { VagrantPlugins::ProviderVirtualBox::Driver::Meta.new(uuid) }

  it_behaves_like "a version 4.x virtualbox driver"
end
