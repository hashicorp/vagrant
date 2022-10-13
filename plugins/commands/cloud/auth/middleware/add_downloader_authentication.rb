require "cgi"
require "uri"

require "vagrant/util/credential_scrubber"
require_relative "./add_authentication"

require Vagrant.source_root.join("plugins/commands/cloud/client/client")

# Similar to AddAuthentication this middleware will add authentication for interacting
# with Vagrant cloud. It does this by adding Authentication headers to a 
# Vagrant::Util::Downloader object. 
module VagrantPlugins
  module CloudCommand
    class AddDownloaderAuthentication <  AddAuthentication

      @@logger = Log4r::Logger.new("vagrant::clout::add_download_authentication")

      def call(env)
        client = Client.new(env[:env])
        token  = client.token
        Vagrant::Util::CredentialScrubber.sensitive(token)

        begin
          target_url = URI.parse(env[:downloader].source)
          if target_url.host != TARGET_HOST && REPLACEMENT_HOSTS.include?(target_url.host)
              target_url.host = TARGET_HOST
              env[:downloader].source = target_url.to_s
          end
        rescue URI::Error
          # if there is an error, use current target_url
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

            if Array(env[:downloader].headers).any? { |h| h.include?("Authorization") }
              @@logger.info("Not adding an authentication header, one already found")
            else
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
