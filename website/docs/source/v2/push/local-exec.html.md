---
page_title: "Vagrant Push - Local Exec Strategy"
sidebar_current: "push-local-exec"
description: |-
  The Vagrant Push Heroku strategy pushes your application's code to Heroku.
  Only files which are committed to the Git repository are pushed to Heroku.
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

- `command` - The command to execute (as a string).


### Usage

The Vagrant Push Local Exec strategy is defined in the `Vagrantfile` using the
`local-exec` key:

```ruby
config.push.define "local-exec" do |push|
  push.command = <<-SCRIPT
    scp . /var/www/website
  SCRIPT
end
```

And then invoke the push with Vagrant:

```shell
$ vagrant push
```
