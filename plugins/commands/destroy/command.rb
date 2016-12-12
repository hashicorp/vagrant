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

          o.on("--[no-]parallel",
               "Enable or disable parallelism if provider supports it") do |parallel|
            options[:parallel] = parallel
          end

          o.on("-f", "--force", "Destroy without confirmation.") do |f|
            options[:force] = f
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'Destroy' each target VM...")

        # Get the names of the machines we want to bring up
        names = argv
        if names.empty?
          autostart = false
          @env.vagrantfile.machine_names_and_options.each do |n, o|
            autostart = true if o.key?(:autostart)
            o[:autostart] = true if !o.key?(:autostart)
            names << n.to_s if o[:autostart]
          end

          # If we have an autostart key but no names, it means that
          # all machines are autostart: false and we don't start anything.
          names = nil if autostart && names.empty?
        end

        # Build up the batch job of what we'll do
        machines = []
        if names
          # If we're installing providers, then do that. We don't
          # parallelize this step because it is likely the same provider
          # anyways.
          if options[:install_provider]
            install_providers(names, provider: options[:provider])
          end

          @env.batch(options[:parallel]) do |batch|
            with_target_vms(names, reverse: true, provider: options[:provider]) do |machine|
              @env.ui.info(I18n.t(
                "vagrant.commands.destroy.destroying",
                name: machine.name,
                provider: machine.provider_name))

              machines << machine

              batch.action(machine, :destroy, force_confirm_destroy: options[:force])
            end
          end
        end

        if machines.empty?
          @env.ui.info(I18n.t("vagrant.destroy_no_machines"))
          return 0
        end

        # Output the post-up messages that we have, if any
        machines.each do |m|
          next if !m.config.vm.post_destroy_message
          next if m.config.vm.post_destroy_message == ""

          # Add a newline to separate things.
          @env.ui.info("", prefix: false)

          m.ui.success(I18n.t(
            "vagrant.post_destroy_message",
            name: m.name.to_s,
            message: m.config.vm.post_destroy_message))
        end

        return 0
      end
    end
  end
end
