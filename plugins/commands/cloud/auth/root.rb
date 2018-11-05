module VagrantPlugins
  module CloudCommand
    module AuthCommand
      module Command
        class Root < Vagrant.plugin("2", :command)
          def self.synopsis
            "Manages Vagrant Cloud authorization related to Vagrant Cloud"
          end

          def initialize(argv, env)
            super

            @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
            @subcommands = Vagrant::Registry.new
            @subcommands.register(:login) do
              require File.expand_path("../login", __FILE__)
              Command::Login
            end
            @subcommands.register(:logout) do
              require File.expand_path("../logout", __FILE__)
              Command::Logout
            end
            @subcommands.register(:whoami) do
              require File.expand_path("../whoami", __FILE__)
              Command::Whoami
            end
          end

          def execute
            if @main_args.include?("-h") || @main_args.include?("--help")
              # Print the help for all the box commands.
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
              opts.banner = "Usage: vagrant cloud auth <subcommand> [<args>]"
              opts.separator ""
              opts.separator "Authorization with Vagrant Cloud"
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
              opts.separator "For help on any individual subcommand run `vagrant cloud auth <subcommand> -h`"
            end

            @env.ui.info(opts.help, prefix: false)
          end
        end
      end
    end
  end
end
