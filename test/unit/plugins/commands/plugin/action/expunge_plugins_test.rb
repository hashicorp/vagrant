require File.expand_path("../../../../../base", __FILE__)

describe VagrantPlugins::CommandPlugin::Action::ExpungePlugins do
  let(:app) { lambda { |env| } }
  let(:home_path){ '/fake/file/path/.vagrant.d' }
  let(:gems_path){ "#{home_path}/gems" }
  let(:force){ true }
  let(:env) {{
    ui: Vagrant::UI::Silent.new,
    home_path: home_path,
    gems_path: gems_path,
    force: force
  }}

  let(:manager) { double("manager") }

  let(:expect_to_receive) do
    lambda do
      allow(File).to receive(:exist?).with(File.join(home_path, 'plugins.json')).and_return(true)
      allow(File).to receive(:directory?).with(gems_path).and_return(true)
      expect(FileUtils).to receive(:rm).with(File.join(home_path, 'plugins.json'))
      expect(FileUtils).to receive(:rm_rf).with(gems_path)
      expect(app).to receive(:call).with(env).once
    end
  end

  subject { described_class.new(app, env) }

  before do
    allow(Vagrant::Plugin::Manager).to receive(:instance).and_return(manager)
  end

  describe "#call" do
    before do
      instance_exec(&expect_to_receive)
    end

    it "should delete all plugins" do
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
  end
end
