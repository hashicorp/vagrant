---
layout: "vagrant-cloud"
page_title: "Box Versioning and Lifecycle"
sidebar_current: "vagrant-cloud-boxes-lifecycle"
---

# Box Versioning and Lifecycle

Boxes support versioning so that members of your team using Vagrant can
update the underlying box easily, and the people who create boxes can
push fixes and communicate these fixes efficiently.

There are multiple components of a box:

- The box itself, comprised of the box name and description.
- One or more box versions.
- One or more providers for each box version.

## Vagrant Messaging

Upon `vagrant up` or `vagrant box outdated`, an out-of-date box
user will see the following message in Vagrant:

    Bringing machine 'default' up with 'virtualbox' provider...
    ==> default: Checking if box 'hashicorp/example' is up to date...
    ==> default: A newer version of the box 'hashicorp/example' is available! You currently
    ==> default: have version '0.0.5'. The latest is version '0.0.6'. Run
    ==> default: `vagrant box update` to update.
    ...

## Box Version Release States

Vagrant Cloud lets you create new versions of boxes without
releasing them or without Vagrant seeing the update. This lets you prepare
a box for release slowly. Box versions have three states:

- `unreleased`: Vagrant cannot see this version yet, so it needs
to be released.  Versions can be released by editing them and clicking
the release button at the top of the page
- `active`: Vagrant is able to add and use this box version
- `revoked`: Vagrant cannot see this version, and it cannot be re-released.
You must create the version again

### Release Requirements

A box can only be released if it has at least one of each component: a
box, a version, and a provider.
