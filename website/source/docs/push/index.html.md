---
layout: "docs"
page_title: "Vagrant Push"
sidebar_current: "push"
description: |-
  Vagrant Push is a revolutionary feature that allows users to push the code in
  their Vagrant environment to a remote location.
---

# Vagrant Push

As of version 1.7, Vagrant is capable of deploying or "pushing" application code
in the same directory as your Vagrantfile to a remote such as an FTP server.

Pushes are defined in an application's `Vagrantfile` and are invoked using the
`vagrant push` subcommand. Much like other components of Vagrant, each Vagrant
Push plugin has its own configuration options. Please consult the documentation
for your Vagrant Push plugin for more information. Here is an example Vagrant
Push configuration section in a `Vagrantfile`:

```ruby
config.push.define "ftp" do |push|
  push.host = "ftp.company.com"
  push.username = "..."
  # ...
end
```

When the application is ready to be deployed to the FTP server, just run a
single command:

```shell
$ vagrant push
```

Much like [Vagrant Providers][], Vagrant Push also supports multiple backend
declarations. Consider the common scenario of a staging and QA environment:

```ruby
config.push.define "staging", strategy: "ftp" do |push|
  # ...
end

config.push.define "qa", strategy: "ftp" do |push|
  # ...
end
```

In this scenario, the user must pass the name of the Vagrant Push to the
subcommand:

```shell
$ vagrant push staging
```

Vagrant Push is the easiest way to deploy your application. You can read more
in the documentation links on the sidebar.

[Vagrant Providers]: /docs/providers/  "Vagrant Providers"
