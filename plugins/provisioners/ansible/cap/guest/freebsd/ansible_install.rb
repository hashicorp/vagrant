# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../errors"

module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module FreeBSD
          module AnsibleInstall

            def self.ansible_install(machine, install_mode, ansible_version, pip_args, pip_install_cmd = "")
              if install_mode != :default
                raise Ansible::Errors::AnsiblePipInstallIsNotSupported
              else
                machine.communicate.sudo "pkg install -qy py37-ansible"
              end
            end

          end
        end
      end
    end
  end
end
