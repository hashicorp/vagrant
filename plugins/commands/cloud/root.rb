module VagrantPlugins
  module CloudCommand
    module Command
      class Root < Vagrant.plugin("2", :command)
        def self.synopsis
          "manages everything related to Vagrant Cloud"
        end

        def initialize(argv, env)
          super

          @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
          @subcommands = Vagrant::Registry.new
          @subcommand_helptext = {}

          @subcommands.register(:auth) do
            require File.expand_path("../auth/root", __FILE__)
            AuthCommand::Command::Root
          end
          @subcommand_helptext[:auth] = "For various authorization operations on Vagrant Cloud"

          @subcommands.register(:box) do
            require File.expand_path("../box/root", __FILE__)
            BoxCommand::Command::Root
          end
          @subcommand_helptext[:box] = "For managing a Vagrant box entry on Vagrant Cloud"

          # TODO: Uncomment this when API endpoint exists
          #@subcommands.register(:list) do
          #  require File.expand_path("../list", __FILE__)
          #  List
          #end
          #@subcommand_helptext[:list] = "Displays a list of Vagrant boxes that the current user manages"

          @subcommands.register(:search) do
            require File.expand_path("../search", __FILE__)
            Search
          end
          @subcommand_helptext[:search] = "Search Vagrant Cloud for available boxes"

          @subcommands.register(:provider) do
            require File.expand_path("../provider/root", __FILE__)
            ProviderCommand::Command::Root
          end
          @subcommand_helptext[:provider] = "For managing a Vagrant box's provider options"

          @subcommands.register(:publish) do
            require File.expand_path("../publish", __FILE__)
            Publish
          end
          @subcommand_helptext[:publish] = "A complete solution for creating or updating a new box on Vagrant Cloud"

          @subcommands.register(:version) do
            require File.expand_path("../version/root", __FILE__)
            VersionCommand::Command::Root
          end
          @subcommand_helptext[:version] = "For managing a Vagrant box's versions"
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
            opts.banner = "Usage: vagrant cloud <subcommand> [<args>]"
            opts.separator ""
            opts.separator "The cloud command can be used for taking actions against"
            opts.separator "Vagrant Cloud like searching or uploading a Vagrant Box"
            opts.separator ""
            opts.separator "Available subcommands:"

            # Add the available subcommands as separators in order to print them
            # out as well.
            keys = []
            @subcommands.each { |key, value| keys << key.to_s }

            keys.sort.each do |key|
              opts.separator "     #{key.ljust(15)} #{@subcommand_helptext[key.to_sym]}"
            end

            opts.separator ""
            opts.separator "For help on any individual subcommand run `vagrant cloud <subcommand> -h`"
          end

          @env.ui.info(opts.help, prefix: false)
        end
      end
    end
  end
end
