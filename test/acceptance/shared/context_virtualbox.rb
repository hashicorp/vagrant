# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

shared_context "provider-context/virtualbox" do
  let(:extra_env) {{
    "VBOX_USER_HOME" => "{{homedir}}",
  }}
end
