require 'optparse'

require "vagrant"

require File.expand_path("../start_mixins", __FILE__)

module VagrantPlugins
  module CommandUp
    class Command < Vagrant.plugin("2", :command)
      include StartMixins

      def self.synopsis
        "starts and provisions the vagrant environment"
      end

      def execute
        options = {}
        options[:destroy_on_error] = true
        options[:parallel] = true
        options[:provision_ignore_sentinel] = false

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant up [options] [name]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          build_start_options(o, options)

          o.on("--[no-]destroy-on-error",
               "Destroy machine if any fatal error happens (default to true)") do |destroy|
            options[:destroy_on_error] = destroy
          end

          o.on("--[no-]parallel",
               "Enable or disable parallelism if provider supports it") do |parallel|
            options[:parallel] = parallel
          end

          o.on("--provider PROVIDER", String,
               "Back the machine with a specific provider") do |provider|
            options[:provider] = provider
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Validate the provisioners
        validate_provisioner_flags!(options)

        # Go over each VM and bring it up
        @logger.debug("'Up' each target VM...")

        # Build up the batch job of what we'll do
        @env.batch(options[:parallel]) do |batch|
          names = argv
          if names.empty? then
            names = @env.autostart_machine_names
          end
          with_target_vms(names, :provider => options[:provider]) do |machine|
            @env.ui.info(I18n.t(
              "vagrant.commands.up.upping",
              :name => machine.name,
              :provider => machine.provider_name))

            batch.action(machine, :up, options)
          end
        end

        # Success, exit status 0
        0
      end
    end
  end
end
