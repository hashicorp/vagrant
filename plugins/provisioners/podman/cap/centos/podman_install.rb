module VagrantPlugins
  module PodmanProvisioner
    module Cap
      module Centos
        module PodmanInstall
          def self.podman_install(machine, kubic)
            if kubic
              # Official install instructions for podman
              # https://podman.io/getting-started/installation.html
              case machine.guest.capability("flavor")
              when :centos_7
                machine.communicate.tap do |comm|
                  comm.sudo("curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_7/devel:kubic:libcontainers:stable.repo")
                  comm.sudo("yum -q -y install podman")
                end
              when :centos_8
                machine.communicate.tap do |comm|
                  comm.sudo("dnf -y module disable container-tools &> /dev/null || echo 'container-tools module does not exist'")
                  comm.sudo("dnf -y install 'dnf-command(copr)'")
                  comm.sudo("dnf -y copr enable rhcontainerbot/container-selinux")
                  comm.sudo("curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo")
                  comm.sudo("dnf -y install podman")
                end
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
