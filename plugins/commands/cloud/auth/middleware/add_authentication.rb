# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "cgi"
require "uri"
require "log4r"

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
        @logger = Log4r::Logger.new("vagrant::cloud::auth::authenticate-box-url")
        CloudCommand::Plugin.init!
      end

      def call(env)
        if ENV["VAGRANT_SERVER_ACCESS_TOKEN_BY_URL"]
          @logger.warn("Adding access token as GET parameter by user request")
          client = Client.new(env[:env])
          token  = client.token

          env[:box_urls].map! do |url|
            begin
              u = URI.parse(url)
              if u.host != TARGET_HOST && REPLACEMENT_HOSTS.include?(u.host)
                u.host = TARGET_HOST
                u.to_s
              else
                url
              end
            rescue URI::Error
              url
            end
          end

          server_uri = URI.parse(Vagrant.server_url.to_s)

          if token && !server_uri.host.to_s.empty?
            env[:box_urls].map! do |url|
              begin
                u = URI.parse(url)

                if u.host == server_uri.host
                  if server_uri.host != TARGET_HOST && !self.class.custom_host_notified?
                    env[:ui].warn(I18n.t("cloud_command.middleware.authentication.different_target",
                      custom_host: server_uri.host, known_host: TARGET_HOST) + "\n")
                    sleep CUSTOM_HOST_NOTIFY_WAIT
                    self.class.custom_host_notified!
                  end

                  q = CGI.parse(u.query || "")

                  current = q["access_token"]
                  if current && current.empty?
                    q["access_token"] = token
                  end

                  u.query = URI.encode_www_form(q)
                end

                u.to_s
              rescue URI::Error
                url
              end
            end
          end
        else
          env[:box_urls].map! do |url|
            begin
              u = URI.parse(url)
              q = CGI.parse(u.query || "")
              if !q["access_token"].empty?
                @logger.warn("Removing access token from URL parameter.")
                q.delete("access_token")
                if q.empty?
                  u.query = nil
                else
                  u.query = URI.encode_www_form(q)
                end
                u.to_s
              else
                @logger.warn("Authentication token not found as GET parameter.")
                url
              end
            rescue URI::Error
              url
            end
          end
        end
        @app.call(env)
      end.freeze
    end
  end
end
