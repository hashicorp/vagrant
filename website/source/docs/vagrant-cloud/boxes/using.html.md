---
layout: "vagrant-cloud"
page_title: "Finding and Using Boxes"
sidebar_current: "vagrant-cloud-boxes-using"
---

# Finding and Using Boxes

A primary use case of Vagrant Cloud by HashiCorp is to be able to easily find
boxes you can use with Vagrant that contain the technologies you need
for a Vagrant environment. We've made it extremely easy to do that:

1. Go to the [Discover page](https://vagrantcloud.com/discover), and search for
   any box you want.

1. Once you find a box, click its name to learn more about it.

1. When you're ready to use it, copy the name, such as "hashicorp/precise64"
   and initialize your Vagrant project with `vagrant init hashicorp/precise64`.
   Or, if you already have a Vagrant project created, modify the Vagrantfile
   to use the box: `config.vm.box = "hashicorp/precise64"`
