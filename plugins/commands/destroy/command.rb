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
               "Enable or disable parallelism if provider supports it") do |p|
            options[:parallel] = p
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'Destroy' each target VM...")

        if options[:parallel]
          options[:force] = true
        end

        machines = []

        @env.batch(options[:parallel]) do |batch|
          with_target_vms(argv, reverse: true) do |vm|
            machines << vm
            batch.action(vm, :destroy, force_confirm_destroy: options[:force])
          end
        end

        states = machines.map { |m| m.state.id }
        if states.uniq.length == 1 && states.first == :not_created
          # Nothing was declined
          return 0
        elsif states.uniq.length == 1 && states.first != :not_created
          # Everything was declined
          return 1
        else
          # Some was declined
          return 2
        end
      end
    end
  end
end
