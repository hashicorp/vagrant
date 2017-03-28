---
layout: "intro"
page_title: "Vagrant vs. Terraform"
sidebar_current: "vs-terraform"
description: |-
  Vagrant is a tool for managing virtual machines. Terraform is another open
  source tool from HashiCorp which enables infrastructure as code.
---

# Vagrant vs. Terraform

Vagrant is a tool for managing virtual machines. [Terraform][terraform] is
another open source tool from [HashiCorp][hashicorp] which enables
infrastructure as code.

Both Vagrant and Terraform use a declarative syntax to express the desired,
final state of a system. Vagrant's focus is on development environments whereas
Terraform's focus is on remote APIs and cloud resources. While Terraform has
provisioners, they are not as full-featured as those in Vagrant. Vagrant cannot
manage cloud resources without third-party plugins.

[hashicorp]: https://www.hashicorp.com
[terraform]: https://www.terraform.io
