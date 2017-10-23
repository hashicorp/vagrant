---
layout: "vagrant-cloud"
page_title: "API Release Workflow"
sidebar_current: "vagrant-cloud-boxes-release-workflow"
---

# API Release Workflow

Creating new boxes through their [release lifecycle](/docs/vagrant-cloud/boxes/lifecycle.html)
is possible through the Vagrant Cloud website, but you can also automate
the task via the Vagrant Cloud API.

1. Create box, or locate a boxes `tag`, like `hashicorp/precise64`
2. After some event, like the end of a CI build, you may want to
release a new version of the box. To do this, first use the API to
create a new version with a version number and a short description
of the changes
3. Then, create any providers associated with the version, like
`virtualbox`
4. Once your system has made the necessary requests to the API and the
version is ready, make a request to the `release` endpoint on the version
5. The version should now be available to users of the box via
the command `vagrant box outdated` or via the automated checks on
`vagrant up`
