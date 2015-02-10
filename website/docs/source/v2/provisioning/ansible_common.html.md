---
page_title: "Common Ansible Options - Provisioning"
sidebar_current: "provisioning-ansible-common"
---

# Shared Ansible Options

The following options are available to both Ansible provisioners:

 - [`ansible`](/v2/provisioning/ansible.html)
 - [`ansible_local`](/v2/provisioning/ansible_local.html)

These options get passed to the `ansible-playbook` command that ships with Ansible, either via command line arguments or environment variables, depending on Ansible own capabilities.

Some of these options are for advanced usage only and should not be used unless you understand their purpose.

- `extra_vars` (string or hash) - Pass additional variables (with highest priority) to the playbook.

  This parameter can be a path to a JSON or YAML file, or a hash.

  Example:

    ```ruby
    ansible.extra_vars = {
      ntp_server: "pool.ntp.org",
      nginx: {
        port: 8008,
        workers: 4
      }
    }
    ```
  These variables take the highest precedence over any other variables.

- `groups` (hash) - Set of inventory groups to be included in the [auto-generated inventory file](/v2/provisioning/ansible_intro.html).

  Example:

    ```ruby
    ansible.groups = {
      "web" => ["vm1", "vm2"],
      "db"  => ["vm3"]
    }
    ```

  Notes:

    - Alphanumeric patterns are not supported (e.g. `db-[a:f]`, `vm[01:10]`).
    - This option has no effect when the `inventory_path` option is defined.

- `inventory_path` (string) - The path to an Ansible inventory resource (e.g. a [static inventory file](http://docs.ansible.com/intro_inventory.html), a [dynamic inventory script](http://docs.ansible.com/intro_dynamic_inventory.html) or even [multiple inventories stored in the same directory](http://docs.ansible.com/intro_dynamic_inventory.html#using-multiple-inventory-sources)).

  By default, this option is disabled and Vagrant generates an inventory based on the `Vagrantfile` information.

- `limit` (string or array of strings) - Set of machines or groups from the inventory file to further control which hosts [are affected](http://docs.ansible.com/glossary.html#limit-groups).

  The default value is set to the machine name (taken from `Vagrantfile`) to ensure that `vagrant provision` command only affect the expected machine.

  Setting `limit = "all"` can be used to make Ansible connect to all machines from the inventory file.

- `raw_arguments` (array of strings) - a list of additional `ansible-playbook` arguments.

  It is an *unsafe wildcard* that can be used to apply Ansible options that are not (yet) supported by this Vagrant provisioner. As of Vagrant 1.7, `raw_arguments` has the highest priority and its values can potentially override or break other Vagrant settings.

  Example: `['--check', '-M /my/modules']`).

- `skip_tags` (string or array of strings) - Only plays, roles and tasks that [*do not match* these values will be executed](http://docs.ansible.com/playbooks_tags.html).

- `start_at_task` (string) - The task name where the [playbook execution will start](http://docs.ansible.com/playbooks_startnstep.html#start-at-task).

- `sudo` (boolean) - Cause Ansible to perform all the playbook tasks [using sudo](http://docs.ansible.com/glossary.html#sudo).

  The default value is `false`.

- `sudo_user` (string) - set the default username who should be used by the sudo command.

- `tags` (string or array of strings) - Only plays, roles and tasks [tagged with these values will be executed](http://docs.ansible.com/playbooks_tags.html) .

- `verbose` (boolean or string) - Set Ansible's verbosity to obtain detailed logging

  Default value is `false` (minimal verbosity).

  Examples: `true` (equivalent to `v`), `-vvv` (equivalent to `vvv`), `vvvv`.

  Note that when the `verbose` option is enabled, the `ansible-playbook` command used by Vagrant will be displayed.

- `vault_password_file` (string) - The path of a file containing the password used by [Ansible Vault](http://docs.ansible.com/playbooks_vault.html#vault).
