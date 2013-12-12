module VagrantPlugins
  module Docker
    module Cap
      module Redhat
        module DockerConfigureAutoStart
          def self.docker_configure_auto_start(machine)
            if ! machine.communicate.test('grep -q \'\-r=true\' /etc/sysconfig/docker')
              machine.communicate.sudo("sed -i.bak 's/docker -d/docker -d -r=true/' /etc/sysconfig/docker ")
            end
          end
        end
      end
    end
  end
end
