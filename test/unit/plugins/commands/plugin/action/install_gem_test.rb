require File.expand_path("../../../../../base", __FILE__)

describe VagrantPlugins::CommandPlugin::Action::InstallGem do
  let(:app) { lambda { |env| } }
  let(:env) {{
    ui: Vagrant::UI::Silent.new
  }}

  let(:manager) { double("manager") }

  subject { described_class.new(app, env) }

  before do
    Vagrant::Plugin::Manager.stub(instance: manager)
  end

  describe "#call" do
    it "should install the plugin" do
      spec = Gem::Specification.new
      manager.should_receive(:install_plugin).with(
        "foo", version: nil, require: nil, sources: nil, verbose: false,
        git: nil, git_ref: nil, git_tag: nil, git_branch: nil).once.and_return(spec)

      app.should_receive(:call).with(env).once

      env[:plugin_name] = "foo"
      subject.call(env)
    end

    it "should specify the version if given" do
      spec = Gem::Specification.new
      manager.should_receive(:install_plugin).with(
        "foo", version: "bar", require: nil, sources: nil, verbose: false,
        git: nil, git_ref: nil, git_tag: nil, git_branch: nil).once.and_return(spec)

      app.should_receive(:call).with(env).once

      env[:plugin_name] = "foo"
      env[:plugin_version] = "bar"
      subject.call(env)
    end

    it "should specify the entrypoint if given" do
      spec = Gem::Specification.new
      manager.should_receive(:install_plugin).with(
        "foo", version: "bar", require: "baz", sources: nil, verbose: false,
        git: nil, git_ref: nil, git_tag: nil, git_branch: nil).once.and_return(spec)

      app.should_receive(:call).with(env).once

      env[:plugin_entry_point] = "baz"
      env[:plugin_name] = "foo"
      env[:plugin_version] = "bar"
      subject.call(env)
    end

    it "should specify the sources if given" do
      spec = Gem::Specification.new
      manager.should_receive(:install_plugin).with(
        "foo", version: nil, require: nil, sources: ["foo"], verbose: false,
        git: nil, git_ref: nil, git_tag: nil, git_branch: nil).once.and_return(spec)

      app.should_receive(:call).with(env).once

      env[:plugin_name] = "foo"
      env[:plugin_sources] = ["foo"]
      subject.call(env)
    end

    it "should specify the git repository if given" do
      spec = Gem::Specification.new
      manager.should_receive(:install_plugin).with(
        "foo", version: nil, require: nil, sources: nil, verbose: false,
        git: "bar", git_ref: nil, git_tag: nil, git_branch: nil).once.and_return(spec)

      app.should_receive(:call).with(env).once

      env[:plugin_name] = "foo"
      env[:plugin_git] = "bar"
      subject.call(env)
    end

    it "should specify the git repository and ref if given" do
      spec = Gem::Specification.new
      manager.should_receive(:install_plugin).with(
        "foo", version: nil, require: nil, sources: nil, verbose: false,
        git: "bar", git_ref: "baz", git_tag: nil, git_branch: nil).once.and_return(spec)

      app.should_receive(:call).with(env).once

      env[:plugin_name] = "foo"
      env[:plugin_git] = "bar"
      env[:plugin_git_ref] = "baz"
      subject.call(env)
    end

    it "should specify the git repository and tag if given" do
      spec = Gem::Specification.new
      manager.should_receive(:install_plugin).with(
        "foo", version: nil, require: nil, sources: nil, verbose: false,
        git: "bar", git_ref: nil, git_tag: "baz", git_branch: nil).once.and_return(spec)

      app.should_receive(:call).with(env).once

      env[:plugin_name] = "foo"
      env[:plugin_git] = "bar"
      env[:plugin_git_tag] = "baz"
      subject.call(env)
    end

    it "should specify the git repository and branch if given" do
      spec = Gem::Specification.new
      manager.should_receive(:install_plugin).with(
        "foo", version: nil, require: nil, sources: nil, verbose: false,
        git: "bar", git_ref: nil, git_tag: nil, git_branch: "baz").once.and_return(spec)

      app.should_receive(:call).with(env).once

      env[:plugin_name] = "foo"
      env[:plugin_git] = "bar"
      env[:plugin_git_branch] = "baz"
      subject.call(env)
    end
end

  describe "#recover" do
    it "should do nothing by default" do
      subject.recover(env)
    end

    context "with a successful plugin install" do
      let(:action_runner) { double("action_runner") }

      before do
        spec = Gem::Specification.new
        spec.name = "foo"
        manager.stub(install_plugin: spec)

        env[:plugin_name] = "foo"
        subject.call(env)

        env[:action_runner] = action_runner
      end

      it "should uninstall the plugin" do
        action_runner.should_receive(:run).with do |action, newenv|
          expect(newenv[:plugin_name]).to eql("foo")
        end

        subject.recover(env)
      end
    end
  end
end
