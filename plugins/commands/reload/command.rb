require 'optparse'

require "vagrant"

require Vagrant.source_root.join("plugins/commands/up/start_mixins")

# Needed for the "--destroy" option
require Vagrant.source_root.join("plugins/commands/destroy/command")
require Vagrant.source_root.join("plugins/commands/up/command")

module VagrantPlugins
  module CommandReload
    class Command < Vagrant.plugin("2", :command)
      # We assume that the `up` plugin exists and that we'll have access
      # to this.
      include VagrantPlugins::CommandUp::StartMixins

      def self.synopsis
        "restarts vagrant machine, loads new Vagrantfile configuration"
      end

      def execute
        options = {}
        options[:provision_ignore_sentinel] = false
        options[:destroy] = false

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant reload [vm-name]"
          o.separator ""

          o.on("--destroy", "Shorthand for `vagrant destroy --force & vagrant up`") do |f|
            options[:destroy] = f
          end

          build_start_options(o, options)
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Validate the provisioners
        validate_provisioner_flags!(options, argv)

        if options[:destroy]
          # Call 'vagrant destroy --force'
          VagrantPlugins::CommandDestroy::Command.new(['--force'], @env).execute

          # Call 'vagrant up'
          VagrantPlugins::CommandUp::Command.new([], @env).execute
        else
          @logger.debug("'reload' each target VM...")
          machines = []
          with_target_vms(argv) do |machine|
            machines << machine
            machine.action(:reload, options)
          end

          # Output the post-up messages that we have, if any
          machines.each do |m|
            next if !m.config.vm.post_up_message
            next if m.config.vm.post_up_message == ""

            # Add a newline to separate things.
            @env.ui.info("", prefix: false)

            m.ui.success(I18n.t(
              "vagrant.post_up_message",
              name: m.name.to_s,
              message: m.config.vm.post_up_message))
          end
        end
        # Success, exit status 0
        0
      end
    end
  end
end
