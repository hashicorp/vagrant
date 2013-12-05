shared_context "provider/virtualbox" do
  let(:extra_env) {{
    "VBOX_USER_HOME" => "{{homedir}}",
  }}
end
