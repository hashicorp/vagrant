---
page_title: "Custom Hosts - Plugin Development"
sidebar_current: "plugins-hosts"
---

# Plugin Development: Hosts

This page documents how to add new host OS implementations to Vagrant,
allowing Vagrant to properly configure new host operating systems
for features such as NFS shared folders. Prior to reading this, you should be familiar
with the [plugin development basics](/v2/plugins/development-basics.html).

<div class="alert alert-warn">
	<p>
		<strong>Warning: Advanced Topic!</strong> Developing plugins is an
		advanced topic that only experienced Vagrant users who are reasonably
		comfortable with Ruby should approach.
	</p>
</div>

## Definition Component

Within the context of a plugin definition, new hosts can be defined
like so:

```ruby
host "some_os" do
  require_relative "host"
  Host
end
```

Guests are defined with the `host` method. The first argument is th
name of the host. This name isn't actually used anywhere, but may in
the future, so choose something helpful. Then, the block argument returns a
class that implements the `Vagrant.plugin(2, :host)` interface.

## Implementation

Implementations of hosts subclass `Vagrant.plugin(2, :host)`. Within
this implementation, various methods for different tasks must be implemented.
Instead of going over each task, the easiest example would be to take a
look at an existing host implementation.

There are [many host implementations](https://github.com/mitchellh/vagrant/tree/master/plugins/hosts),
but you can view the [BSD host implementation](https://github.com/mitchellh/vagrant/blob/master/plugins/hosts/bsd/host.rb) as a starting point.
