module VagrantPlugins
  module PodmanProvisioner
    module Cap
      module Redhat
        module PodmanInstall
          def self.podman_install(machine, kubic)
            # Official install instructions for podman
            # https://podman.io/getting-started/installation.html
            case machine.guest.capability("flavor")
            when :rhel_7
              machine.communicate.tap do |comm|
                comm.sudo("subscription-manager repos --enable=rhel-7-server-extras-rpms")
                comm.sudo("yum -q -y install podman")
              end
            when :rhel_8
              machine.communicate.tap do |comm|
                comm.sudo("yum module enable -y container-tools")
                comm.sudo("yum module install -y container-tools")
              end
            end
          end
        end
      end
    end
  end
end
