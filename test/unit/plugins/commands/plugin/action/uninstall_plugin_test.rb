require File.expand_path("../../../../../base", __FILE__)

describe VagrantPlugins::CommandPlugin::Action::UninstallPlugin do
  let(:app) { lambda { |env| } }
  let(:env) {{
    ui: Vagrant::UI::Silent.new,
  }}

  let(:manager) { double("manager") }

  subject { described_class.new(app, env) }

  before do
    allow(Vagrant::Plugin::Manager).to receive(:instance).and_return(manager)
  end

  it "uninstalls the specified plugin" do
    expect(manager).to receive(:uninstall_plugin).with("bar").ordered
    expect(app).to receive(:call).ordered

    env[:plugin_name] = "bar"
    subject.call(env)
  end
end
