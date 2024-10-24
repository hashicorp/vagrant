# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "stringio"
require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Driver::Version_7_1 do
  include_context "virtualbox"

  subject { VagrantPlugins::ProviderVirtualBox::Driver::Version_7_1.new(uuid) }

  it_behaves_like "a version 5.x virtualbox driver"
  it_behaves_like "a version 6.x virtualbox driver"
  it_behaves_like "a version 7.x virtualbox driver"
end
