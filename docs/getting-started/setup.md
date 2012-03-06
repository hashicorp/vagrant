---
layout: getting_started
title: Getting Started - Project Setup

current: Project Setup
previous: Introduction
previous_url: /docs/getting-started/introduction.html
next: Boxes
next_url: /docs/getting-started/boxes.html
---
# Project Setup

The remainder of this getting started guide is written as a walkthrough.
As the reader, you are encouraged to follow along with the samples on your own
personal computer. Since Vagrant works with virtual machines, there will be no
"cruft" left over if you ever wish to stop (no extraneous software, files, etc)
as Vagrant will handle destroying the virtual machine if you so choose.

## Vagrant Project Setup

The first step for any project which uses Vagrant is to mark the root directory
and setup the basic required files. Vagrant provides a handy command-line utility
for just that. In the terminal transcript below, we create the directory for our
project and initialize it for Vagrant:

{% highlight bash %}
$ mkdir vagrant_guide
$ cd vagrant_guide
$ vagrant init
{% endhighlight %}

`vagrant init` creates an initial Vagrantfile. For now, we'll leave this Vagrantfile
as-is, but it will be used extensively in future steps to configure our virtual
machine.

## Web Project Setup

With Vagrant now ready for the given directory, let's create a quick "web project"
which we'll use later to showcase your VM. Run the following command in your
project directory (the directory with the Vagrantfile):

{% highlight bash %}
$ echo "<h1>Hello from a Vagrant VM</h1>" > index.html
{% endhighlight %}

The above steps could have been run in any order. Vagrant can easily be initialized
in pre-existing project folders.

<div class="alert alert-block alert-notice">
  <h3>What about PHP? Python? Java?</h3>
  <p>
    To keep this getting started guide as simple and as general as possible,
    we use an HTML-based project as an example, but Vagrant doesn't make
    any assumptions about the type of project you're developing. It should
    be clear after going through the getting started guide that Vagrant is
    usable with any type of web project.
  </p>
</div>
