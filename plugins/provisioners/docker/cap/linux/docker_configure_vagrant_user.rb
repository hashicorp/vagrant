module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Linux
        module DockerConfigureVagrantUser
          def self.docker_configure_vagrant_user(machine)
            communicator_info = machine.communicator_info

            machine.communicate.tap do |comm|
              if !comm.test("id -Gn | grep docker")
                comm.sudo("usermod -a -G docker #{communicator_info[:username]}")
              end
            end
          end
        end
      end
    end
  end
end
