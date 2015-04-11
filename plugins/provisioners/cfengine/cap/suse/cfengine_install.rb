module VagrantPlugins
  module CFEngine
    module Cap
      module SUSE
        module CFEngineInstall
          def self.cfengine_install(machine, config)
            machine.communicate.tap do |comm|
              comm.sudo("rpm --import #{config.repo_gpg_key_url}")

              comm.sudo("zypper addrepo -t YUM #{config.yum_repo_url} CFEngine")
              comm.sudo("zypper se #{config.package_name} && zypper -n install #{config.package_name}")
            end
          end
        end
      end
    end
  end
end
