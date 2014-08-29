require 'optparse'

module VagrantPlugins
  module CommandProvision
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "provisions the vagrant machine"
      end

      def execute
        options = {}
        options[:provision_types] = nil

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant provision [vm-name] [--provision-with x,y,z]"

          o.on("--provision-with x,y,z", Array,
                    "Enable only certain provisioners, by type.") do |list|
            options[:provision_types] = list.map { |type| type.to_sym }
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Go over each VM and provision!
        @logger.debug("'provision' each target VM...")
        with_target_vms(argv) do |machine|
          machine.action(:provision, options)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
