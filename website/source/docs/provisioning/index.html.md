---
layout: "docs"
page_title: "Provisioning"
sidebar_current: "provisioning"
description: |-
  Provisioners in Vagrant allow you to automatically install software, alter configurations, and more on the machine as part of the `vagrant up` process.
---

# Provisioning

Provisioners in Vagrant allow you to automatically install software, alter configurations,
and more on the machine as part of the `vagrant up` process.

This is useful since [boxes](/docs/boxes.html) typically are not
built _perfectly_ for your use case. Of course, if you want to just use
`vagrant ssh` and install the software by hand, that works. But by using
the provisioning systems built-in to Vagrant, it automates the process so
that it is repeatable. Most importantly, it requires no human interaction,
so you can `vagrant destroy` and `vagrant up` and have a fully ready-to-go
work environment with a single command. Powerful.

Vagrant gives you multiple options for provisioning the machine, from
simple shell scripts to more complex, industry-standard configuration
management systems.

If you've never used a configuration management system before, it is
recommended you start with basic [shell scripts](/docs/provisioning/shell.html)
for provisioning.

You can find the full list of built-in provisioners and usage of these
provisioners in the navigational area to the left.

## When Provisioning Happens

Provisioning happens at certain points during the lifetime of your
Vagrant environment:

* On the first `vagrant up` that creates the environment, provisioning is run.
  If the environment was already created and the up is just resuming a machine
  or booting it up, they will not run unless the `--provision` flag is explicitly
  provided.

* When `vagrant provision` is used on a running environment.

* When `vagrant reload --provision` is called. The `--provision` flag must
  be present to force provisioning.

You can also bring up your environment and explicitly _not_ run provisioners
by specifying `--no-provision`.
