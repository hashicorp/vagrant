shared_context 'provider-context/virtualbox' do
  let(:extra_env) do{
    'VBOX_USER_HOME' => '{{homedir}}',
  }end
end
