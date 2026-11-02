# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

describe VagrantPlugins::CommandPlugin::Action::ExpungePlugins do
  let(:app) { lambda { |env| } }
  let(:home_path){ '/fake/file/path/.vagrant.d' }
  let(:gems_path){ "#{home_path}/gems" }
  let(:force){ true }
  let(:env_local){ false }
  let(:env_local_only){ nil }
  let(:global_only){ nil }
  let(:env) {{
    ui: Vagrant::UI::Silent.new,
    home_path: home_path,
    gems_path: gems_path,
    force: force,
    env_local: env_local,
    env_local_only: env_local_only,
    global_only: global_only
  }}

  let(:user_file) { double("user_file", path: user_file_pathname) }
  let(:user_file_pathname) { double("user_file_pathname", exist?: true, delete: true) }
  let(:local_file) { nil }
  let(:bundler) { double("bundler", plugin_gem_path: plugin_gem_path,
    env_plugin_gem_path: env_plugin_gem_path) }
  let(:plugin_gem_path) { double("plugin_gem_path", exist?: true, rmtree: true) }
  let(:env_plugin_gem_path) { nil }

  let(:manager) { double("manager", user_file: user_file, local_file: local_file) }

  let(:expect_to_receive) do
    lambda do
      allow(File).to receive(:exist?).with(File.join(home_path, 'plugins.json')).and_return(true)
      allow(File).to receive(:directory?).with(gems_path).and_return(true)
      expect(app).to receive(:call).with(env).once
    end
  end

  subject { described_class.new(app, env) }

  before do
    allow(Vagrant::Plugin::Manager).to receive(:instance).and_return(manager)
    allow(Vagrant::Bundler).to receive(:instance).and_return(bundler)
  end

  describe "#call" do
    before do
      instance_exec(&expect_to_receive)
    end

    it "should delete all plugins" do
      expect(user_file_pathname).to receive(:delete)
      expect(plugin_gem_path).to receive(:rmtree)
      subject.call(env)
    end

    describe "when force is false" do
      let(:force){ false }

      it "should prompt user before deleting all plugins" do
        expect(env[:ui]).to receive(:ask).and_return("Y\n")
        subject.call(env)
      end

      describe "when user declines prompt" do
        let(:expect_to_receive) do
          lambda do
            expect(app).not_to receive(:call)
          end
        end

        it "should not delete all plugins" do
          expect(env[:ui]).to receive(:ask).and_return("N\n")
          subject.call(env)
        end
      end
    end

    context "when local option is set" do
      let(:env_local) { true }

      it "should delete plugins" do
        expect(user_file_pathname).to receive(:delete)
        expect(plugin_gem_path).to receive(:rmtree)
        subject.call(env)
      end
    end

    context "when local plugins exist" do
      let(:local_file) { double("local_file", path: local_file_pathname) }
      let(:local_file_pathname) { double("local_file_pathname", exist?: true, delete: true) }
      let(:env_plugin_gem_path) { double("env_plugin_gem_path", exist?: true, rmtree: true) }

      it "should delete user and local plugins" do
        expect(user_file_pathname).to receive(:delete)
        expect(local_file_pathname).to receive(:delete)
        expect(plugin_gem_path).to receive(:rmtree)
        expect(env_plugin_gem_path).to receive(:rmtree)
        subject.call(env)
      end

      context "when local option is set" do
        let(:env_local) { true }

        it "should delete local plugins" do
          expect(local_file_pathname).to receive(:delete)
          expect(env_plugin_gem_path).to receive(:rmtree)
          subject.call(env)
        end

        it "should delete user plugins" do
          expect(user_file_pathname).to receive(:delete)
          expect(plugin_gem_path).to receive(:rmtree)
          subject.call(env)
        end

        context "when local only option is set" do
          let(:env_local_only) { true }

          it "should delete local plugins" do
            expect(local_file_pathname).to receive(:delete)
            expect(env_plugin_gem_path).to receive(:rmtree)
            subject.call(env)
          end

          it "should not delete user plugins" do
            expect(user_file_pathname).not_to receive(:delete)
            expect(plugin_gem_path).not_to receive(:rmtree)
            subject.call(env)
          end
        end

        context "when global only option is set" do
          let(:global_only) { true }

          it "should not delete local plugins" do
            expect(local_file_pathname).not_to receive(:delete)
            expect(env_plugin_gem_path).not_to receive(:rmtree)
            subject.call(env)
          end

          it "should delete user plugins" do
            expect(user_file_pathname).to receive(:delete)
            expect(plugin_gem_path).to receive(:rmtree)
            subject.call(env)
          end
        end

        context "when global and local only options are set" do
          let(:env_local_only) { true }
          let(:global_only) { true }

          it "should delete local plugins" do
            expect(local_file_pathname).to receive(:delete)
            expect(env_plugin_gem_path).to receive(:rmtree)
            subject.call(env)
          end

          it "should delete user plugins" do
            expect(user_file_pathname).to receive(:delete)
            expect(plugin_gem_path).to receive(:rmtree)
            subject.call(env)
          end
        end
      end
    end
  end
end
