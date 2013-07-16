module VagrantPlugins
  module CFEngine
    module Cap
      module Debian
        module CFEngineInstall
          def self.cfengine_install(machine, config)
            machine.communicate.tap do |comm|
              comm.sudo("mkdir -p #{File.dirname(config.deb_repo_file)} && /bin/echo #{config.deb_repo_line} > #{config.deb_repo_file}")
              comm.sudo("GPGFILE=`tempfile`; wget -O $GPGFILE #{config.repo_gpg_key_url} && apt-key add $GPGFILE; rm -f $GPGFILE")

              comm.sudo("apt-get update")
              comm.sudo("apt-get install -y #{config.package_name}")
            end
          end
        end
      end
    end
  end
end
