module HashiCorp
  module Rack
    # This redirects to the latest version of the docs.
    class RedirectToLatest
      def initialize(app)
        @app = app
      end

      def call(env)
        if env["PATH_INFO"] =~ /^\/$/
          headers = {
            "Content-Type" => "text/html",
            "Location" => "/v2/",
            "Surrogate-Key" => "page"
          }
          message = "Redirecting to new URL..."

          return [301, headers, [message]]
        end

        @app.call(env)
      end
    end
  end
end
