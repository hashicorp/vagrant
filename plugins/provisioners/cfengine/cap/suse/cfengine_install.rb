module VagrantPlugins
  module CFEngine
    module Cap
      module SuSE
        module CFEngineInstall
          def self.cfengine_install(machine, config)
            machine.communicate.tap do |comm|
              comm.sudo("GPGFILE=$(mktemp) && wget -O $GPGFILE #{config.repo_gpg_key_url} && rpm --import $GPGFILE; rm -f $GPGFILE")
              comm.sudo("zypper addrepo -t YUM #{config.yum_repo_url} cfengine-repository")
              comm.sudo("zypper se #{config.package_name} && zypper -n install #{config.package_name}")
            end
          end
        end
      end
    end
  end
end
