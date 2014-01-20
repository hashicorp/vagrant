---
page_title: "Vagrant Stability and Upgrades"
title: "Vagrant Stability and Upgrades"
author: Mitchell Hashimoto
author_url: https://github.com/mitchellh
---

At nearly four years old, Vagrant is considered mature and stable software.
Thousands of individuals depend on Vagrant every day to provide
a stable working environment, crucial to their productivity. We pride ourselves
on shipping software that can stand up to this requirement.

Even so, we've noticed an unacceptable trend of "upgrade pains" whenever
a major new version of Vagrant is released. In every case, once Vagrant is
working, it is very stable. However, after an upgrade, the fact some environments
have to be "fixed" is not okay.

A big focus of the project for the past couple months has been improving
stability, especially upgrade stability. In this post, I'd like to discuss
some of the changes we've made so you can be confident that Vagrant upgrades
won't break things for you.

READMORE

### Unit Tests

First, unit test coverage within Vagrant itself has increased nearly 20%
since 1.4.0. The unit test coverage has always been very good across the
core of Vagrant. However, the test coverage of the core plugins (which power
all the commands, providers, provisioners, etc.) has been very bad.

For
Vagrant 1.5, we took a policy of not accepting any changes without associated
tests, either written by the contributor or a core contributor. This policy
improved unit test coverage greatly, and these new tests have already caught
a handful of what would have been subtle upgrade bugs.

### Vagrant-Spec

Next, I've personally focused a large amount of effort on the
[vagrant-spec](https://github.com/mitchellh/vagrant-spec) project. This
project is a black-box acceptance test suite for Vagrant. Given a path to
some boxes and a Vagrant executable, it verifies that various features of
Vagrant work completely using an outside-in approach.

The vagrant-spec project tests basic commands, managing boxes, managing
plugins, provisioners, synced folder types, etc. It tests all these features
across multiple providers. The goal of the project
is to eventually have tests covering all options of Vagrant.

As we work on features, we run Vagrant against vagrant-spec to verify
the behavior is still valid. And before any release, we run the complete
vagrant-spec suite against boxes for a variety of operating systems to
verify that Vagrant is functioning as it should.

### Longer Deprecation Cycles

Although we've made it clear that we may
[break compatibility](http://docs.vagrantup.com/v2/installation/backwards-compatibility.html)
of Vagrantfiles for 1.x until 2.0 is final, we've only introduces a couple
backwards incompatibilities. However, when we have introduced them, we've been
pretty abrupt about removing the old features.

Starting with 1.5, we're first deprecating features before outright removing
them. The deprecated features will show a warning when Vagrant is run. These
features will be removed in a following version of Vagrant.

### Smoother Upgrades

With the above three changes put together, upgrading Vagrant should be a
smooth, painless process. If there are any pains upgrading future
Vagrant versions, please
[report a bug](https://github.com/mitchellh/vagrant/issues).

We've always taken stability very seriously and as the number of people
using Vagrant grows, it becomes even more important to keep Vagrant working.
