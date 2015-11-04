require 'optparse'

module VagrantPlugins
  module CommandProvider
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "show provider for this environment"
      end

      def execute
        options = {}
        options[:install] = false
        options[:usable] = false

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant provider [options] [args]"
          o.separator ""
          o.separator "This command interacts with the provider for this environment."
          o.separator "With no arguments, it'll output the default provider for this"
          o.separator "environment."
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--install", "Installs the provider if possible") do |f|
            options[:install] = f
          end

          o.on("--usable", "Checks if the named provider is usable") do |f|
            options[:usable] = f
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Get the machine
        machine = nil
        with_target_vms(argv, single_target: true) do |m|
          machine = m
        end

        # Output some machine readable stuff
        @env.ui.machine("provider-name", machine.provider_name, target: machine.name.to_s)

        # Check if we're just doing a usability check
        if options[:usable]
          @env.ui.output(machine.provider_name.to_s)
          return 0 if machine.provider.class.usable?(false)
          return 1
        end

        # Check if we're requesting installation
        if options[:install]
          key = "provider_install_#{machine.provider_name}".to_sym
          if !@env.host.capability?(key)
            raise Vagrant::Errors::ProviderCantInstall,
              provider: machine.provider_name.to_s
          end

          @env.host.capability(key)
          return
        end

        # No subtask, just output the provider name
        @env.ui.output(machine.provider_name.to_s)

        # Success, exit status 0
        0
      end
    end
  end
end
