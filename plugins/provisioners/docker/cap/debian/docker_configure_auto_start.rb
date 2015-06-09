module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Debian
        module DockerConfigureAutoStart
          def self.docker_configure_auto_start(machine)
            machine.communicate.tap do |comm|
              if !comm.test('grep -q \'\-r=true\' /etc/default/docker')
                comm.sudo("echo 'DOCKER_OPTS=\"-r=true ${DOCKER_OPTS}\"' >> /etc/default/docker")
                comm.sudo("service docker restart")

                # Wait some amount time for the pid to become available
                # so that we don't start executing Docker commands until
                # it is available.
                if machine.guest.capability?(:docker_daemon_running)
                  [0, 1, 2, 4].each do |delay|
                    sleep delay
                    break if machine.guest.capability(:docker_daemon_running)
                  end
                else
                  # This OS doesn't support checking if Docker is running,
                  # so just wait 5 seconds.
                  sleep 5
                end
              end
            end
          end
        end
      end
    end
  end
end
