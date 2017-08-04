require File.expand_path("../../../../../base", __FILE__)

describe VagrantPlugins::CommandPlugin::Action::PluginExistsCheck do
  let(:app) { lambda {} }
  let(:env) { {} }

  let(:manager) { double("manager") }

  subject { described_class.new(app, env) }

  before do
    allow(Vagrant::Plugin::Manager).to receive(:instance).and_return(manager)
  end

  it "should raise an exception if the plugin doesn't exist" do
    allow(manager).to receive(:installed_plugins).and_return({ "foo" => {} })
    expect(app).not_to receive(:call)

    env[:plugin_name] = "bar"
    expect { subject.call(env) }.
      to raise_error(Vagrant::Errors::PluginNotInstalled)
  end

  it "should call the app if the plugin is installed" do
    allow(manager).to receive(:installed_plugins).and_return({ "bar" => {} })
    expect(app).to receive(:call).once.with(env)

    env[:plugin_name] = "bar"
    subject.call(env)
  end
end
