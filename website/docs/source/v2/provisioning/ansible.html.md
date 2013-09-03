---
sidebar_current: "provisioning-ansible"
---

# Ansible Provisioner

**Provisioner name: `:ansible`**

The ansible provisioner allows you to provision the guest using
[Ansible](http://ansible.cc) playbooks.

Ansible playbooks are [YAML](http://en.wikipedia.org/wiki/YAML) documents that
comprise the set of steps to be orchestrated on one or more machines. This documentation
page will not go into how to use Ansible or how to write Ansible playbooks, since Ansible
is a complete deployment and configuration management system that is beyond the scope of
a single page of documentation.

## Inventory File

Out of the box, Ansible can control with multiple systems in your infrastructure at the
same time. It does this by selecting portions of systems listed in Ansible's inventory
INI formatted file, which defaults to being located at `/etc/ansible/hosts`. This same
file can be used with Vagrant, or the `ansible.inventory_file` option can be specified to
direct Vagrant to use an inventory file dedicated to your Vagrant project. Using this option
is recommended to avoid accidentally running playbooks against live infrastructure. A simple
inventory file for use with Vagrant might look like:

```
[vagrant]
192.168.111.222
```

Where the above IP address is one set in your Vagrantfile:

```
config.vm.network :private_network, ip: "192.168.111.222"
```

(While Vagrant does have the IP address of your VM, entering it into an Ansible inventory
file is preferred so that Ansible's `group_vars` and `host_vars` can be used; Their location
is derived from the location of the inventory file.)

## Playbook

The second component of a successful Ansible provisioner setup is the Ansible playbook
which contains the steps that should be run on the guest. Ansible's
[playbook documentation](http://ansible.cc/docs/playbooks.html) goes into great
detail on how to author playbooks, and there are a number of
[best practices](http://ansible.cc/docs/bestpractices.html) that can be applied to use
Ansible's powerful features effectively. A playbook that installs and starts (or restarts 
if it was updated) the NTP daemon via YUM looks like:

```
---
- hosts: vagrant
  tasks:
    - name: ensure ntpd is at the latest version
      yum: pkg=ntp state=latest
      notify:
      - restart ntpd
  handlers:
    - name: restart ntpd
      service: name=ntpd state=restarted
```

You can of course target other operating systems that don't have YUM by changing the
playbook tasks. Ansible ships with a number of [modules](http://ansible.cc/docs/modules.html)
that make running otherwise tedious tasks dead simple.

## Running Ansible

To run Ansible against your Vagrant guest, the basic Vagrantfile configuration looks like:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision :ansible do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.inventory_file = "ansible_hosts"
  end
end
```

This causes Vagrant to run the `playbook.yml` playbook against the `vagrant` group in the
`ansible_hosts` file, both of which are adjacent to the Vagrantfile. Since an Ansible playbook
can include many files, you may also collect the related files in a directory structure like this:

```
$ tree
.
|-- Vagrantfile
|-- provisioning
|   |-- ansible_hosts
|   |-- group_vars
|           |-- vagrant
|   |-- playbook.yml
```

In such an arrangement, the `ansible.playbook` and `ansible.inventory_file` options should be
adjusted accordingly:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision :ansible do |ansible|
    ansible.playbook = "provisioning/playbook.yml"
    ansible.inventory_file = "provisioning/ansible_hosts"
  end
end
```

## Additional Options

The Ansible provisioner also includes a number of additional options that can be set,
all of which get passed to the `ansible-playbook` command that ships with Ansible.

* `ansible.extra_vars` can be used to pass a hash of additional variables to the playbook. For example:
```
ansible.extra_vars = {
  ntp_server: "pool.ntp.org",
  nginx_workers: 4
}
```
These variables take the highest precedence over any other variables.
* `ansible.sudo` can be set to `true` to cause Ansible to perform commands using sudo.
* `ansible.sudo_user` can be set to a string containing a username on the guest who should be used
by the sudo command.
* `ansible.ask_sudo_pass` can be set to `true` to require Ansible to prompt for a sudo password.
* `ansible.limit` can be set to a string or an array of machines or groups from the inventory file
to further narrow down which hosts are affected. This option is best used in the case where you
are using an inventory file containing more than just the Vagrant guest.
* `ansible.verbose` can be set to `true` to increase Ansible's verbosity to obtain more detailed logging
during playbook execution.
