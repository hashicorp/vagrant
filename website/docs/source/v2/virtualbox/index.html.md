---
page_title: "VirtualBox Provider"
sidebar_current: "virtualbox"
---

# VirtualBox

Vagrant comes with support out of the box for [VirtualBox](http://www.virtualbox.org),
a free, cross-platform consumer virtualization product.

The VirtualBox provider is compatible with VirtualBox versions 4.0.x, 4.1.x,
4.2.x, and 4.3.x. Any other version is unsupported and the provider will display
an error message.

VirtualBox must be installed on its own prior to using the provider, or
the provider will display an error message asking you to install it.
VirtualBox can be installed by [downloading](https://www.virtualbox.org/wiki/Downloads)
a package or installer for your operating system and using standard procedures
to install that package.

<div class="alert alert-block alert-warning">
<p>
<strong>Hanging Vagrant commands on Windows?</strong> If your prompt hangs on a 
Vagrant command on Windows when using the VirtualBox provider this may be caused 
by a permissions problem within VirtualBox, starting VirtualBox normally or as 
a Windows administrator will prevent you from accessing it the opposite way. 
Please keep in mind that when a Vagrant command interacts with VirtualBox it 
will access VirtualBox with the access level of your Windows console.
</p>
</div>

Use the navigation to the left to find a specific VirtualBox topic to read more about.
