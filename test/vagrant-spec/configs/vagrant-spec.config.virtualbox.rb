# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../acceptance/base"

Vagrant::Spec::Acceptance.configure do |c|
  c.component_paths << File.expand_path("../test/acceptance", __FILE__)
  c.skeleton_paths << File.expand_path("../test/acceptance/skeletons", __FILE__)
  # Allow for slow setup to still pass
  c.assert_retries = 15
  c.vagrant_path = ENV.fetch("VAGRANT_PATH", "vagrant")
  c.provider "virtualbox",
    box: ENV["VAGRANT_SPEC_BOX"],
    contexts: ["provider-context/virtualbox"]
end
