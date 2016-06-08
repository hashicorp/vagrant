
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Pip

          def self.pip_install(machine, package, version = "", upgrade = true)
            upgrade_arg = "--upgrade " if upgrade
            version_arg = ""

            if !version.to_s.empty? && version.to_s.to_sym != :latest
              version_arg = "==#{version}"
            end

            machine.communicate.sudo "pip install #{upgrade_arg}#{package}#{version_arg}"
          end

          def self.get_pip(machine)
            machine.ui.detail I18n.t("vagrant.provisioners.ansible.installing_pip")
            machine.communicate.execute "curl https://bootstrap.pypa.io/get-pip.py | sudo python"
          end

        end
      end
    end
  end
end
