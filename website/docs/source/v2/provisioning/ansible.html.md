---
page_title: "Ansible - Provisioning"
sidebar_current: "provisioning-ansible"
---

# Ansible Provisioner

**Provisioner name: `"ansible"`**

The ansible provisioner allows you to provision the guest using
[Ansible](http://ansible.cc) playbooks.

Ansible playbooks are [YAML](http://en.wikipedia.org/wiki/YAML) documents that
comprise the set of steps to be orchestrated on one or more machines. This documentation
page will not go into how to use Ansible or how to write Ansible playbooks, since Ansible
is a complete deployment and configuration management system that is beyond the scope of
a single page of documentation.

<div class="alert alert-warn">
  <p>
    <strong>Warning:</strong> If you're not familiar with Ansible and Vagrant already,
    I recommend starting with the <a href="/v2/provisioning/shell.html">shell
    provisioner</a>. However, if you're comfortable with Vagrant already, Vagrant
    is a great way to learn Ansible.
  </p>
</div>

## Inventory File

When using Ansible, it needs to know on which machines a given playbook should run. It does
this by way of an inventory file which lists those machines. In the context of Vagrant,
there are two ways to approach working with inventory files. The first and simplest option
is to not provide one to Vagrant at all. Vagrant will generate inventory files for each
virtual machine it manages, and use them for provisioning machines. Generated inventory files
are created adjacent to your Vagrantfile, named using the machine names set in your Vagrantfile.

The second option is for situations where you'd like to have more than one virtual machine
in a single inventory file, perhaps leveraging more complex playbooks or inventory grouping.
If you provide the `ansible.inventory_path` option referencing a specific inventory file
dedicated to your Vagrant project, that one will be used instead of generating them.
Such an inventory file for use with Vagrant might look like:

```
[vagrant]
192.168.111.222
```

Where the above IP address is one set in your Vagrantfile:

```
config.vm.network :private_network, ip: "192.168.111.222"
```

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
- hosts: all
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
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
  end
end
```

This causes Vagrant to run the `playbook.yml` playbook against all hosts in the inventory file.
Since an Ansible playbook can include many files, you may also collect the related files in
a directory structure like this:

```
$ tree
.
|-- Vagrantfile
|-- provisioning
|   |-- group_vars
|           |-- all
|   |-- playbook.yml
```

In such an arrangement, the `ansible.playbook` path should be adjusted accordingly:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "provisioning/playbook.yml"
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
* `ansible.limit` can be set to a string or an array of machines or groups from the inventory file to further narrow down which hosts are affected.
* `ansible.verbose` can be set to increase Ansible's verbosity to obtain full detailed logging. By default, Vagrant uses Ansible default verbosity (`--verbose` or `-v`). By enabling this option following higher verbosity can be activated:
  * `'vv'`
  * `'vvv'`, also aliased as `'extra'`
* `ansible.tags` can be set to a string or an array of tags. Only plays, roles and tasks tagged with these values will be executed.
* `ansible.skip_tags` can be set to a string or an array of tags. Only plays, roles and tasks that *do not match* these values will be executed.
* `ansible.start_at_task` can be set to a string corresponding to the task name where the playbook provision will start.
* `ansible.raw_arguments` is an *unsafe wildcard* string that can be used to take advantage of `ansible-playbook` arguments that are not (yet) supported by this Vagrant provisioner plugin. This can be very useful when integrating with bleeding edge Ansible versions. Following precedence rules apply:
  * Any supported options (described above) will override conflicting `raw_arguments` value (e.g. `--tags` or `--start-at-task`)
  * Vagrant default user authentication can be overridden via `raw_arguments` (with custom values for `--user` and `--private-key`)
* `ansible.host_key_checking` can be set to `false` which will disable host key checking and prevent `"FAILED: (25, 'Inappropriate ioctl for device')"` errors from being reported during provisioner runs.  The default value is `true`, which matches the default behavior of Ansible 1.2.1 and later.
