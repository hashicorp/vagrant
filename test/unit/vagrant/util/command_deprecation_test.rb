require File.expand_path("../../../base", __FILE__)

require "vagrant/util/command_deprecation"

describe Vagrant::Util do
  include_context "unit"

  let(:app){ lambda{|env|} }
  let(:argv){[]}
  let(:env){ {ui: Vagrant::UI::Silent.new} }

  let(:command_class) do
    Class.new(Vagrant.plugin("2", :command)) do
      def self.synopsis
        "base synopsis"
      end
      def self.name
        "VagrantPlugins::CommandTest::Command"
      end
      def execute
        @env[:ui].info("COMMAND CONTENT")
        0
      end
    end
  end

  let(:command){ command_class.new(app, env) }

  describe Vagrant::Util::CommandDeprecation do
    before{ command_class.include(Vagrant::Util::CommandDeprecation) }

    it "should add deprecation warning to synopsis" do
      expect(command_class.synopsis).to include('[DEPRECATED]')
      command.class.synopsis
    end

    it "should add deprecation warning to #execute" do
      expect(env[:ui]).to receive(:warn).with(/DEPRECATION WARNING/)
      command.execute
    end

    it "should execute original command" do
      expect(env[:ui]).to receive(:info).with("COMMAND CONTENT")
      command.execute
    end

    it "should return with a 0 value" do
      expect(command.execute).to eq(0)
    end

    context "with custom name defined" do
      before do
        command_class.class_eval do
          def deprecation_command_name
            "custom-name"
          end
        end
      end

      it "should use custom name within warning message" do
        expect(env[:ui]).to receive(:warn).with(/custom-name/)
        command.execute
      end
    end

    context "with deprecated subcommand" do
      let(:command_class) do
        Class.new(Vagrant.plugin("2", :command)) do
          def self.name
            "VagrantPlugins::CommandTest::Command::Action"
          end
          def execute
            @env[:ui].info("COMMAND CONTENT")
            0
          end
        end
      end

      it "should not modify empty synopsis" do
        expect(command_class.synopsis.to_s).to be_empty
      end

      it "should extract command name and subname" do
        expect(command.deprecation_command_name).to eq("test action")
      end
    end
  end

  describe Vagrant::Util::CommandDeprecation::Complete do
    before{ command_class.include(Vagrant::Util::CommandDeprecation::Complete) }

    it "should add deprecation warning to synopsis" do
      expect(command_class.synopsis).to include('[DEPRECATED]')
      command.class.synopsis
    end

    it "should raise a deprecation error when executed" do
      expect{ command.execute }.to raise_error(Vagrant::Errors::CommandDeprecated)
    end

    it "should not run original command" do
      expect(env[:ui]).not_to receive(:info).with("COMMAND CONTENT")
      expect{ command.execute }.to raise_error(Vagrant::Errors::CommandDeprecated)
    end
  end
end
