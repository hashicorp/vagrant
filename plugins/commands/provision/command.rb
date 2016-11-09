require 'optparse'

module VagrantPlugins
  module CommandProvision
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "provisions the vagrant machine"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant provision [vm-name] [--provision-with x,y,z]"

          o.on("--provision-with x,y,z", Array,
                    "Enable only certain provisioners, by type or by name.") do |list|
            options[:provision_types] = list.map { |type| type.to_sym }
          end

          o.on("--up", "Automatically transition VM to 'up' state") do |value|
            options[:auto_up] = value
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Go over each VM and provision!
        @logger.debug("'provision' each target VM...")
        with_target_vms(argv) do |machine|
          if options[:auto_up] && machine.state.id != :running
            @logger.debug("current machine state `#{machine.state.id}`. Attempting to bring up.")
            case machine.state.id
            when :not_created, :poweroff
              machine.action(:up)
            when :paused, :saved
              machine.action(:resume)
            else
              raise Vagrant::Errors::ProvisionAutoUpFailure.new(
                machine_name: machine.name,
                machine_state: machine.state.short_description
              )
            end
          end
          machine.action(:provision, options)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
