require "rest_client"
require "vagrant/util/downloader"
require "vagrant/util/presence"

module VagrantPlugins
  module LoginCommand
    class Client
      APP = "app".freeze

      include Vagrant::Util::Presence

      attr_accessor :username_or_email
      attr_accessor :password
      attr_reader :two_factor_default_delivery_method
      attr_reader :two_factor_delivery_methods

      # Initializes a login client with the given Vagrant::Environment.
      #
      # @param [Vagrant::Environment] env
      def initialize(env)
        @logger = Log4r::Logger.new("vagrant::login::client")
        @env    = env
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
        token = self.token
        return false if !token

        with_error_handling do
          url = "#{Vagrant.server_url}/api/v1/authenticate" +
            "?access_token=#{token}"
          RestClient.get(url, content_type: :json)
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

        response = post(
          "/api/v1/authenticate", {
            user: {
              login: username_or_email,
              password: password
            },
            token: {
              description: description
            },
            two_factor: {
              code: code
            }
          }
        )

        response["token"]
      end

      # Requests a 2FA code
      # @param [String] delivery_method
      def request_code(delivery_method)
        @env.ui.warn("Requesting 2FA code via #{delivery_method.upcase}...")

        response = post(
          "/api/v1/two-factor/request-code", {
            user: {
              login: username_or_email,
              password: password
            },
            two_factor: {
              delivery_method: delivery_method.downcase
            }
          }
        )

        two_factor = response['two_factor']
        obfuscated_destination = two_factor['obfuscated_destination']

        @env.ui.success("2FA code sent to #{obfuscated_destination}.")
      end

      # Issues a post to a Vagrant Cloud path with the given payload.
      # @param [String] path
      # @param [Hash] payload
      # @return [Hash] response data
      def post(path, payload)
        with_error_handling do
          url = File.join(Vagrant.server_url, path)

          proxy   = nil
          proxy ||= ENV["HTTPS_PROXY"] || ENV["https_proxy"]
          proxy ||= ENV["HTTP_PROXY"]  || ENV["http_proxy"]
          RestClient.proxy = proxy

          response = RestClient::Request.execute(
            method: :post,
            url: url,
            payload: JSON.dump(payload),
            proxy: proxy,
            headers: {
              accept: :json,
              content_type: :json,
              user_agent: Vagrant::Util::Downloader::USER_AGENT,
            },
          )

          JSON.load(response.to_s)
        end
      end

      # Stores the given token locally, removing any previous tokens.
      #
      # @param [String] token
      def store_token(token)
        @logger.info("Storing token in #{token_path}")

        token_path.open("w") do |f|
          f.write(token)
        end

        nil
      end

      # Reads the access token if there is one. This will first read the
      # `VAGRANT_CLOUD_TOKEN` environment variable and then fallback to the stored
      # access token on disk.
      #
      # @return [String]
      def token
        if present?(ENV["VAGRANT_CLOUD_TOKEN"]) && token_path.exist?
          @env.ui.warn <<-EOH.strip
Vagrant detected both the VAGRANT_CLOUD_TOKEN environment variable and a Vagrant login
token are present on this system. The VAGRANT_CLOUD_TOKEN environment variable takes
precedence over the locally stored token. To remove this error, either unset
the VAGRANT_CLOUD_TOKEN environment variable or remove the login token stored on disk:

    ~/.vagrant.d/data/vagrant_login_token

EOH
        end

        if present?(ENV["VAGRANT_CLOUD_TOKEN"])
          @logger.debug("Using authentication token from environment variable")
          return ENV["VAGRANT_CLOUD_TOKEN"]
        end

        if token_path.exist?
          @logger.debug("Using authentication token from disk at #{token_path}")
          return token_path.read.strip
        end

        if present?(ENV["ATLAS_TOKEN"])
          @logger.warn("ATLAS_TOKEN detected within environment. Using ATLAS_TOKEN in place of VAGRANT_CLOUD_TOKEN.")
          return ENV["ATLAS_TOKEN"]
        end

        @logger.debug("No authentication token in environment or #{token_path}")

        nil
      end

      protected

      def with_error_handling(&block)
        yield
      rescue RestClient::Unauthorized
        @logger.debug("Unauthorized!")
        raise Errors::Unauthorized
      rescue RestClient::BadRequest => e
        @logger.debug("Bad request:")
        @logger.debug(e.message)
        @logger.debug(e.backtrace.join("\n"))
        parsed_response = JSON.parse(e.response)
        errors = parsed_response["errors"].join("\n")
        raise Errors::ServerError, errors: errors
      rescue RestClient::NotAcceptable => e
        @logger.debug("Got unacceptable response:")
        @logger.debug(e.message)
        @logger.debug(e.backtrace.join("\n"))

        parsed_response = JSON.parse(e.response)

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

        raise "An unexpected error occurred: #{e.inspect}"
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
