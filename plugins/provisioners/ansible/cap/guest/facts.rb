
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Facts

          def self.dnf?(machine)
            machine.communicate.test "/usr/bin/which -s dnf"
          end

          def self.yum?(machine)
            machine.communicate.test "/usr/bin/which -s yum"
          end

          def self.rpm_package_manager(machine)
            dnf?(machine) ? "dnf" : "yum"
          end

        end
      end
    end
  end
end
