---
page_title: "Ansible - Provisioning"
sidebar_current: "provisioning-ansible"
---

# Ansible Provisioner

**Provisioner name: `ansible`**

The Ansible provisioner allows you to provision the guest using [Ansible](http://ansible.com) playbooks by executing **`ansible-playbook` from the Vagrant host**.

<div class="alert alert-warn">
  <p>
    <strong>Warning:</strong> If you're not familiar with Ansible and Vagrant already,
    I recommend starting with the <a href="/v2/provisioning/shell.html">shell
    provisioner</a>. However, if you're comfortable with Vagrant already, Vagrant
    is a great way to learn Ansible.
  </p>
</div>

## Setup Requirements

  - **[Install Ansible](http://docs.ansible.com/intro_installation.html#installing-the-control-machine) on your Vagrant host**.

  - Your Vagrant host should ideally provide a recent version of OpenSSH that [supports ControlPersist](http://docs.ansible.com/faq.html#how-do-i-get-ansible-to-reuse-connections-enable-kerberized-ssh-or-have-ansible-pay-attention-to-my-local-ssh-config-file).

If installing Ansible directly on the Vagrant host is not an option in your development environment, you might be looking for the <a href="/v2/provisioning/ansible_local.html">Ansible Local provisioner</a> alternative.

## Usage

This page only documents the specific parts of the `ansible` (remote) provisioner. General Ansible concepts like Playbook or Inventory are shortly explained in the [introduction to Ansible and Vagrant](/v2/provisioning/ansible_intro.html).

### Simplest Configuration

To run Ansible against your Vagrant guest, the basic `Vagrantfile` configuration looks like:

```ruby
Vagrant.configure(2) do |config|

  #
  # Run Ansible from the Vagrant Host
  #
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
  end

end
```

##  Options

This section lists the specific options for the Ansible (remote) provisioner. In addition to the options listed below, this provisioner supports the [common options for both Ansible provisioners](/v2/provisioning/ansible_common.html).

- `ask_sudo_pass` (boolean) - require Ansible to [prompt for a sudo password](http://docs.ansible.com/intro_getting_started.html#remote-connection-information).

  The default value is `false`.

- `ask_vault_pass` (boolean) - require Ansible to [prompt for a vault password](http://docs.ansible.com/playbooks_vault.html#vault).

  The default value is `false`.

- `host_key_checking` (boolean) - require Ansible to [enable SSH host key checking](http://docs.ansible.com/intro_getting_started.html#host-key-checking).

  The default value is `false`.

- `raw_ssh_args` (array of strings) - require Ansible to apply a list of OpenSSH client options.

  Example: `['-o ControlMaster=no']`.

  It is an *unsafe wildcard* that can be used to pass additional SSH settings to Ansible via `ANSIBLE_SSH_ARGS` environment variable, overriding any other SSH arguments (e.g. defined in an [`ansible.cfg` configuration file](http://docs.ansible.com/intro_configuration.html#ssh-args)).

## Tips and Tricks

### Ansible Parallel Execution

Vagrant is designed to provision [multi-machine environments](/v2/multi-machine) in sequence, but the following configuration pattern can be used to take advantage of Ansible parallelism:

```
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
        ansible.limit = 'all'
        ansible.playbook = "playbook.yml"

      end
    end

  end
end
```

**Caveats:**

If you apply this parallel provisioning pattern with a static Ansible inventory, you'll have to organize the things so that [all the relevant private keys are provided to the `ansible-playbook` command](https://github.com/mitchellh/vagrant/pull/5765#issuecomment-120247738). The same kind of considerations applies if you are using multiple private keys for a same machine (see [`config.ssh.private_key_path` SSH setting](/v2/vagrantfile/ssh_settings.html)).

### Troubleshooting SSH Connection Errors

It is good to know that the following Ansible settings always override the `config.ssh.username` option defined in [Vagrant SSH Settings](/v2/vagrantfile/ssh_settings.html):

* `ansible_ssh_user` variable
* `remote_user` (or `user`) play attribute
* `remote_user` task attribute

Be aware that copying snippets from the Ansible documentation might lead to this problem, as `root` is used as the remote user in many [examples](http://docs.ansible.com/playbooks_intro.html#hosts-and-users).

Example of an SSH error (with `vvv` log level), where an undefined remote user `xyz` has replaced `vagrant`:

```
TASK: [my_role | do something] *****************
<127.0.0.1> ESTABLISH CONNECTION FOR USER: xyz
<127.0.0.1> EXEC ['ssh', '-tt', '-vvv', '-o', 'ControlMaster=auto',...
fatal: [ansible-devbox] => SSH encountered an unknown error. We recommend you re-run the command using -vvvv, which will enable SSH debugging output to help diagnose the issue.
```

In a situation like the above, to override the `remote_user` specified in a play you can use the following line in your Vagrantfile `vm.provision` block:

```
ansible.extra_vars = { ansible_ssh_user: 'vagrant' }
```

### Force Paramiko Connection Mode

The Ansible provisioner is implemented with native OpenSSH support in mind, and there is no official support for [paramiko](https://github.com/paramiko/paramiko/) (A native Python SSHv2 protocol library).

If you really need to use this connection mode, it is though possible to enable paramiko as illustrated in the following configuration examples:

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