require "rest_client"
require "vagrant/util/downloader"
require "vagrant/util/presence"

module VagrantPlugins
  module LoginCommand
    class Client
      include Vagrant::Util::Presence

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
      end

      # Login logs a user in and returns the token for that user. The token
      # is _not_ stored unless {#store_token} is called.
      #
      # @param [String] user
      # @param [String] pass
      # @return [String] token The access token, or nil if auth failed.
      def login(user, pass)
        @logger.info("Logging in '#{user}'")

        with_error_handling do
          url      = "#{Vagrant.server_url}/api/v1/authenticate"
          request  = { "user" => { "login" => user, "password" => pass } }

          proxy   = nil
          proxy ||= ENV["HTTPS_PROXY"] || ENV["https_proxy"]
          proxy ||= ENV["HTTP_PROXY"]  || ENV["http_proxy"]
          RestClient.proxy = proxy

          response = RestClient::Request.execute(
            method: :post,
            url: url,
            payload: JSON.dump(request),
            proxy: proxy,
            headers: {
              accept: :json,
              content_type: :json,
              user_agent: Vagrant::Util::Downloader::USER_AGENT,
            },
          )

          data = JSON.load(response.to_s)
          data["token"]
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
      # `ATLAS_TOKEN` environment variable and then fallback to the stored
      # access token on disk.
      #
      # @return [String]
      def token
        if present?(ENV["ATLAS_TOKEN"]) && token_path.exist?
          @env.ui.warn <<-EOH.strip
Vagrant detected both the ATLAS_TOKEN environment variable and a Vagrant login
token are present on this system. The ATLAS_TOKEN environment variable takes
precedence over the locally stored token. To remove this error, either unset
the ATLAS_TOKEN environment variable or remove the login token stored on disk:

    ~/.vagrant.d/data/vagrant_login_token

In general, the ATLAS_TOKEN is more preferred because it is respected by all
HashiCorp products.
EOH
        end

        if present?(ENV["ATLAS_TOKEN"])
          @logger.debug("Using authentication token from environment variable")
          return ENV["ATLAS_TOKEN"]
        end

        if token_path.exist?
          @logger.debug("Using authentication token from disk at #{token_path}")
          return token_path.read.strip
        end

        @logger.debug("No authentication token in environment or #{token_path}")

        nil
      end

      protected

      def with_error_handling(&block)
        yield
      rescue RestClient::Unauthorized
        @logger.debug("Unauthorized!")
        false
      rescue RestClient::NotAcceptable => e
        @logger.debug("Got unacceptable response:")
        @logger.debug(e.message)
        @logger.debug(e.backtrace.join("\n"))

        begin
          errors = JSON.parse(e.response)["errors"].join("\n")
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
    end
  end
end
