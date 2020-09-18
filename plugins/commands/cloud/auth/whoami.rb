require 'optparse'

module VagrantPlugins
  module CloudCommand
    module AuthCommand
      module Command
        class Whoami < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud auth whoami [token]"
              o.separator ""
              o.separator "Display currently logged in user"
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.size > 1
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            if argv.first
              token = argv.first
            else
              client = Client.new(@env)
              token = client.token
            end

            whoami(token)
          end

          def whoami(access_token)
            if access_token.to_s.empty?
              @env.ui.error(I18n.t("cloud_command.check_not_logged_in"))
              return 1
            end
            begin
              account = VagrantCloud::Account.new(
                custom_server: api_server_url,
                access_token: access_token
              )
              @env.ui.success("Currently logged in as #{account.username}")
              return 0
            rescue VagrantCloud::Error::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.whoami.read_error"))
              @env.ui.error(e)
              return 1
            end
            return 1
          end
        end
      end
    end
  end
end
