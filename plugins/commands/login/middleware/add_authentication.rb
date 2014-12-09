require "uri"

require_relative "../client"

module VagrantPlugins
  module LoginCommand
    class AddAuthentication
      def initialize(app, env)
        @app = app
      end

      def call(env)
        client = Client.new(env[:env])
        token  = client.token

        if token && Vagrant.server_url
          server_uri = URI.parse(Vagrant.server_url)

          env[:box_urls].map! do |url|
            u = URI.parse(url)
            if u.host == server_uri.host
              u.query ||= ""
              u.query += "&" if u.query != ""
              u.query += "access_token=#{token}"
            end

            u.to_s
          end
        end

        @app.call(env)
      end
    end
  end
end
