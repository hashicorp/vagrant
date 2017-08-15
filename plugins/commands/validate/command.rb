require 'optparse'

module VagrantPlugins
  module CommandValidate
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "validates the Vagrantfile"
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant validate"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Validate the configuration of all machines
        with_target_vms() do |machine|
          machine.action_raw(:config_validate, Vagrant::Action::Builtin::ConfigValidate)
        end

        @env.ui.info(I18n.t("vagrant.commands.validate.success"))

        # Success, exit status 0
        0
      end
    end
  end
end
