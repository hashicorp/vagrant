---
layout: "docs"
page_title: "Configuration Version - Vagrantfile"
sidebar_current: "vagrantfile-version"
description: |-
  Configuration versions are the mechanism by which Vagrant 1.1+ is able to
  remain backwards compatible with Vagrant 1.0.x Vagrantfiles, while introducing
  dramatically new features and configuration options.
---

# Configuration Version

Configuration versions are the mechanism by which Vagrant 1.1+ is able
to remain [backwards compatible](/docs/installation/backwards-compatibility.html)
with Vagrant 1.0.x Vagrantfiles, while introducing dramatically new features
and configuration options.

If you run `vagrant init` today, the Vagrantfile will be in roughly the
following format:

```ruby
Vagrant.configure("2") do |config|
  # ...
end
```

The `"2"` in the first line above represents the version of the configuration
object `config` that will be used for configuration for that block (the
section between the `do` and the `end`). This object can be very
different from version to version.

Currently, there are only two supported versions: "1" and "2". Version 1
represents the configuration from Vagrant 1.0.x. "2" represents the configuration
for 1.1+ leading up to 2.0.x.

When loading Vagrantfiles, Vagrant uses the proper configuration object
for each version, and properly merges them, just like any other configuration.

The important thing to understand as a general user of Vagrant is that
_within a single configuration section_, only a single version can be used.
You cannot use the new `config.vm.provider` configurations in a version 1
configuration section. Likewise, `config.vm.forward_port` will not work
in a version 2 configuration section (it was renamed).

If you want, you can mix and match multiple configuration versions in the
same Vagrantfile. This is useful if you found some useful configuration
snippet or something that you want to use. Example:

```ruby
Vagrant.configure("1") do |config|
  # v1 configs...
end

Vagrant.configure("2") do |config|
  # v2 configs...
end
```

<div class="alert alert-info">
  <strong>What is <code>Vagrant::Config.run</code>?</strong>
  You may see this in Vagrantfiles. This was actually how Vagrant 1.0.x
  did configuration. In Vagrant 1.1+, this is synonymous with
  <code>Vagrant.configure("1")</code>.
</div>
