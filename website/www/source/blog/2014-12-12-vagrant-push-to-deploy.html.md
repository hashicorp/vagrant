---
page_title: "Vagrant Push: One Command to Deploy Any Application"
title: "Vagrant Push: One Command to Deploy Any Application"
author: "Mitchell Hashimoto"
author_url: https://github.com/mitchellh
---

Vagrant 1.7 comes with a new command: `vagrant push`. Just as "vagrant up"
is a single command to create a development environment for any application,
`vagrant push` is a single command to _deploy_ any application.

The goal of Vagrant is to give developers a single workflow to develop
applications effectively. "vagrant up" creates a development environment for any
application and "vagrant share" enables collaboration for any application.
Deploying was the next logical step for Vagrant, now possible with
"vagrant push".

Like every other component of Vagrant, push can be configured using multiple
strategies. "vagrant push" can deploy via FTP, Heroku,
[Atlas](https://atlas.hashicorp.com), or by executing any local script.
Other strategies can be added via plugins and more will be added to core
as time goes on.

Read on to learn more.

READMORE

### Demo

We've prepared a short video showing Vagrant Push in action.

<iframe src="//player.vimeo.com/video/114328000" width="680" height="382" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

### Push to Deploy

`vagrant push` works like anything else in Vagrant: configure it in the
Vagrantfile, and it is immediately available to every developer. Push
configuration is simple and easy to understand:

```
config.push.define "ftp" do |push|
  push.host = "ftp.company.com"
  push.username = "username"
  push.password = "mypassword"
end
```

And then to push the application to the FTP or SFTP server:

```
$ vagrant push
...
```

The "ftp" in the configuration above defines the strategy Vagrant will
use to push. Below, we cover strategies in more detail.

Additionally, multiple `config.push.define` declarations can be in a Vagrantfile to
define multiple pushes, perhaps one to staging and one to production, for
example. To learn more about multiple push definitions,
[read the complete documentation](https://docs.vagrantup.com/v2/push/index.html).

### A Single Command

The biggest benefit of Vagrant Push is being able to define a single command
to deploy any application. Whether the deploy process is complex or
is just a simple push to Heroku, developers only need to know that any
application within their organizations can be deployed with `vagrant push`.

For complicated deploys, the benefit is obvious. For simpler deploys, such
as a push to Heroku, Vagrant Push is still useful. Besides not having
to know that Heroku is being used under the hood, Vagrant Push will
automatically configure your Git remote so the push works. Prior to this,
you'd at least have to know the Heroku application name and configure
your local repository to be able to push to it.

Of course, not all applications stay that simple, and if your application
outgrows Heroku, then the deploy process doesn't change with Vagrant:
`vagrant push` to deploy any application.

### Push Strategies

Like providers, provisioners, and other features in Vagrant, pushes can
be configured with multiple _strategies_. Vagrant 1.7 ships with four
strategies:

  * [Atlas](https://docs.vagrantup.com/v2/push/atlas.html) - Push application
      to [Atlas](https://atlas.hashicorp.com), a commercial
      product from HashiCorp.

  * [FTP/SFTP](https://docs.vagrantup.com/v2/push/ftp.html) - Upload files
      via FTP or SFTP to a remote server. This is great for static sites,
      PHP, etc.

  * [Heroku](https://docs.vagrantup.com/v2/push/heroku.html) - Push your
      Git repository to Heroku, and configure the Git remote for you if
      it doesn't already exist.

  * [Local Exec](https://docs.vagrantup.com/v2/push/local-exec.html) -
      Executes a local script on the system using a shell, deferring deployment
      logic to the user. This is for custom behavior or more complicated
      interactions with systems.

In addition to these built-in strategies, new strategies can be
[built just like any other Vagrant plugin](https://docs.vagrantup.com/v2/plugins/development-basics.html).
This allows 3rd parties to extend the capabilities of `vagrant push`, and
will surely result in future versions of Vagrant shipping with more push
strategies.

### Next

To learn all the details about Vagrant Push, please read the
[complete documentation](https://docs.vagrantup.com/v2/push/index.html).

This is a historic day for Vagrant. Vagrant 0.1 came out and defined
"vagrant up" to build a development environment for any application.
Vagrant 1.1 made it possible to have development environments on top of
any provider (VMware, Docker, etc.). Vagrant 1.5 introduced the "share"
command to collaborate. And now, Vagrant 1.7 completes the development
process with "push" to deploy.

The mission of Vagrant has been the same since day one: development
environments made easy. This mission spans any language choice, any
provider choice, and likewise any choice of how to deploy these
applications. Push continues this mission by adding a necessary
feature to the development workflow.

With Vagrant 1.7 available, we'll be blogging about more of the features
as well as creeping towards a 2.0!
