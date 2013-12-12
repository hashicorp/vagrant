# coding: utf-8
module VagrantPlugins
  module CommandSnapshot
    module Command
      # This is the root command 'vagrant snapshot' which delegates out work to
      # the subcommands here within.
      class Root < Vagrant.plugin('2', :command)
        def self.synopsis
          'manages snapshots: creation, deletion, etc.'
        end

        def initialize(argv, argc)
          super

          @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)

          @subcommands = Vagrant::Registry.new
          @subcommands.register(:list) do
            require_relative 'list'
            List
          end

          @subcommands.register(:create) do
            require_relative 'create'
            Create
          end

          @subcommands.register(:delete) do
            require_relative 'delete'
            Delete
          end

          @subcommands.register(:restore) do
            require_relative 'restore'
            Restore
          end
        end

        def execute
          # Print the help for all of the subcommands
          return help if @main_args.include?('-h') || @main_args.include?('--help')

          # At this point we have a subcommand that needs to be parsed and
          # dispatched. Use the registry that was built on initialization.
          command_klass = @subcommands.get(@sub_command.to_sym) if @sub_command
          return help unless command_klass
          @logger.debug("Invoking command class: #{command_klass} with #{@sub_args.inspect}")
          
          command_klass.new(@sub_args, @env).execute
        end

        def help
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant snapshot <command> [<args>]'
            o.separator ''
            o.separator 'Available subcommands:'

            # TODO: Remove once PR #2637 is approved/merged.
            #@subcommands.keys.sort.each { |k| o.separator "     #{k}" }
            keys = []
            @subcommands.each { |k,v| keys << k }
            keys.sort.each { |k| o.separator "     #{k}" }

            o.separator ''
            o.separator 'For help on any individual command run `vagrant snapshot COMMAND -h`'
          end

          @env.ui.info(opts.help, prefix: false)
        end
      end
    end
  end
end
