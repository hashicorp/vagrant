shared_context "provider-context/virtualbox" do
  let(:extra_env) {{
    "VBOX_USER_HOME" => "{{homedir}}",
  }}
end
