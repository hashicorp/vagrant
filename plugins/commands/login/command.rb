require 'socket'

module VagrantPlugins
  module LoginCommand
    class Command < Vagrant.plugin("2", "command")
      def self.synopsis
        "log in to HashiCorp's Vagrant Cloud"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant login"
          o.separator ""
          o.on("-c", "--check", "Only checks if you're logged in") do |c|
            options[:check] = c
          end

          o.on("-d", "--description DESCRIPTION", String, "Description for the Vagrant Cloud token") do |t|
            options[:description] = t
          end

          o.on("-k", "--logout", "Logs you out if you're logged in") do |k|
            options[:logout] = k
          end

          o.on("-t", "--token TOKEN", String, "Set the Vagrant Cloud token") do |t|
            options[:token] = t
          end

          o.on("-u", "--username USERNAME_OR_EMAIL", String, "Specify your Vagrant Cloud username or email address") do |t|
            options[:login] = t
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @client = Client.new(@env)
        @client.username_or_email = options[:login]

        # Determine what task we're actually taking based on flags
        if options[:check]
          return execute_check
        elsif options[:logout]
          return execute_logout
        elsif options[:token]
          return execute_token(options[:token])
        end

        # Let the user know what is going on.
        @env.ui.output(I18n.t("login_command.command_header") + "\n")

        # If it is a private cloud installation, show that
        if Vagrant.server_url != Vagrant::DEFAULT_SERVER_URL
          @env.ui.output("Vagrant Cloud URL: #{Vagrant.server_url}")
        end

        # Ask for the username
        if @client.username_or_email
          @env.ui.output("Vagrant Cloud username or email: #{@client.username_or_email}")
        end
        until @client.username_or_email
          @client.username_or_email = @env.ui.ask("Vagrant Cloud username or email: ")
        end

        until @client.password
          @client.password = @env.ui.ask("Password (will be hidden): ", echo: false)
        end

        description = options[:description]
        if description
          @env.ui.output("Token description: #{description}")
        else
          description_default = "Vagrant login from #{Socket.gethostname}"
          until description
            description =
              @env.ui.ask("Token description (Defaults to #{description_default.inspect}): ")
          end
          description = description_default if description.empty?
        end

        code = nil

        begin
          token = @client.login(description: description, code: code)
        rescue Errors::TwoFactorRequired
          until code
            code = @env.ui.ask("2FA code: ")

            if @client.two_factor_delivery_methods.include?(code.downcase)
              delivery_method, code = code, nil
              @client.request_code delivery_method
            end
          end

          retry
        end

        @client.store_token(token)
        @env.ui.success(I18n.t("login_command.logged_in"))
        0
      end

      def execute_check
        if @client.logged_in?
          @env.ui.success(I18n.t("login_command.check_logged_in"))
          return 0
        else
          @env.ui.error(I18n.t("login_command.check_not_logged_in"))
          return 1
        end
      end

      def execute_logout
        @client.clear_token
        @env.ui.success(I18n.t("login_command.logged_out"))
        return 0
      end

      def execute_token(token)
        @client.store_token(token)
        @env.ui.success(I18n.t("login_command.token_saved"))

        if @client.logged_in?
          @env.ui.success(I18n.t("login_command.check_logged_in"))
          return 0
        else
          @env.ui.error(I18n.t("login_command.invalid_token"))
          return 1
        end
      end
    end
  end
end
