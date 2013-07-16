require "log4r"

module VagrantPlugins
  module CFEngine
    module Cap
      module RedHat
        module CFEngineInstall
          def self.cfengine_install(machine, config)
            logger = Log4r::Logger.new("vagrant::plugins::cfengine::cap_redhat_cfengine_install")

            machine.communicate.tap do |comm|
              logger.info("Adding the CFEngine repository to #{config.yum_repo_file}")
              comm.sudo("mkdir -p #{File.dirname(config.yum_repo_file)} && (echo '[cfengine-repository]'; echo 'name=CFEngine Community Yum Repository'; echo 'baseurl=#{config.yum_repo_url}'; echo 'enabled=1'; echo 'gpgcheck=1') > #{config.yum_repo_file}")
              logger.info("Installing CFEngine Community Yum Repository GPG KEY from #{config.repo_gpg_key_url}")
              comm.sudo("GPGFILE=$(mktemp) && wget -O $GPGFILE #{config.repo_gpg_key_url} && rpm --import $GPGFILE; rm -f $GPGFILE")

              comm.sudo("yum -y install #{config.package_name}")
            end
          end
        end
      end
    end
  end
end
