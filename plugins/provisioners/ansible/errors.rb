require "vagrant"

module VagrantPlugins
  module Ansible
    module Errors
      class AnsibleError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.provisioners.ansible.errors")
      end

      class AnsibleCommandFailed < AnsibleError
        error_key(:ansible_command_failed)
      end

      class AnsibleCompatibilityModeConflict < AnsibleError
        error_key(:ansible_compatibility_mode_conflict)
      end

      class AnsibleNotFoundOnGuest < AnsibleError
        error_key(:ansible_not_found_on_guest)
      end

      class AnsibleNotFoundOnHost < AnsibleError
        error_key(:ansible_not_found_on_host)
      end

      class AnsiblePipInstallIsNotSupported < AnsibleError
        error_key(:cannot_support_pip_install)
      end

      class AnsibleProgrammingError < AnsibleError
        error_key(:ansible_programming_error)
      end

      class AnsibleVersionMismatch < AnsibleError
        error_key(:ansible_version_mismatch)
      end

    end
  end
end