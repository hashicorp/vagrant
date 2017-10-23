---
layout: "vagrant-cloud"
page_title: "Distributing Boxes"
sidebar_current: "vagrant-cloud-boxes-distributing"
---

## Distributing Boxes

To distribute the box to your team, update your Vagrantfile to reference the
box on Vagrant Cloud.

    Vagrant.configure(2) do |config|
      config.vm.box = "username/example-box"
    end

Now when a team member runs `vagrant up`, the box will be downloaded from Vagrant Cloud.
If the box is private, the team member will be prompted to authorize access. Users
are granted access to private resources by logging in with a Vagrant Cloud username and
password or by using a shared Vagrant Cloud token.
[Learn more about authorization options here](/docs/vagrant-cloud/users/authentication.html).

## Private Boxes

If you create a private box, only you (the owner) and collaborators
will be able to access it. This is valuable if you
have information, data or provisioning in your box
that cannot be public.

Private boxes will be excluded from the box catalog.

### Collaborators

Collaborators can be both teams in
organizations or individual users.

To add a collaborator:

1. Go to the "Access" page of a box via the sidebar
2. Enter the username or team name and submit the form
3. You'll now see an the user or team in the list of collaborators,
and if necessary a collaborator can be removed

### Vagrant Login

In order to access these private boxes from Vagrant, you'll need to first
authenticate with your Vagrant Cloud account.

1. Run `vagrant login`
2. Enter your credentials

You should now be logged in. We use these credentials to request
a unique authentication token that is stored locally by Vagrant. Your
username or password is never stored on your machine.

### 404 Not Found

If you don't authenticate, you will likely receive a `404 Not Found`
error in Vagrant. We return a 404 for security reasons, so a potential
attacker could not verify if a private box exists.
