require "vagrant_cloud"
require "vagrant/util/downloader"
require "vagrant/util/presence"
require Vagrant.source_root.join("plugins/commands/cloud/errors")

module VagrantPlugins
  module CloudCommand
    class Client
      # @private
      # Reset the cached values for scrubber. This is not considered a public
      # API and should only be used for testing.
      def self.reset!
        class_variables.each(&method(:remove_class_variable))
      end

      ######################################################################
      # Class that deals with managing users 'local' token for Vagrant Cloud
      ######################################################################
      APP = "app".freeze

      include Vagrant::Util::Presence

      attr_accessor :client
      attr_accessor :username_or_email
      attr_accessor :password
      attr_reader :two_factor_default_delivery_method
      attr_reader :two_factor_delivery_methods

      # Initializes a login client with the given Vagrant::Environment.
      #
      # @param [Vagrant::Environment] env
      def initialize(env)
        @logger = Log4r::Logger.new("vagrant::cloud::client")
        @env    = env
        @client = VagrantCloud::Client.new(access_token: token)
      end

      # Removes the token, effectively logging the user out.
      def clear_token
        @logger.info("Clearing token")
        token_path.delete if token_path.file?
      end

      # Checks if the user is logged in by verifying their authentication
      # token.
      #
      # @return [Boolean]
      def logged_in?
        return false if !client.access_token
        Vagrant::Util::CredentialScrubber.sensitive(client.access_token)

        with_error_handling do
          client.authentication_token_validate
          true
        end
      rescue Errors::Unauthorized
        false
      end

      # Login logs a user in and returns the token for that user. The token
      # is _not_ stored unless {#store_token} is called.
      #
      # @param [String] description
      # @param [String] code
      # @return [String] token The access token, or nil if auth failed.
      def login(description: nil, code: nil)
        @logger.info("Logging in '#{username_or_email}'")

        Vagrant::Util::CredentialScrubber.sensitive(password)
        with_error_handling do
          r = client.authentication_token_create(username: username_or_email,
            password: password, description: description, code: code)

          Vagrant::Util::CredentialScrubber.sensitive(r[:token])
          @client = VagrantCloud::Client.new(access_token: r[:token])
          r[:token]
        end
      end

      # Requests a 2FA code
      # @param [String] delivery_method
      def request_code(delivery_method)
        @env.ui.warn("Requesting 2FA code via #{delivery_method.upcase}...")

        Vagrant::Util::CredentialScrubber.sensitive(password)
        with_error_handling do
          r = client.authentication_request_2fa_code(
            username: username_or_email, password: password, delivery_method: delivery_method)

          two_factor = r[:two_factor]
          obfuscated_destination = two_factor[:obfuscated_destination]

          @env.ui.success("2FA code sent to #{obfuscated_destination}.")
        end
      end

      # Stores the given token locally, removing any previous tokens.
      #
      # @param [String] token
      def store_token(token)
        Vagrant::Util::CredentialScrubber.sensitive(token)
        @logger.info("Storing token in #{token_path}")

        token_path.open("w") do |f|
          f.write(token)
        end

        # Reset after we store the token since this is now _our_ token
        @client = VagrantCloud::Client.new(access_token: token)

        nil
      end

      # Reads the access token if there is one. This will first read the
      # `VAGRANT_CLOUD_TOKEN` environment variable and then fallback to the stored
      # access token on disk.
      #
      # @return [String]
      def token
        if present?(ENV["VAGRANT_CLOUD_TOKEN"]) && token_path.exist?
          # Only show warning if it has not been previously shown
          if !defined?(@@double_token_warning)
            @env.ui.warn <<-EOH.strip
Vagrant detected both the VAGRANT_CLOUD_TOKEN environment variable and a Vagrant login
token are present on this system. The VAGRANT_CLOUD_TOKEN environment variable takes
precedence over the locally stored token. To remove this error, either unset
the VAGRANT_CLOUD_TOKEN environment variable or remove the login token stored on disk:

    ~/.vagrant.d/data/vagrant_login_token

EOH
            @@double_token_warning = true
          end
        end

        if present?(ENV["VAGRANT_CLOUD_TOKEN"])
          @logger.debug("Using authentication token from environment variable")
          t = ENV["VAGRANT_CLOUD_TOKEN"]
        elsif token_path.exist?
          @logger.debug("Using authentication token from disk at #{token_path}")
          t = token_path.read.strip
        elsif present?(ENV["ATLAS_TOKEN"])
          @logger.warn("ATLAS_TOKEN detected within environment. Using ATLAS_TOKEN in place of VAGRANT_CLOUD_TOKEN.")
          t = ENV["ATLAS_TOKEN"]
        end

        if !t.nil?
          Vagrant::Util::CredentialScrubber.sensitive(t)
          return t
        end

        @logger.debug("No authentication token in environment or #{token_path}")

        nil
      end

      protected

      def with_error_handling(&block)
        yield
      rescue Excon::Error::Unauthorized
        @logger.debug("Unauthorized!")
        raise Errors::Unauthorized
      rescue Excon::Error::BadRequest => e
        @logger.debug("Bad request:")
        @logger.debug(e.message)
        @logger.debug(e.backtrace.join("\n"))
        parsed_response = JSON.parse(e.response.body)
        errors = parsed_response["errors"].join("\n")
        raise Errors::ServerError, errors: errors
      rescue Excon::Error::NotAcceptable => e
        @logger.debug("Got unacceptable response:")
        @logger.debug(e.message)
        @logger.debug(e.backtrace.join("\n"))

        parsed_response = JSON.parse(e.response.body)

        if two_factor = parsed_response['two_factor']
          store_two_factor_information two_factor

          if two_factor_default_delivery_method != APP
            request_code two_factor_default_delivery_method
          end

          raise Errors::TwoFactorRequired
        end

        begin
          errors = parsed_response["errors"].join("\n")
          raise Errors::ServerError, errors: errors
        rescue JSON::ParserError; end

        @logger.debug("Got an unexpected error:")
        @logger.debug(e.inspect)
        raise Errors::Unexpected, error: e.inspect
      rescue SocketError
        @logger.info("Socket error")
        raise Errors::ServerUnreachable, url: Vagrant.server_url.to_s
      end

      def token_path
        @env.data_dir.join("vagrant_login_token")
      end

      def store_two_factor_information(two_factor)
        @two_factor_default_delivery_method =
          two_factor['default_delivery_method']

        @two_factor_delivery_methods =
          two_factor['delivery_methods']

        @env.ui.warn "2FA is enabled for your account."
        if two_factor_default_delivery_method == APP
          @env.ui.info "Enter the code from your authenticator."
        else
          @env.ui.info "Default method is " \
            "'#{two_factor_default_delivery_method}'."
        end

        other_delivery_methods =
          two_factor_delivery_methods - [APP]

        if other_delivery_methods.any?
          other_delivery_methods_sentence = other_delivery_methods
            .map { |word| "'#{word}'" }
            .join(' or ')
          @env.ui.info "You can also type #{other_delivery_methods_sentence} " \
            "to request a new code."
        end
      end
    end
  end
end
