module HashiCorp
  module Rack
    # This redirects the V1 docs to the GitHub pages hosted version.
    class RedirectV1Docs
      def initialize(app)
        @app = app
      end

      def call(env)
        if env["PATH_INFO"] =~ /^\/v1/
          headers = {
            "Content-Type" => "text/html",
            "Location"     => "http://docs-v1.vagrantup.com#{env["PATH_INFO"]}",
            "Surrogate-Key" => "page"
          }

          message = "Redirecting to old documentation URL..."

          return [301, headers, [message]]
        end

        @app.call(env)
      end
    end
  end
end
