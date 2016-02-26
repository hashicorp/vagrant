---
layout: "docs"
page_title: "Tips & Tricks - Vagrantfile"
sidebar_current: "vagrantfile-tips"
description: |-
  The Vagrantfile is a very flexible configuration format. Since it is just
  Ruby, there is a lot you can do with it. However, in that same vein, since
  it is Ruby, there are a lot of ways you can shoot yourself in the foot. When
  using some of the tips and tricks on this page, please take care to use them
  correctly.
---

# Tips & Tricks

The Vagrantfile is a very flexible configuration format. Since it is just
Ruby, there is a lot you can do with it. However, in that same vein, since
it is Ruby, there are a lot of ways you can shoot yourself in the foot. When
using some of the tips and tricks on this page, please take care to use them
correctly.

## Loop Over VM Definitions

If you want to apply a slightly different configuration to many
multi-machine machines, you can use a loop to do this. For example, if
you wanted to create three machines:

```ruby
(1..3).each do |i|
  config.vm.define "node-#{i}" do |node|
    node.vm.provision "shell",
      inline: "echo hello from node #{i}"
  end
end
```

~> **Warning:** The inner portion of multi-machine definitions
and provider overrides are lazy-loaded. This can cause issues if you change
the value of a variable used within the configs. For example, the loop below
<em>does not work</em>:

```ruby
# THIS DOES NOT WORK!
for i in 1..3 do
  config.vm.define "node-#{i}" do |node|
    node.vm.provision "shell",
      inline: "echo hello from node #{i}"
  end
end
```

The `for i in  ...` construct in Ruby actually modifies the value of `i`
for each iteration, rather than making a copy. Therefore, when you run this,
every node will actually provision with the same text.

This is an easy mistake to make, and Vagrant cannot really protect against it,
so the best we can do is mention it here.

## Overwrite host locale in ssh session

Usually, host locale environment variables are passed to guest. It may cause
failures if the guest software do not support host locale. One possible solution
is override locale in the `Vagrantfile`:

```ruby
ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure("2") do |config|
  # ...
end
```

The change is only visible within the `Vagrantfile`.
