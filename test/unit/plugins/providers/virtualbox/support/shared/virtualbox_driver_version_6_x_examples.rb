# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

shared_examples "a version 6.x virtualbox driver" do |options|
  before do
    raise ArgumentError, "Need virtualbox context to use these shared examples." if !(defined? vbox_context)
  end
end
