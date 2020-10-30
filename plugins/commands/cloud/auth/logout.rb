require 'optparse'

module VagrantPlugins
  module CloudCommand
    module AuthCommand
      module Command
        class Logout < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud auth logout"
              o.separator ""
              o.separator "Log out of Vagrant Cloud"
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if !argv.empty?
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = Client.new(@env)
            @client.clear_token
            @env.ui.success(I18n.t("cloud_command.logged_out"))
            return 0
          end
        end
      end
    end
  end
end
