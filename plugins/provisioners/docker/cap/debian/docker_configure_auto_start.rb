module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Debian
        module DockerConfigureAutoStart
          def self.docker_configure_auto_start(machine)
            machine.communicate.tap do |comm|
              if !comm.test('grep -q \'\-r=true\' /etc/default/docker')
                comm.sudo("echo 'DOCKER_OPTS=\"-r=true ${DOCKER_OPTS}\"' >> /etc/default/docker")
                comm.sudo("stop docker")
                comm.sudo("start docker")
              end
            end
          end
        end
      end
    end
  end
end
