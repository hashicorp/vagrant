---
layout: "intro"
page_title: "Vagrant vs. Terraform"
sidebar_current: "vs-terraform"
description: |-
  Vagrant is a tool for managing virtual machines. Terraform is another open
  source tool from HashiCorp which enables infrastructure as code.
---

# Vagrant vs. Terraform

Vagrant and [Terraform][terraform] are both projects from [HashiCorp][hashicorp].
Vagrant is a tool focused for managing development environments and
Terraform is a tool for building infrastructure.

Terraform can describe complex sets of infrastructure that exists
locally or remotely. It is focused on building and changing that infrastructure
over time. The minimal aspects of virtual machine lifecycle can be reproduced
in Terraform, sometimes leading to confusion with Vagrant.

Vagrant provides a number of higher level features that Terraform doesn't.
Synced folders, automatic networking, HTTP tunneling, and more are features
provided by Vagrant to ease development environment usage. Because Terraform
is focused on infrastructure management and not development environments,
these features are out of scope for that project.

The primary usage of Terraform is for managing remote resources in cloud
providers such as AWS. Terraform is designed to be able to manage extremely
large infrastructures that span multiple cloud providers. Vagrant is designed
primarily for local development environments that use only a handful of
virtual machines at most.

Vagrant is for development environments. Terraform is for more general
infrastructure management.

[hashicorp]: https://www.hashicorp.com
[terraform]: https://www.terraform.io
