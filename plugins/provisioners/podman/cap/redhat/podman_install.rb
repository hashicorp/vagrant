module VagrantPlugins
  module PodmanProvisioner
    module Cap
      module Redhat
        module PodmanInstall
          def self.podman_install(machine)
            # Official install instructions for podman
            # https://podman.io/getting-started/installation.html
            case machine.guest.capability("flavor")
            when :rhel_7
              machine.communicate.tap do |comm|
                comm.sudo("curl curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_7/devel:kubic:libcontainers:stable.repo")
                comm.sudo("yum -q -y install podman")
              end
            when :rhel_8
              machine.communicate.tap do |comm|
                comm.sudo("dnf -y module disable container-tools")
                comm.sudo("dnf -y install 'dnf-command(copr)'")
                comm.sudo("dnf -y copr enable rhcontainerbot/container-selinux")
                comm.sudo("curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo")
                comm.sudo("dnf -y install podman")
              end
            else
              machine.communicate.tap do |comm|
                comm.sudo("yum -q -y install podman")
              end
            end
          end
        end
      end
    end
  end
end
