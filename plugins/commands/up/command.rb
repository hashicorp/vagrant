require 'optparse'

require "vagrant"

require File.expand_path("../start_mixins", __FILE__)

module VagrantPlugins
  module CommandUp
    class Command < Vagrant.plugin("2", :command)
      include StartMixins

      def execute
        options = {}
        options[:parallel] = true

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant up [vm-name] [options] [-h]"
          o.separator ""

          build_start_options(o, options)

          o.on("--[no-]parallel",
               "Enable or disable parallelism if provider supports it.") do |parallel|
            options[:parallel] = parallel
          end

          o.on("--provider provider", String,
               "Back the machine with a specific provider.") do |provider|
            options[:provider] = provider
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Go over each VM and bring it up
        @logger.debug("'Up' each target VM...")

        # Build up the batch job of what we'll do
        @env.batch(options[:parallel]) do |batch|
          with_target_vms(argv, :provider => options[:provider]) do |machine|
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
