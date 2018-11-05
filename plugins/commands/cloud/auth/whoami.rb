require 'optparse'

module VagrantPlugins
  module CloudCommand
    module AuthCommand
      module Command
        class Whoami < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud auth whoami [options] [token]"
              o.separator ""
              o.separator "Display currently logged in user"
              o.separator ""
              o.separator "Options:"
              o.separator ""
              o.on("-u", "--username USERNAME_OR_EMAIL", String, "Vagrant Cloud username or email address") do |l|
                options[:login] = l
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.size > 1
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:login])

            if argv.first
              token = argv.first
            else
              token = @client.token
            end

            whoami(token, options[:username])
          end

          def whoami(access_token, username)
            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(username, access_token, server_url)

            begin
              success = account.validate_token
              user = success["user"]["username"]
              @env.ui.success("Currently logged in as #{user}")
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.whoami.read_error", org: username))
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
