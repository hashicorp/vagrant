require 'optparse'

module VagrantPlugins
  module CloudCommand
    module AuthCommand
      module Command
        class Login < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud auth login [options]"
              o.separator ""
              o.separator "Options:"
              o.separator ""
              o.on("-c", "--check", "Checks if currently logged in") do |c|
                options[:check] = c
              end
              o.on("-d", "--description DESCRIPTION", String, "Set description for the Vagrant Cloud token") do |d|
                options[:description] = d
              end

              o.on("-t", "--token TOKEN", String, "Set the Vagrant Cloud token") do |t|
                options[:token] = t
              end

              o.on("-u", "--username USERNAME_OR_EMAIL", String, "Vagrant Cloud username or email address") do |l|
                options[:login] = l
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if !argv.empty?
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            client = Client.new(@env)
            client.username_or_email = options[:login]

            # Determine what task we're actually taking based on flags
            if options[:check]
              return execute_check(client)
            elsif options[:token]
              return execute_token(client, options[:token])
            else
              if client.logged_in?
                @env.ui.success(I18n.t("cloud_command.check_logged_in"))
              else
                client_login(@env, options.slice(:login, :description))
              end
            end

            0
          end

          def execute_check(client)
            if client.logged_in?
              @env.ui.success(I18n.t("cloud_command.check_logged_in"))
              return 0
            else
              @env.ui.error(I18n.t("cloud_command.check_not_logged_in"))
              return 1
            end
          end

          def execute_token(client, token)
            client.store_token(token)
            @env.ui.success(I18n.t("cloud_command.token_saved"))

            if client.logged_in?
              @env.ui.success(I18n.t("cloud_command.check_logged_in"))
              return 0
            else
              @env.ui.error(I18n.t("cloud_command.invalid_token"))
              return 1
            end
          end
        end
      end
    end
  end
end
