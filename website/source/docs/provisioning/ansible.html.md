---
layout: "docs"
page_title: "Ansible - Provisioning"
sidebar_current: "provisioning-ansible"
description: |-
  The Vagrant Ansible provisioner allows you to provision the guest using
  Ansible playbooks by executing "ansible-playbook" from the Vagrant host.
---

# Ansible Provisioner

**Provisioner name: `ansible`**

The Vagrant Ansible provisioner allows you to provision the guest using [Ansible](http://ansible.com) playbooks by executing **`ansible-playbook` from the Vagrant host**.

<div class="alert alert-warning">
  <strong>Warning:</strong>
  If you are not familiar with Ansible and Vagrant already, I recommend starting with the <a href="/docs/provisioning/shell.html">shell provisioner</a>. However, if you are comfortable with Vagrant already, Vagrant is a great way to learn Ansible.
</div>

## Setup Requirements

  - **[Install Ansible](https://docs.ansible.com/intro_installation.html#installing-the-control-machine) on your Vagrant host**.

  - Your Vagrant host should ideally provide a recent version of OpenSSH that [supports ControlPersist](https://docs.ansible.com/faq.html#how-do-i-get-ansible-to-reuse-connections-enable-kerberized-ssh-or-have-ansible-pay-attention-to-my-local-ssh-config-file).

If installing Ansible directly on the Vagrant host is not an option in your development environment, you might be looking for the <a href="/docs/provisioning/ansible_local.html">Ansible Local provisioner</a> alternative.

## Usage

This page only documents the specific parts of the `ansible` (remote) provisioner. General Ansible concepts like Playbook or Inventory are shortly explained in the [introduction to Ansible and Vagrant](/docs/provisioning/ansible_intro.html).

### Simplest Configuration

To run Ansible against your Vagrant guest, the basic `Vagrantfile` configuration looks like:

```ruby
Vagrant.configure("2") do |config|

  #
  # Run Ansible from the Vagrant Host
  #
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
  end

end
```

##  Options

This section lists the _specific_ options for the Ansible (remote) provisioner. In addition to the options listed below, this provisioner supports the [**common options** for both Ansible provisioners](/docs/provisioning/ansible_common.html).

- `ask_become_pass` (boolean) - require Ansible to [prompt for a password](https://docs.ansible.com/intro_getting_started.html#remote-connection-information) when switching to another user with the [become/sudo mechanism](http://docs.ansible.com/ansible/become.html).

    The default value is `false`.

- `ask_sudo_pass` (boolean) - Backwards compatible alias for the [ask_become_pass](#ask_become_pass) option.

    <div class="alert alert-warning">
      <strong>Deprecation:</strong>
      The `ask_sudo_pass` option is deprecated and will be removed in a future release. Please use the [**`ask_become_pass`**](#ask_become_pass) option instead.
    </div>

- `ask_vault_pass` (boolean) - require Ansible to [prompt for a vault password](https://docs.ansible.com/playbooks_vault.html#vault).

    The default value is `false`.

- `force_remote_user` (boolean) - require Vagrant to set the `ansible_ssh_user` setting in the generated inventory, or as an extra variable when a static inventory is used. All the Ansible `remote_user` parameters will then be overridden by the value of `config.ssh.username` of the [Vagrant SSH Settings](/docs/vagrantfile/ssh_settings.html).

    If this option is set to `false` Vagrant will set the Vagrant SSH username as a default Ansible remote user, but `remote_user` parameters of your Ansible plays or tasks will still be taken into account and thus override the Vagrant configuration.

    The default value is `true`.

    <div class="alert alert-info">
      <strong>Compatibility Note:</strong>
      This option was introduced in Vagrant 1.8.0. Previous Vagrant versions behave like if this option was set to `false`.
    </div>

- `host_key_checking` (boolean) - require Ansible to [enable SSH host key checking](https://docs.ansible.com/intro_getting_started.html#host-key-checking).

    The default value is `false`.

- `raw_ssh_args` (array of strings) - require Ansible to apply a list of OpenSSH client options.

    Example: `['-o ControlMaster=no']`.

    It is an *unsafe wildcard* that can be used to pass additional SSH settings to Ansible via `ANSIBLE_SSH_ARGS` environment variable, overriding any other SSH arguments (e.g. defined in an [`ansible.cfg` configuration file](https://docs.ansible.com/intro_configuration.html#ssh-args)).

## Tips and Tricks

### Ansible Parallel Execution

Vagrant is designed to provision [multi-machine environments](/docs/multi-machine) in sequence, but the following configuration pattern can be used to take advantage of Ansible parallelism:

```ruby
# Vagrant 1.7+ automatically inserts a different
# insecure keypair for each new VM created. The easiest way
# to use the same keypair for all the machines is to disable
# this feature and rely on the legacy insecure key.
# config.ssh.insert_key = false
#
# Note:
# As of Vagrant 1.7.3, it is no longer necessary to disable
# the keypair creation when using the auto-generated inventory.

N = 3
(1..N).each do |machine_id|
  config.vm.define "machine#{machine_id}" do |machine|
    machine.vm.hostname = "machine#{machine_id}"
    machine.vm.network "private_network", ip: "192.168.77.#{20+machine_id}"

    # Only execute once the Ansible provisioner,
    # when all the machines are up and ready.
    if machine_id == N
      machine.vm.provision :ansible do |ansible|
        # Disable default limit to connect to all the machines
        ansible.limit = "all"
        ansible.playbook = "playbook.yml"
      end
    end
  end
end
```

<div class="alert alert-info">
  <strong>Tip:</strong>
  If you apply this parallel provisioning pattern with a static Ansible inventory, you will have to organize the things so that [all the relevant private keys are provided to the `ansible-playbook` command](https://github.com/mitchellh/vagrant/pull/5765#issuecomment-120247738). The same kind of considerations applies if you are using multiple private keys for a same machine (see [`config.ssh.private_key_path` SSH setting](/docs/vagrantfile/ssh_settings.html)).
</div>

### Force Paramiko Connection Mode

The Ansible provisioner is implemented with native OpenSSH support in mind, and there is no official support for [paramiko](https://github.com/paramiko/paramiko/) (A native Python SSHv2 protocol library).

If you really need to use this connection mode though, it is possible to enable paramiko as illustrated in the following configuration examples:

With auto-generated inventory:

```
ansible.raw_arguments = ["--connection=paramiko"]
```

With a custom inventory, the private key must be specified (e.g. via an `ansible.cfg` configuration file, `--private-key` argument, or as part of your inventory file):

```
ansible.inventory_path = "./my-inventory"
ansible.raw_arguments  = [
  "--connection=paramiko",
  "--private-key=/home/.../.vagrant/machines/.../private_key"
]
```
