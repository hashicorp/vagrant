require 'optparse'

module VagrantPlugins
  module CommandValidate
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "validates the Vagrantfile"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant validate [options]"
          o.separator ""
          o.separator "Validates a Vagrantfile config"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("-p", "--ignore-provider", "Ignores provider config options") do |p|
            options[:ignore_provider] = p
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        action_env = {}
        if options[:ignore_provider]
          action_env[:ignore_provider] = true
        end
        # Validate the configuration of all machines
        with_target_vms() do |machine|
          machine.action_raw(:config_validate, Vagrant::Action::Builtin::ConfigValidate, action_env)
        end

        @env.ui.info(I18n.t("vagrant.commands.validate.success"))

        # Success, exit status 0
        0
      end
    end
  end
end
