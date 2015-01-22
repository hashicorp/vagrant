---
page_title: "Vagrant Push - Local Exec Strategy"
sidebar_current: "push-local-exec"
description: |-
  The Vagrant Push Local Exec strategy pushes your application's code using a
  user-defined script.
---

# Vagrant Push

## Local Exec Strategy

The Vagrant Push Local Exec strategy allows the user to invoke an arbitrary
shell command or script as part of a push.

<div class="alert alert-warn">
  <p>
    <strong>Warning:</strong> The Vagrant Push Local Exec strategy does not
    perform any validation on the correctness of the shell script.
  </p>
</div>

The Vagrant Push Local Exec strategy supports the following configuration
options:

- `script` - The path to a script on disk (relative to the `Vagrantfile`) to
  execute. Vagrant will attempt to convert this script to an executable, but an
  exception will be raised if that fails.
- `inline` - The inline script to execute (as a string).

Please note - only one of the `script` and `inline` options may be specified in
a single push definition.

### Usage

The Vagrant Push Local Exec strategy is defined in the `Vagrantfile` using the
`local-exec` key:

```ruby
config.push.define "local-exec" do |push|
  push.inline = <<-SCRIPT
    scp . /var/www/website
  SCRIPT
end
```

For more complicated scripts, you may store them in a separate file and read
them from the `Vagrantfile` like so:

```ruby
config.push.define "local-exec" do |push|
  push.script = "my-script.sh"
end
```

And then invoke the push with Vagrant:

```shell
$ vagrant push
```
