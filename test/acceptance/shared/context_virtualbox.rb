# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

shared_context "provider-context/virtualbox" do
  let(:extra_env) {{
    "VBOX_USER_HOME" => "{{homedir}}",
  }}
end
