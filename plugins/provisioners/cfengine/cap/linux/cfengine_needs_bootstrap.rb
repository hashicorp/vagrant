require "log4r"

module VagrantPlugins
  module CFEngine
    module Cap
      module Linux
        module CFEngineNeedsBootstrap
          def self.cfengine_needs_bootstrap(machine, config)
            logger = Log4r::Logger.new("vagrant::plugins::cfengine::cap_linux_cfengine_bootstrap")

            machine.communicate.tap do |comm|
              # We hardcode fixing the permissions on /var/cfengine/ppkeys/, if it exists,
              # because otherwise CFEngine will fail to bootstrap.
              if comm.test("test -d /var/cfengine/ppkeys", sudo: true)
                logger.debug("Fixing permissions on /var/cfengine/ppkeys")
                comm.sudo("chmod -R 600 /var/cfengine/ppkeys")
              end

              logger.debug("Checking if CFEngine is bootstrapped...")
              bootstrapped = comm.test("test -f /var/cfengine/policy_server.dat", sudo: true)
              if bootstrapped && !config.force_bootstrap
                logger.info("CFEngine already bootstrapped, no need to do it again")
                return false
              end

              logger.info("CFEngine needs bootstrap.")
              return true
            end
          end
        end
      end
    end
  end
end
