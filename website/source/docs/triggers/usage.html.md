---
layout: "docs"
page_title: "Vagrant Triggers Usage"
sidebar_current: "triggers-usage"
description: |-
  Various Vagrant Triggers examples
---

# Basic Usage

Below are some very simple examples of how to use Vagrant Triggers.

## Examples

The following is a basic example of two global triggers. One that runs _before_
the `:up` command and one that runs _after_ the `:up` command:

```ruby
Vagrant.configure("2") do |config|
  config.trigger.before :up do |trigger|
    trigger.name = "Hello world"
    trigger.info = "I am running before vagrant up!!"
  end

  config.trigger.before :up do |trigger|
    trigger.name = "Hello world"
    trigger.info = "I am running after vagrant up!!"
  end

  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "ubuntu"
  end
end
```

These will run before and after each defined guest in the Vagrantfile.

Running a remote script to save a database on your host before __destroy__ing a
guest:

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "ubuntu"

    ubuntu.trigger.before :destroy do |trigger|
      trigger.warn = "Dumping database to /vagrant/outfile"
      trigger.run_remote = {inline: "pg_dump dbname > /vagrant/outfile"}
    end
  end
end
```

Now that the trigger is defined, running the __destroy__ command will fire off
the defined trigger before Vagrant destroys the machine.

```shell
$ vagrant destroy ubuntu
```

An example of defining three triggers that start and stop tinyproxy on your host
machine using homebrew:

```shell
#/bin/bash
# start-tinyproxy.sh
brew services start tinyproxy
```

```shell
#/bin/bash
# stop-tinyproxy.sh
brew services stop tinyproxy
```

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "ubuntu"

    ubuntu.trigger.before :up do |trigger|
      trigger.info = "Starting tinyproxy..."
      trigger.run = {path: "start-tinyproxy.sh"}
    end

    ubuntu.trigger.after :destroy, :halt do |trigger|
      trigger.info = "Stopping tinyproxy..."
      trigger.run = {path: "stop-tinyproxy.sh"}
    end
  end
end
```

Running `vagrant up` would fire the before trigger to start tinyproxy, where as
running either `vagrant destroy` or `vagrant halt` would stop tinyproxy.
