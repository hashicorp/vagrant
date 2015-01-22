module VagrantPlugins
  module LoginCommand
    class Command < Vagrant.plugin("2", "command")
      def self.synopsis
        "log in to HashiCorp's Atlas"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant login"
          o.separator ""
          o.on("-c", "--check", "Only checks if you're logged in") do |c|
            options[:check] = c
          end

          o.on("-k", "--logout", "Logs you out if you're logged in") do |k|
            options[:logout] = k
          end

          o.on("-t", "--token TOKEN", String, "Set the Atlas token") do |t|
            options[:token] = t
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @client = Client.new(@env)

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
          @env.ui.output("Atlas URL: #{Vagrant.server_url}")
        end

        # Ask for the username
        login    = nil
        password = nil
        while !login
          login = @env.ui.ask("Atlas Username: ")
        end

        while !password
          password = @env.ui.ask("Password (will be hidden): ", echo: false)
        end

        token = @client.login(login, password)
        if !token
          @env.ui.error(I18n.t("login_command.invalid_login"))
          return 1
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
