require 'optparse'

module VagrantPlugins
  module CommandCap
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "checks and executes capability"
      end

      def execute
        options = {}
        options[:check] = false

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant cap [options] TYPE NAME [args]"
          o.separator ""
          o.separator "This is an advanced command. If you don't know what this"
          o.separator "does and you aren't explicitly trying to use it, you probably"
          o.separator "don't want to use this."
          o.separator ""
          o.separator "This command checks or executes arbitrary capabilities that"
          o.separator "Vagrant has for hosts, guests, and providers."
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--check", "Only checks for a capability, does not execute") do |f|
            options[:check] = f
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv
        if argv.length < 2
          raise Vagrant::Errors::CLIInvalidUsage,
            help: opts.help.chomp
        end

        type = argv.shift.to_sym
        name = argv.shift.to_sym

        # Get the proper capability host to check
        cap_host = nil
        if type == :host
          cap_host = @env.host
        else
          with_target_vms([]) do |vm|
            cap_host = case type
                       when :provider
                         vm.provider
                       when :guest
                         vm.guest
                       else
                         raise Vagrant::Errors::CLIInvalidUsage,
                           help: opts.help.chomp
                       end
          end
        end

        # If we're just checking, then just return exit codes
        if options[:check]
          return 0 if cap_host.capability?(name)
          return 1
        end

        # Otherwise, call it
        cap_host.capability(name, *argv)

        # Success, exit status 0
        0
      end
    end
  end
end
