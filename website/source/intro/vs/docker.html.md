---
layout: "intro"
page_title: "Vagrant vs. Docker"
sidebar_current: "vs-docker"
description: |-
  Vagrant and Docker both provide isolation primitives. This page details the
  differences between them.
---

# Vagrant vs. Docker

Vagrant uses kernel-level isolation whereas Docker uses userland-level
isolation. In practice, this means Vagrant will provide more isolation from your
virtual machines than Docker, but Docker will be faster to boot machines. After
booting, speeds are roughly equivalent.

Docker also lacks support for certain operating systems (like Windows and BSD).
If your target deployment is a Windows environment, Docker will not provide the
same production parity as a tool like Vagrant.

Both Vagrant and Docker have a vast library of community-contributed "images" or
"boxes" to choose from.
