---
layout: getting_started
title: Getting Started - Why Vagrant?

current: Why Vagrant?
previous: Overview
previous_url: /docs/getting-started/index.html
next: Introduction
next_url: /docs/getting-started/introduction.html
---
# Why Vagrant?

Web developers use virtual environments every day with their web applications. From EC2 and Rackspace Cloud to specialized
solutions such as EngineYard and Heroku, virtualization is the tool of choice for easy deployment and infrastructure management.
Vagrant aims to take those very same principles and put them to work in the heart of the application lifecycle.
By providing easy to configure, lightweight, reproducible, and portable virtual machines targeted at
development environments, Vagrant helps maximize the productivity and flexibility of you and your team.

Vagrant is a development tool which stands on the shoulders of giants, using tried and
proven technologies to achieve its magic. Vagrant uses [Oracle's VirtualBox](http://www.virtualbox.org)
to create its virtual machines and then uses [Chef](http://www.opscode.com/chef) or [Puppet](http://www.puppetlabs.com/puppet)  to provision them.

## Benefits of Using Vagrant

### For Solo Developers

Maintaining consistent development environments over multiple projects is simply an
unfeasible task for a modern web developer. Each project depends on its own libraries,
message queue systems, databases, frameworks, and more, each with their own versions.
In addition to the dependencies, running all these on a single home machine and remembering
to turn it all off at the end of the day or when working on other projects is also unfeasible.
Vagrant gives you the tools to build unique development environments for each project once
and then easily tear them down and rebuild them only when they're needed so you can save
time and frustration.

### For Teams

Each member of a team ideally has identical development environments: same dependencies, same
versions, same configurations, same everything. But this is simply not true today. With database
agnostic ORMs, multiple web server options, and fast-moving libraries, one team member may be using
MySQL with one version of a library while another team member may be using PostgreSQL with another
version of the same library. Or perhaps one team member's configuration for their server is slightly
different. These are all real cases which are bound to cause real issues at some point down the road.
Vagrant gives teams the ability to enforce a consistent and portable
virtual development environment that is easy to create and quick to setup.

### For Companies

If you've ever maintained a large web application, one of the hardest parts is onboarding new resources.
Message queues, caching, database servers and other infrastructure pieces mean a lot of installation
and a lot more configuration (see [case-in-point: insanity](http://www.robbyonrails.com/articles/2010/02/08/installing-ruby-on-rails-passenger-postgresql-mysql-oh-my-zsh-on-snow-leopard-fourth-edition)). Vagrant gives you the tools to build a development environment once and then easily distribute it to
new members of your development team so you can get them to work and saving time, money and frustration.
