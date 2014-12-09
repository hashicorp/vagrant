require "rest_client"

module VagrantPlugins
  module LoginCommand
    class Client
      # Initializes a login client with the given Vagrant::Environment.
      #
      # @param [Vagrant::Environment] env
      def initialize(env)
        @env = env
      end

      # Removes the token, effectively logging the user out.
      def clear_token
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
        with_error_handling do
          url      = "#{Vagrant.server_url}/api/v1/authenticate"
          request  = { "user" => { "login" => user, "password" => pass } }
          response = RestClient.post(
            url, JSON.dump(request), content_type: :json)
          data = JSON.load(response.to_s)
          data["token"]
        end
      end

      # Stores the given token locally, removing any previous tokens.
      #
      # @param [String] token
      def store_token(token)
        token_path.open("w") do |f|
          f.write(token)
        end
        nil
      end

      # Reads the access token if there is one, or returns nil otherwise.
      #
      # @return [String]
      def token
        token_path.read
      rescue Errno::ENOENT
        return nil
      end

      protected

      def with_error_handling(&block)
        yield
      rescue RestClient::Unauthorized
        false
      rescue RestClient::NotAcceptable => e
        begin
          errors = JSON.parse(e.response)["errors"]
            .map { |h| h["message"] }
            .join("\n")

          raise Errors::ServerError, errors: errors
        rescue JSON::ParserError; end

        raise "An unexpected error occurred: #{e.inspect}"
      rescue SocketError
        raise Errors::ServerUnreachable, url: Vagrant.server_url.to_s
      end

      def token_path
        @env.data_dir.join("vagrant_login_token")
      end
    end
  end
end
