module VagrantPlugins
  module Docker
    module Cap
      module Redhat
        module DockerInstall
          def self.docker_install(machine, version)
            machine.communicate.tap do |comm|
              if ! comm.test("rpm -qa | grep epel-release")
                comm.sudo("rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm")
              end
              comm.sudo("yum -y upgrade")
              comm.sudo("yum -y install docker-io")
            end
          end
        end
      end
    end
  end
end
