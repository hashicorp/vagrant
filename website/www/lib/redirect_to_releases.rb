module HashiCorp
  module Rack
    # This redirects to releases.hashicorp.com when a user tries to download
    # an old version of Vagrant.
    class RedirectToReleases
      def initialize(app)
        @app = app
      end

      def call(env)
        if env["PATH_INFO"] =~ /^\/downloads-archive/
          headers = {
            "Content-Type" => "text/html",
            "Location"     => "https://releases.hashicorp.com/vagrant",
          }

          message = "Redirecting to releases archive..."

          return [301, headers, [message]]
        end

        if env["PATH_INFO"] =~ /^\/download-archive\/v(.+)\.html/
          headers = {
            "Content-Type" => "text/html",
            "Location"     => "https://releases.hashicorp.com/vagrant/#{$1}",
          }

          message = "Redirecting to releases archive..."

          return [301, headers, [message]]
        end

        @app.call(env)
      end
    end
  end
end
