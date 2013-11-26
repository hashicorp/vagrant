module VagrantPlugins
  module Docker
    module Cap
      module Debian
        module DockerConfigureAutoStart
          def self.docker_configure_auto_start(machine)
            if ! machine.communicate.test('grep -q \'\-r=true\' /etc/init/docker.conf')
              machine.communicate.sudo("sed -i.bak 's/docker -d/docker -d -r=true/' /etc/init/docker.conf ")
            end
          end
        end
      end
    end
  end
end
