---
layout: "docs"
page_title: "Common Issues - Disks VirtualBox Provider"
sidebar_current: "disks-providers-virtualbox-issues"
description: |-
  This page lists some common issues people run into with Vagrant and VirtualBox
  as well as solutions for those issues.
---

# Common Issues and Troubleshooting

This page lists some common issues people run into with Vagrant and VirtualBox
as well as solutions for those issues.

## Are my disks attached?

A handy way to figure out what disks are attached (or not attached) to your guest
is to open up the VirtualBox GUI and select the guest. When selecting a guest on the GUI,
it should open more information about the guest, including storage information. Here
you should see a list of disks attached to your guest.

## How many disks can I attach?

Vagrant attaches all new disks defined to a guests SATA Controller. As of VirtualBox 6.1.x,
SATA Controllers can only support up to **30 disks** per guest. Therefore if you try
to define and attach more than 30, it will result in an error. This number _includes_
the primary disk for the guest.

## Applying Changes to Guests

Due to how VirtualBox works, you must reload your guest for any disk config changes
to be applied. So if you update your Vagrantfile to update or even remove disks, make
sure to `vagrant reload` your guests for these changes to be applied.
