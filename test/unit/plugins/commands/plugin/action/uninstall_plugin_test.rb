require File.expand_path('../../../../../base', __FILE__)

describe VagrantPlugins::CommandPlugin::Action::UninstallPlugin do
  let(:app) { lambda { |_env| } }
  let(:env) do{
    ui: Vagrant::UI::Silent.new,
  }end

  let(:manager) { double('manager') }

  subject { described_class.new(app, env) }

  before do
    Vagrant::Plugin::Manager.stub(instance: manager)
  end

  it 'uninstalls the specified plugin' do
    expect(manager).to receive(:uninstall_plugin).with('bar').ordered
    expect(app).to receive(:call).ordered

    env[:plugin_name] = 'bar'
    subject.call(env)
  end
end
