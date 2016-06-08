module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module POSIX
          module AnsibleInstalled

            # Check if Ansible is installed (at the given version).
            # @return [true, false]
            def self.ansible_installed(machine, version)
              command = 'test -x "$(command -v ansible)"'

              if !version.empty?
                command << "&& ansible --version | grep 'ansible #{version}'"
              end

              machine.communicate.test command, sudo: false
            end

          end
        end
      end
    end
  end
end
