require File.expand_path("../../../../../base", __FILE__)

describe VagrantPlugins::CommandPlugin::Action::UpdateGems do
  let(:app) { lambda { |env| } }
  let(:env) {{
    ui: Vagrant::UI::Silent.new
  }}

  let(:manager) { double("manager") }

  subject { described_class.new(app, env) }

  before do
    allow(Vagrant::Plugin::Manager).to receive(:instance).and_return(manager)
    allow(manager).to receive(:installed_specs).and_return([])
  end

  describe "#call" do
    it "should update all plugins if none are specified" do
      expect(manager).to receive(:update_plugins).with([]).once.and_return([])
      expect(manager).to receive(:installed_plugins).twice.and_return({})
      expect(app).to receive(:call).with(env).once
      subject.call(env)
    end

    it "should update specified plugins" do
      expect(manager).to receive(:update_plugins).with(["foo"]).once.and_return([])
      expect(manager).to receive(:installed_plugins).twice.and_return({})
      expect(app).to receive(:call).with(env).once

      env[:plugin_name] = ["foo"]
      subject.call(env)
    end
  end
end
