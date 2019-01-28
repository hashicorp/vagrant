
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Pip

          DEFAULT_PIP_INSTALL_CMD = "curl https://bootstrap.pypa.io/get-pip.py | sudo python"

          def self.pip_install(machine, package = "", version = "", pip_args = "", upgrade = true)
            upgrade_arg = "--upgrade" if upgrade
            version_arg = ""

            if !version.to_s.empty? && version.to_s.to_sym != :latest
              version_arg = "==#{version}"
            end

            args_array = [pip_args, upgrade_arg, "#{package}#{version_arg}"]

            machine.communicate.sudo "pip install #{args_array.join(' ')}"
          end

          def self.get_pip(machine, pip_install_cmd=DEFAULT_PIP_INSTALL_CMD)

            # The objective here is to get pip either by default
            # or by the argument passed in. The objective is not 
            # to circumvent the pip setup by passing in nothing.
            # Thus, we stick with the default on an empty string
            # or if it is an UNSET_VALUE.

            if pip_install_cmd == Vagrant.plugin("2", :config)::UNSET_VALUE || pip_install_cmd.empty?
              pip_install_cmd=DEFAULT_PIP_INSTALL_CMD
            end

            machine.ui.detail I18n.t("vagrant.provisioners.ansible.installing_pip")
            machine.communicate.execute pip_install_cmd
          end

        end
      end
    end
  end
end
