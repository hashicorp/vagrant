require 'optparse'

module Vagrant
  module Command
    class Destroy < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant destroy [vm-name]"
          opts.separator ""

          opts.on("-f", "--force", "Destroy without confirmation.") do |f|
            options[:force] = f
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'Destroy' each target VM...")
        with_target_vms(argv[0], :reverse => true) do |vm|
          if vm.created?
            # Boolean whether we should actually go through with the destroy
            # or not. This is true only if the "--force" flag is set or if the
            # user confirms it.
            do_destroy = false

            if options[:force]
              do_destroy = true
            else
              choice = @env.ui.ask(I18n.t("vagrant.commands.destroy.confirmation",
                                          :name => vm.name))
              do_destroy = choice.upcase == "Y"
            end

            if do_destroy
              @logger.info("Destroying: #{vm.name}")
              vm.destroy
            else
              @logger.info("Not destroying #{vm.name} since confirmation was declined.")
              @env.ui.success(I18n.t("vagrant.commands.destroy.will_not_destroy",
                                     :name => vm.name), :prefix => false)
            end
          else
            @logger.info("Not destroying #{vm.name}, since it isn't created.")
            vm.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end
      end
    end
  end
end
