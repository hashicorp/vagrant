module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Debian
        module DockerInstall
          def self.docker_install(machine, version)
            package = 'lxc-docker'
            package << "-#{version}" if version != :latest

            machine.communicate.tap do |comm|
              comm.sudo("apt-get update -y")
              # TODO: Perform check on the host machine if aufs is installed and using LXC
              if machine.provider_name != :lxc
                comm.sudo("lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`")
              end
              comm.sudo("apt-get install -y --force-yes -q curl")
              comm.sudo("curl -sSL https://get.docker.com/gpg | apt-key add -")
              comm.sudo("echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list")
              comm.sudo("apt-get update")
              comm.sudo("echo lxc lxc/directory string /var/lib/lxc | debconf-set-selections")
              comm.sudo("apt-get install -y --force-yes -q xz-utils #{package} -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'")

              # chmod the directory if it exists
              comm.sudo("chmod 0755 /var/lib/docker")
            end
          end
        end
      end
    end
  end
end
