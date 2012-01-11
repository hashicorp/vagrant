require 'optparse'

module Vagrant
  module Command
    class Up < Base
      def execute
        options = {
          :provision => true,
          :provisioners => nil
        }

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant up [vm-name] [--[no-]provision] [-h]"

          opts.separator ""

          opts.on("--[no-]provision", "Enable or disable provisioning") do |p|
            options[:provision] = p
          end

          opts.on("--provision-with x,y,z", Array,
                  "Enable only certain provisioners, by type.") do |list|
            options[:provisioners] = list
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Parameters to send to actions
        action_params = {
          "provision.enabled" => options[:provision],
          "provision.types"   => options[:provisioners]
        }

        # Go over each VM and bring it up
        @logger.debug("'Up' each target VM...")
        with_target_vms(argv[0]) do |vm|
          if vm.created?
            @logger.info("Booting: #{vm.name}")
            vm.ui.info I18n.t("vagrant.commands.up.vm_created")
            vm.start(action_params)
          else
            @logger.info("Creating: #{vm.name}")
            vm.up(action_params)
          end
        end
      end
    end
  end
end
