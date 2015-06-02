module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Linux
        module DockerConfigureVagrantUser
          def self.docker_configure_vagrant_user(machine)
            ssh_info = machine.ssh_info

            machine.communicate.tap do |comm|
              if comm.test("getent group docker") && !comm.test("id -Gn | grep docker")
                comm.sudo("usermod -a -G docker #{ssh_info[:username]}")
              end
            end
          end
        end
      end
    end
  end
end
