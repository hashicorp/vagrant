module VagrantPlugins
  module CloudCommand
    module VersionCommand
      module Command
        class Root < Vagrant.plugin("2", :command)
          def self.synopsis
            "Version commands"
          end

          def initialize(argv, env)
            super

            @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
            @subcommands = Vagrant::Registry.new
            @subcommands.register(:create) do
              require File.expand_path("../create", __FILE__)
              Command::Create
            end
            @subcommands.register(:delete) do
              require File.expand_path("../delete", __FILE__)
              Command::Delete
            end
            @subcommands.register(:revoke) do
              require File.expand_path("../revoke", __FILE__)
              Command::Revoke
            end
            @subcommands.register(:release) do
              require File.expand_path("../release", __FILE__)
              Command::Release
            end
            @subcommands.register(:update) do
              require File.expand_path("../update", __FILE__)
              Command::Update
            end
          end

          def execute
            if @main_args.include?("-h") || @main_args.include?("--help")
              # Print the help for all the version commands.
              return help
            end

            # If we reached this far then we must have a subcommand. If not,
            # then we also just print the help and exit.
            command_class = @subcommands.get(@sub_command.to_sym) if @sub_command
            return help if !command_class || !@sub_command
            @logger.debug("Invoking command class: #{command_class} #{@sub_args.inspect}")

            # Initialize and execute the command class
            command_class.new(@sub_args, @env).execute
          end

          # Prints the help out for this command
          def help
            opts = OptionParser.new do |opts|
              opts.banner = "Usage: vagrant cloud version <subcommand> [<args>]"
              opts.separator ""
              opts.separator "For taking various actions against a Vagrant box's version attribute on Vagrant Cloud"
              opts.separator ""
              opts.separator "Available subcommands:"

              # Add the available subcommands as separators in order to print them
              # out as well.
              keys = []
              @subcommands.each { |key, value| keys << key.to_s }

              keys.sort.each do |key|
                opts.separator "     #{key}"
              end

              opts.separator ""
              opts.separator "For help on any individual subcommand run `vagrant cloud version <subcommand> -h`"
            end

            @env.ui.info(opts.help, prefix: false)
          end
        end
      end
    end
  end
end
