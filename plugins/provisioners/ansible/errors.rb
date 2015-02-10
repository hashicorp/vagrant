require "vagrant"

module VagrantPlugins
  module Ansible
    module Errors
      class AnsibleError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.provisioners.ansible.errors")
      end

      class AnsiblePlaybookAppFailed < AnsibleError
        error_key(:ansible_playbook_app_failed)
      end

      class AnsiblePlaybookAppNotFoundOnHost < AnsibleError
        error_key(:ansible_playbook_app_not_found_on_host)
      end

      class AnsiblePlaybookAppNotFoundOnGuest < AnsibleError
        error_key(:ansible_playbook_app_not_found_on_guest)
      end

      class AnsibleVersionNotFoundOnGuest < AnsibleError
        error_key(:ansible_version_not_found_on_guest)
      end
    end
  end
end