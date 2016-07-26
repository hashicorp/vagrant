---
layout: "docs"
page_title: "Vagrant Push - Heroku Strategy"
sidebar_current: "push-heroku"
description: |-
  The Vagrant Push Heroku strategy pushes your application's code to Heroku.
  Only files which are committed to the Git repository are pushed to Heroku.
---

# Vagrant Push

## Heroku Strategy

[Heroku][] is a public PAAS provider that makes it easy to deploy an
application. The Vagrant Push Heroku strategy pushes your application's code to
Heroku.

<div class="alert alert-warning">
  <strong>Warning:</strong> The Vagrant Push Heroku strategy requires you
  have configured your Heroku credentials and created the Heroku application.
  This documentation will not cover these prerequisites, but you can read more
  about them in the <a href="https://devcenter.heroku.com">Heroku documentation</a>.
</div>

Only files which are committed to the Git repository will be pushed to Heroku.
Additionally, the current working branch is always pushed to the Heroku, even if
it is not the "master" branch.

The Vagrant Push Heroku strategy supports the following configuration options:

- `app` - The name of the Heroku application. If the Heroku application does not
  exist, an exception will be raised. If this value is not specified, the
  basename of the directory containing the `Vagrantfile` is assumed to be the
  name of the Heroku application. Since this value can change between users, it
  is highly recommended that you add the `app` setting to your `Vagrantfile`.

- `dir` - The base directory containing the Git repository to upload to Heroku.
  By default this is the same directory as the Vagrantfile, but you can specify
  this if you have a nested Git directory.

- `remote` - The name of the Git remote where Heroku is configured. The default
  value is "heroku".


### Usage

The Vagrant Push Heroku strategy is defined in the `Vagrantfile` using the
`heroku` key:

```ruby
config.push.define "heroku" do |push|
  push.app = "my_application"
end
```

And then push the application to Heroku:

```shell
$ vagrant push
```

[Heroku]: https://heroku.com/  "Heroku"
