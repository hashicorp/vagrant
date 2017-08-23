---
layout: "docs"
page_title: "Common Ansible Options - Provisioning"
sidebar_current: "provisioning-ansible-common"
description: |-
  This page details the common options to the Vagrant Ansible provisioners.
---

# Shared Ansible Options

The following options are available to both Vagrant Ansible provisioners:

 - [`ansible`](/docs/provisioning/ansible.html)
 - [`ansible_local`](/docs/provisioning/ansible_local.html)

These options get passed to the `ansible-playbook` command that ships with Ansible, either via command line arguments or environment variables, depending on Ansible own capabilities.

Some of these options are for advanced usage only and should not be used unless you understand their purpose.

- `config_file` (string) - The path to an [Ansible Configuration file](https://docs.ansible.com/intro_configuration.html).

    By default, this option is not set, and Ansible will [search for a possible configuration file in some default locations](/docs/provisioning/ansible_intro.html#ANSIBLE_CONFIG).

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

- `groups` (hash) - Set of inventory groups to be included in the [auto-generated inventory file](/docs/provisioning/ansible_intro.html).

    Example:

    ```ruby
    ansible.groups = {
      "web" => ["vm1", "vm2"],
      "db"  => ["vm3"]
    }
    ```
    Example with [group variables](https://docs.ansible.com/ansible/intro_inventory.html#group-variables):

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

- `host_vars` (hash) - Set of inventory host variables to be included in the [auto-generated inventory file](https://docs.ansible.com/ansible/intro_inventory.html#host-variables).

    Example:

    ```ruby
    ansible.host_vars = {
      "host1" => {"http_port" => 80,
                  "maxRequestsPerChild" => 808},
                  "comments" => "'text with spaces'",
      "host2" => {"http_port" => 303,
                  "maxRequestsPerChild" => 909}
    }
    ```

    Note: This option has no effect when the `inventory_path` option is defined.

- `inventory_path` (string) - The path to an Ansible inventory resource (e.g. a [static inventory file](https://docs.ansible.com/intro_inventory.html), a [dynamic inventory script](https://docs.ansible.com/intro_dynamic_inventory.html) or even [multiple inventories stored in the same directory](https://docs.ansible.com/intro_dynamic_inventory.html#using-multiple-inventory-sources)).

    By default, this option is disabled and Vagrant generates an inventory based on the `Vagrantfile` information.

- `limit` (string or array of strings) - Set of machines or groups from the inventory file to further control which hosts [are affected](https://docs.ansible.com/glossary.html#limit-groups).

    The default value is set to the machine name (taken from `Vagrantfile`) to ensure that `vagrant provision` command only affect the expected machine.

    Setting `limit = "all"` can be used to make Ansible connect to all machines from the inventory file.

- `playbook_command` (string) - The command used to run playbooks.

    The default value is `ansible-playbook`

- `raw_arguments` (array of strings) - a list of additional `ansible-playbook` arguments.

    It is an *unsafe wildcard* that can be used to apply Ansible options that are not (yet) supported by this Vagrant provisioner. As of Vagrant 1.7, `raw_arguments` has the highest priority and its values can potentially override or break other Vagrant settings.

    Examples:
    - `['--check', '-M', '/my/modules']`
    - `["--connection=paramiko", "--forks=10"]`

    **Caveat:** The `ansible` provisioner does not support whitespace characters in `raw_arguments` elements. Therefore **don't write** something like `["-c paramiko"]`, which will result with an invalid `" parmiko"` parameter value.

- `skip_tags` (string or array of strings) - Only plays, roles and tasks that [*do not match* these values will be executed](https://docs.ansible.com/playbooks_tags.html).

- `start_at_task` (string) - The task name where the [playbook execution will start](https://docs.ansible.com/playbooks_startnstep.html#start-at-task).

- `sudo` (boolean) - Cause Ansible to perform all the playbook tasks [using sudo](https://docs.ansible.com/glossary.html#sudo).

    The default value is `false`.

- `sudo_user` (string) - set the default username who should be used by the sudo command.

- `tags` (string or array of strings) - Only plays, roles and tasks [tagged with these values will be executed](https://docs.ansible.com/playbooks_tags.html) .

- `vault_password_file` (string) - The path of a file containing the password used by [Ansible Vault](https://docs.ansible.com/playbooks_vault.html#vault).

- `verbose` (boolean or string) - Set Ansible's verbosity to obtain detailed logging

    Default value is `false` (minimal verbosity).

    Examples: `true` (equivalent to `v`), `-vvv` (equivalent to `vvv`), `vvvv`.

    Note that when the `verbose` option is enabled, the `ansible-playbook` command used by Vagrant will be displayed.
