---
page_title: "Provisioning"
sidebar_current: "provisioning"
---

# Provisioning

Provisioners in Vagrant allow you to automatically install software, alter configurations,
and more on the machine as part of the `vagrant up` process.

This is useful since [boxes](/v2/boxes.html) typically aren't
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
recommended you start with basic [shell scripts](/v2/provisioning/shell.html)
for provisioning.

You can find the full list of built-in provisioners and usage of these
provisioners in the navigational area to the left.
