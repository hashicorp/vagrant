---
layout: "docs"
page_title: "Ansible Local - Provisioning"
sidebar_current: "provisioning-ansible-local"
description: |-
  The Vagrant Ansible Local provisioner allows you to provision the guest using Ansible playbooks by executing "ansible-playbook" directly on the guest
  machine.
---

# Ansible Local Provisioner

**Provisioner name: `ansible_local`**

The Vagrant Ansible Local provisioner allows you to provision the guest using [Ansible](http://ansible.com) playbooks by executing **`ansible-playbook` directly on the guest machine**.

<div class="alert alert-warning">
  <strong>Warning:</strong> If you are not familiar with Ansible and Vagrant already,
  I recommend starting with the <a href="/docs/provisioning/shell.html">shell
  provisioner</a>. However, if you are comfortable with Vagrant already, Vagrant
  is a great way to learn Ansible.
</div>

## Setup Requirements

The main advantage of the Ansible Local provisioner in comparison to the [Ansible (remote) provisioner](/docs/provisioning/ansible.html) is that it does not require any additional software on your Vagrant host.

On the other hand, [Ansible must obviously be installed](https://docs.ansible.com/intro_installation.html#installing-the-control-machine) on your guest machine(s).

**Note:** By default, Vagrant will *try* to automatically install Ansible if it is not yet present on the guest machine (see the `install` option below for more details).

## Usage

This page only documents the specific parts of the `ansible_local` provisioner. General Ansible concepts like Playbook or Inventory are shortly explained in the [introduction to Ansible and Vagrant](/docs/provisioning/ansible_intro.html).

The Ansible Local provisioner requires that all the Ansible Playbook files are available on the guest machine, at the location referred by the `provisioning_path` option. Usually these files are initially present on the host machine (as part of your Vagrant project), and it is quite easy to share them with a Vagrant [Synced Folder](/docs/synced-folders/).

### Simplest Configuration

To run Ansible from your Vagrant guest, the basic `Vagrantfile` configuration looks like:

```ruby
Vagrant.configure(2) do |config|
  # Run Ansible from the Vagrant VM
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "playbook.yml"
  end
end
```

**Requirements:**

  - The `playbook.yml` file is stored in your Vagrant's project home directory.

  - The [default shared directory](/docs/synced-folders/basic_usage.html) is enabled (`.` &rarr; `/vagrant`).

## Options

This section lists the specific options for the Ansible Local provisioner. In addition to the options listed below, this provisioner supports the [common options for both Ansible provisioners](/docs/provisioning/ansible_common.html).

- `install` (boolean) - Try to automatically install Ansible on the guest system.

  This option is enabled by default.

  Vagrant will to try to install (or upgrade) Ansible when one of these conditions are met:

    - Ansible is not installed (or cannot be found).

    - The `version` option is set to `"latest"`.

    - The current Ansible version does not correspond to the `version` option.

  **Attention:** There is no guarantee that this automated installation will replace a custom Ansible setup, that might be already present on the Vagrant box.

- `provisioning_path` (string) - An absolute path on the guest machine where the Ansible files are stored. The `ansible-playbook` command is executed from this directory.

  The default value is `/vagrant`.

- `tmp_path` (string) - An absolute path on the guest machine where temporary files are stored by the Ansible Local provisioner.

  The default value is `/tmp/vagrant-ansible`

- `version` (string) - The expected Ansible version.

  This option is disabled by default.

  When an Ansible version is defined (e.g. `"1.8.2"`), the Ansible local provisioner will be executed only if Ansible is installed at the requested version.

  When this option is set to `"latest"`, no version check is applied.

  **Attention:** It is currently not possible to use this option to specify which version of Ansible must be automatically installed. With the `install` option enabled, the latest version packaged for the target operating system will always be installed.

## Tips and Tricks

### Ansible Parallel Execution from a Guest

With the following configuration pattern, you can install and execute Ansible only on a single guest machine (the `"controller"`) to provision all your machines.

```ruby
Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/trusty64"

  config.vm.define "node1" do |machine|
    machine.vm.network "private_network", ip: "172.17.177.21"
  end

  config.vm.define "node2" do |machine|
    machine.vm.network "private_network", ip: "172.17.177.22"
  end

  config.vm.define 'controller' do |machine|
    machine.vm.network "private_network", ip: "172.17.177.11"

    machine.vm.provision :ansible_local do |ansible|
      ansible.playbook       = "example.yml"
      ansible.verbose        = true
      ansible.install        = true
      ansible.limit          = "all" # or only "nodes" group, etc.
      ansible.inventory_path = "inventory"
    end
  end

end
```

You need to create a static `inventory` file that corresponds to your `Vagrantfile` machine definitions:

```
controller ansible_connection=local
node1      ansible_ssh_host=172.17.177.21 ansible_ssh_private_key_file=/vagrant/.vagrant/machines/node1/virtualbox/private_key
node2      ansible_ssh_host=172.17.177.22 ansible_ssh_private_key_file=/vagrant/.vagrant/machines/node2/virtualbox/private_key

[nodes]
node[1:2]
```

And finally, you also have to create an [`ansible.cfg` file](https://docs.ansible.com/intro_configuration.html#openssh-specific-settings) to fully disable SSH host key checking. More SSH configurations can be added to the `ssh_args` parameter (e.g. agent forwarding, etc.)

```
[defaults]
host_key_checking = no

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
```
