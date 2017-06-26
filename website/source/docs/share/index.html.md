---
layout: "docs"
page_title: "Vagrant Share"
sidebar_current: "share"
description: |-
  Vagrant Share allows you to  share your Vagrant environment with anyone in
  the world, enabling collaboration directly in your Vagrant environment
  in almost any network environment with just a single command- "vagrant share".
---

# Vagrant Share

Vagrant Share allows you to  share your Vagrant environment with anyone in
the world, enabling collaboration directly in your Vagrant environment
in almost any network environment with just a single command:
`vagrant share`.

Vagrant share has three primary modes or features. These features are not
mutually exclusive, meaning that any combination of them can be active
at any given time:

  * **HTTP sharing** will create a URL that you can give to anyone. This
    URL will route directly into your Vagrant environment. The person using
    this URL does not need Vagrant installed, so it can be shared with anyone.
    This is useful for testing webhooks or showing your work to clients,
    teammates, managers, etc.

  * **SSH sharing** will allow instant SSH access to your Vagrant environment
    by anyone by running `vagrant connect --ssh` on the remote side. This
    is useful for pair programming, debugging ops problems, etc.

  * **General sharing** allows anyone to access any exposed port of your
    Vagrant environment by running `vagrant connect` on the remote side.
    This is useful if the remote side wants to access your Vagrant
    environment as if it were a computer on the LAN.

The details of each are covered in their specific section in the sidebar
to the left. We also have a section where we go into detail about the
security implications of this feature.

Vagrant Share requires [ngrok](https://ngrok.com) to be used.
