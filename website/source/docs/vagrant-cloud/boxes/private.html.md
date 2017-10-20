---
layout: "vagrant-cloud"
page_title: "Private Boxes"
sidebar_current: "vagrant-cloud-boxes-private"
---

# Private Boxes

If you create a private box, only you (the owner) and collaborators
will be able to access it.

## Collaborators

To add a collaborator:

1. Click the gear setting beside the boxes name in order to edit it.
2. Under the "Add Collaborator" section, enter their username and
submit the form.
3. You'll now see a list of collaborators, and if necessary a collaborator
can be removed.

Collaborators can edit the box, versions and providers. The only
things they cannot do are:

- Add another collaborator
- Delete the box

## Vagrant Login

In order to access these boxes from Vagrant, you'll need to first
authenticate with your Vagrant Cloud account.

1. Run `vagrant login`
2. Enter your credentials

You should now be logged in. We use these credentials to request
a unique authentication token that is stored locally by Vagrant. Your
username or password is never stored on your machine.

## 404 Not Found

If you don't authenticate, you will likely receive a `404 Not Found`
error in Vagrant. We return a 404 for security reasons, so a potential
attacker could not verify if a private box exists.
