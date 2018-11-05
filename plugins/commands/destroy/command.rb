module VagrantPlugins
  module CommandDestroy
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "stops and deletes all traces of the vagrant machine"
      end

      def execute
        options = {}
        options[:force] = false

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant destroy [options] [name|id]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("-f", "--force", "Destroy without confirmation.") do |f|
            options[:force] = f
          end

          o.on("--[no-]parallel",
               "Enable or disable parallelism if provider supports it (automatically enables force)") do |p|
            options[:parallel] = p
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        if options[:parallel] && !options[:force]
          @env.ui.warn(I18n.t("vagrant.commands.destroy.warning"))
          sleep(5)
          options[:force] = true
        end

        @logger.debug("'Destroy' each target VM...")

        machines = []
        init_states = {}
        declined = 0

        @env.batch(options[:parallel]) do |batch|
          with_target_vms(argv, reverse: true) do |vm|
            # gather states to be checked after destroy
            init_states[vm.name] = vm.state.id
            machines << vm

            batch.action(vm, :destroy, force_confirm_destroy: options[:force])
          end
        end

        machines.each do |m|
          if m.state.id == init_states[m.name]
            declined += 1
          end
        end

        # Nothing was declined
        return 0 if declined == 0

        # Everything was declined, and all states are `not_created`
        return 0 if declined == machines.length &&
                    declined == init_states.values.count(:not_created)

        # Everything was declined, state was not changed
        return 1 if declined == machines.length

        # Some was declined
        return 2
      end
    end
  end
end
