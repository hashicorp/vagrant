require "cgi"
require "uri"

require_relative "../client"

module VagrantPlugins
  module LoginCommand
    class AddAuthentication
      ALLOWED_AUTHENTICATION_HOSTS = %w[
        app.vagrantup.com
        atlas.hashicorp.com
        vagrantcloud.com
      ].freeze

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
            replace = u.host == server_uri.host

            if !replace
              if ALLOWED_AUTHENTICATION_HOSTS.include?(u.host) &&
                  ALLOWED_AUTHENTICATION_HOSTS.include?(server_uri.host)
                replace = true
              end
            end

            if replace
              q = CGI.parse(u.query || "")

              current = q["access_token"]
              if current && current.empty?
                q["access_token"] = token
              end

              u.query = URI.encode_www_form(q)
            end

            u.to_s
          end
        end

        @app.call(env)
      end
    end
  end
end
