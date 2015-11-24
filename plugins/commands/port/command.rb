require "optparse"

module VagrantPlugins
  module CommandPort
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "displays information about guest port mappings"
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant port [options] [name]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--machine-readable", "Display machine-readable output")
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("Port command: #{argv.inspect}")
        with_target_vms(argv, single_target: true) do |vm|
          vm.action_raw(:config_validate,
            Vagrant::Action::Builtin::ConfigValidate)

          if vm.state.id != :running
            @env.ui.error "not running - make this a better error or use the middleware"
            return 1
          end

          # This only works for vbox? should it be everywhere?
          # vm.action_raw(:check_running,
          #   Vagrant::Action::Builtin::CheckRunning)

          if !vm.provider.capability?(:forwarded_ports)
            @env.ui.error(I18n.t("port_command.missing_capability",
              provider: vm.provider_name,
            ))
            return 1
          end

          ports = vm.provider.capability(:forwarded_ports)

          if ports.empty?
            @env.ui.info(I18n.t("port_command.empty_ports"))
            return 0
          end

          @env.ui.info(I18n.t("port_command.details"))
          @env.ui.info("")
          ports.each do |guest, host|
            @env.ui.info("#{guest.to_s.rjust(6)} (guest) => #{host} (host)")
            @env.ui.machine("forwarded_port", guest, host, target: vm.name.to_s)
          end
        end

        0
      end
    end
  end
end
