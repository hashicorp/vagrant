# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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

              unless version.empty?
                command << "&& [[ $(python3 -c \"import importlib.metadata; print(importlib.metadata.version('ansible'))\") == \"#{version}\" ]]"
              end

              machine.communicate.test command, sudo: false
            end

          end
        end
      end
    end
  end
end
