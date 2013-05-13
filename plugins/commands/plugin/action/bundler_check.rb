module VagrantPlugins
  module CommandPlugin
    module Action
      class BundlerCheck
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Bundler sets up its own custom gem load paths such that our
          # own gems are never loaded. Therefore, give an error if a user
          # tries to install gems while within a Bundler-managed environment.
          if defined?(Bundler)
            require 'bundler/shared_helpers'
            if Bundler::SharedHelpers.in_bundle?
              raise Vagrant::Errors::GemCommandInBundler
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
