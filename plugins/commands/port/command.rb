require "vagrant/util/presence"

require "optparse"

module VagrantPlugins
  module CommandPort
    class Command < Vagrant.plugin("2", :command)
      include Vagrant::Util::Presence

      def self.synopsis
        "displays information about guest port mappings"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant port [options] [name|id]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--guest PORT", "Output the host port that maps to the given guest port") do |port|
            options[:guest] = port
          end

          o.on("--machine-readable", "Display machine-readable output")
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        with_target_vms(argv, single_target: true) do |vm|
          vm.action_raw(:config_validate,
            Vagrant::Action::Builtin::ConfigValidate)

          if !vm.provider.capability?(:forwarded_ports)
            @env.ui.error(I18n.t("port_command.missing_capability",
              provider: vm.provider_name,
            ))
            return 1
          end

          ports = vm.provider.capability(:forwarded_ports)

          if !present?(ports)
            @env.ui.info(I18n.t("port_command.empty_ports"))
            return 0
          end

          if present?(options[:guest])
            return print_single(vm, ports, options[:guest])
          else
            return print_all(vm, ports)
          end
        end
      end

      private

      # Print all the guest <=> host port mappings.
      # @return [0] the exit code
      def print_all(vm, ports)
        @env.ui.info(I18n.t("port_command.details"))
        @env.ui.info("")
        ports.each do |host, guest|
          @env.ui.info("#{guest.to_s.rjust(6)} (guest) => #{host} (host)")
          @env.ui.machine("forwarded_port", guest, host, target: vm.name.to_s)
        end
        return 0
      end

      # Print the host mapping that matches the given guest target.
      # @return [0,1] the exit code
      def print_single(vm, ports, target)
        map = ports.find { |_, guest| "#{guest}" == "#{target}" }
        if !present?(map)
          @env.ui.error(I18n.t("port_command.no_matching_port",
            port: target,
          ))
          return 1
        end

        @env.ui.info("#{map[0]}")
        return 0
      end
    end
  end
end
