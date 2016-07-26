---
layout: "docs"
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

<div class="alert alert-warning">
  <strong>Warning:</strong> The Vagrant Push Local Exec strategy does not
  perform any validation on the correctness of the shell script.
</div>

The Vagrant Push Local Exec strategy supports the following configuration
options:

- `script` - The path to a script on disk (relative to the `Vagrantfile`) to
  execute. Vagrant will attempt to convert this script to an executable, but an
  exception will be raised if that fails.
- `inline` - The inline script to execute (as a string).
- `args` (string or array) - Optional arguments to pass to the shell script when executing it
  as a single string. These arguments must be written as if they were typed
  directly on the command line, so be sure to escape characters, quote,
  etc. as needed. You may also pass the arguments in using an array. In this
  case, Vagrant will handle quoting for you.

Please note - only one of the `script` and `inline` options may be specified in
a single push definition.

### Usage

The Vagrant Push Local Exec strategy is defined in the `Vagrantfile` using the
`local-exec` key:

Remote path:

```ruby
config.push.define "local-exec" do |push|
  push.inline = <<-SCRIPT
    scp -r . server:/var/www/website
  SCRIPT
end
```

Local path:

```ruby
config.push.define "local-exec" do |push|
  push.inline = <<-SCRIPT
    cp -r . /var/www/website
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

### Script Arguments

Refer to [Shell Provisioner](/docs/provisioning/shell.html).
