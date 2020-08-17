require "cgi"
require "uri"

require Vagrant.source_root.join("plugins/commands/cloud/client/client")

module VagrantPlugins
  module CloudCommand
    class AddAuthentication
      REPLACEMENT_HOSTS = [
        "app.vagrantup.com".freeze,
        "atlas.hashicorp.com".freeze
      ].freeze
      TARGET_HOST = "vagrantcloud.com".freeze
      CUSTOM_HOST_NOTIFY_WAIT = 5

      def self.custom_host_notified!
        @_host_notify = true
      end

      def self.custom_host_notified?
        if defined?(@_host_notify)
          @_host_notify
        else
          false
        end
      end

      def initialize(app, env)
        @app = app
        CloudCommand::Plugin.init!
      end

      def call(env)
        client = Client.new(env[:env])
        token  = client.token
        target_url = URI.parse(env[:downloader].source)

        if target_url.host != TARGET_HOST && REPLACEMENT_HOSTS.include?(target_url.host)
          begin
            target_url.host = TARGET_HOST
            target_url = target_url.to_s
          rescue URI::Error
            # if there is an error, use current target_url
          end
        end

        server_uri = URI.parse(Vagrant.server_url.to_s)
        if token && !server_uri.host.to_s.empty?
          if target_url.host == server_uri.host
            if server_uri.host != TARGET_HOST && !self.class.custom_host_notified?
              env[:ui].warn(I18n.t("cloud_command.middleware.authentication.different_target",
                custom_host: server_uri.host, known_host: TARGET_HOST) + "\n")
              sleep CUSTOM_HOST_NOTIFY_WAIT
              self.class.custom_host_notified!
            end

            if env[:downloader].headers && !env[:downloader].headers.any? { |h| h.include?("Authorization") }
              env[:downloader].headers << "Authorization: Bearer #{token}"
            end
          end

          env[:downloader]
        end

        @app.call(env)
      end.freeze
    end
  end
end
