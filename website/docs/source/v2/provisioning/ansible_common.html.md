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
  Example with [group variables](http://docs.ansible.com/ansible/intro_inventory.html#group-variables):

    ```ruby
    ansible.groups = {
      "atlanta" => ["host1", "host2"],
      "atlanta:vars" => {"ntp_server" => "ntp.atlanta.example.com",
                         "proxy" => "proxy.atlanta.example.com"}
    }
    ```

  Notes:

    - Alphanumeric patterns are not supported (e.g. `db-[a:f]`, `vm[01:10]`).
    - This option has no effect when the `inventory_path` option is defined.

- `inventory_path` (string) - The path to an Ansible inventory resource (e.g. a [static inventory file](http://docs.ansible.com/intro_inventory.html), a [dynamic inventory script](http://docs.ansible.com/intro_dynamic_inventory.html) or even [multiple inventories stored in the same directory](http://docs.ansible.com/intro_dynamic_inventory.html#using-multiple-inventory-sources)).

  By default, this option is disabled and Vagrant generates an inventory based on the `Vagrantfile` information.

- `galaxy_command` (template string) - The command pattern used to install Galaxy roles when `galaxy_role_file` is set.

  The following (optional) placeholders can be used in this command pattern:
    - `%{role_file}` is replaced by the absolute path to the `galaxy_role_file` option
    - `%{roles_path}` is
      - replaced by the absolute path to the `galaxy_roles_path` option when such option is defined, or
      - replaced by the absolute path to a `roles` subdirectory sitting in the `playbook` parent directory.

  By default, this option is set to

  `ansible-galaxy install --role-file=%{role_file} --roles-path=%{roles_path} --force`

- `galaxy_role_file` (string) - The path to the Ansible Galaxy role file.

  By default, this option is set to `nil` and Galaxy support is then disabled.

  Note: if an absolute path is given, the `ansible_local` provisioner will assume that it corresponds to the exact location on the guest system.

- `galaxy_roles_path` (string) - The path to the directory where Ansible Galaxy roles must be installed

  By default, this option is set to `nil`, which means that the Galaxy roles will be installed in a `roles` subdirectory located in the parent directory of the `playbook` file.

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
