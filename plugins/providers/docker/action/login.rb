require "log4r"

module VagrantPlugins
  module DockerProvider
    module Action
      class Login
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::docker::login")
        end

        def login(env, config, driver)
          # Login!
          env[:ui].output(I18n.t("docker_provider.logging_in"))
          driver.login(
            config.email, config.username,
            config.password, config.auth_server)

          # Continue, so that the auth is protected
          # from meddling.
          @app.call(env)

          # Log out
          driver.logout(config.auth_server)
        end

        def call(env)
          config = env[:machine].provider_config
          driver = env[:machine].provider.driver

          # If we don't have a password set, don't auth
          return @app.call(env) if config.password == ""

          if !env[:machine].provider.host_vm?
            # no host vm in use, using docker directly
            login(env, config, driver)
          else
            # Grab a host VM lock to do the login so that we only login
            # once per container for the rest of this process.
            env[:machine].provider.host_vm_lock do
              login(env, config, driver)
            end
          end
        end
      end
    end
  end
end
