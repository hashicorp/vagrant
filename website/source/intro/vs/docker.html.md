---
layout: "intro"
page_title: "Vagrant vs. Docker"
sidebar_current: "vs-docker"
description: |-
  Vagrant and Docker both provide isolation primitives. This page details the
  differences between them.
---

# Vagrant vs. Docker

Vagrant is a tool focused on providing a consistent development environment
workflow across multiple operation systems. Docker is a container management
that can consistently run software as long as a containerization system exists.

Containers are generally more lightweight than virtual machines, so starting
and stopping containers is extremely fast. Most common development machines
don't have a containerization system built-in, and Docker uses a virtual machine
with Linux installed to provide that.

Currently, Docker lacks support for certain operating systems (such as
BSD). If your target deployment is one of these operating systems,
Docker will not provide the same production parity as a tool like Vagrant.
Vagrant will allow you to run a Windows development environment on Mac or Linux,
as well.

For microservice heavy environments, Docker can be attractive because you
can easily start a single Docker VM and start many containers above that
very quickly. This is a good use case for Docker. Vagrant can do this as well
with the Docker provider. A primary benefit for Vagrant is a consistent workflow
but there are many cases where a pure-Docker workflow does make sense.

Both Vagrant and Docker have a vast library of community-contributed "images"
or "boxes" to choose from.
