---
layout: "vagrant-cloud"
page_title: "Vagrant Cloud Migration"
sidebar_current: "vagrant-cloud-migration"
---

# Vagrant Cloud Migration

Vagrant-related functionality will be moved from Terraform Enterprise into its own product, Vagrant Cloud.
This migration is currently planned for **June 27th, 2017** at 6PM EDT/3PM PDT/10PM UTC.

All existing Vagrant boxes will be moved to the new system at that time.
All users, organizations, and teams will be copied as well.

~> If you only use Vagrant to download and run public boxes, then nothing is changing.
~> All box names, versions, and URLs will stay the same (or redirect) with no changes to your workflow or Vagrantfiles.

## Vagrant Boxes, Users, Organizations, and Teams

All Vagrant boxes will be moved to the new Vagrant Cloud on June 27th.
Additionally, all users and organizations will be copied.
Any existing box collaborations or team ACLs will persist into the new system.

All existing box names (hashicorp/precise64) and URLs will continue working as-is, or permanently redirect to the correct location.
If you’re only using public Vagrant boxes, no changes will be required to your Vagrantfiles or workflow.
Users of private Vagrant boxes will need to create a new authentication (see below), and activate their Vagrant Cloud account after the migration has completed.

Vagrant Cloud users and organizations will be considered inactive in the future if they have not logged into Vagrant Cloud after the migration and do not have any published Vagrant boxes.
Inactive user accounts will be deleted on or after October 1st, 2017.

## Vagrant Cloud Account Activation

In order to begin using Vagrant Cloud with your Atlas account, you will first need to activate your Vagrant Cloud account.
This will require you to login to Atlas, as well as confirm your password (and 2FA credentials, if configured).
There will be links and instructions on the Vagrant Cloud login screen directing you to do this.

During Vagrant Cloud account activation, you will create a new password for Vagrant Cloud and optionally configure 2FA.
Your pre-existing Atlas account, password, and 2FA configuration will remain unchanged within Atlas.

~> New users of Vagrant Cloud can always create a new account for free, at any time.

## Authentication Tokens

If you are currently using an authentication token to interact with Atlas for Vagrant features, you will need to generate a new Vagrant Cloud token prior to June 27th.
You can see your existing tokens and generate new tokens on the Tokens page of your account settings.

When creating this new token, select Migrate to Vagrant Cloud.

You can see which authentication tokens which will be copied to Vagrant Cloud in the token list.

Only these authentication tokens will be moved to Vagrant Cloud on June 27th.
They will also be removed from Terraform Enterprise at this time, and will no longer work for Terraform or Packer operations.
If you do not create a token in Atlas by June 27th, you will need to create a token within Vagrant Cloud after the migration.

~> Creating a token in Atlas via `vagrant login` will also mark a token as "Migrate to Vagrant Cloud".

## Packer and Terraform Enterprise

Packer has two post-processors which can create Vagrant boxes in Terraform Enterprise (Atlas): `atlas` and `vagrant-cloud`.
The `atlas post-processor` will no longer create Vagrant boxes after June 27th.
If you are currently publishing Vagrant boxes with Packer, please ensure that you are using the vagrant-cloud post-processor.

For example, if your Packer post-processor JSON looks like this:

```json
{
  "variables": {
    "atlas_token": "{{env `ATLAS_TOKEN`}}",
    "version": "1.0.{{timestamp}}"
  },
  "builders": [
  ],
  "post-processors": [
    {
      "type": "atlas",
      "token": "{{user `atlas_token`}}",
      "artifact": "hashicorp/example",
      "artifact_type": "vagrant.box",
      "metadata": {
        "version": "{{user `version`}}"
      }
    }
  ]
}
```

You must replace the `atlas` post-processor with the `vagrant` and `vagrant-cloud` post-processors (note the nested array, which tells Packer to run these steps serially).

```json
{
  "variables": {
    "vagrantcloud_token": "{{env `VAGRANTCLOUD_TOKEN`}}",
    "version": "1.0.{{timestamp}}"
  },
  "builders": [
  ],
  "post-processors": [
    [
      {
        "type": "vagrant",
        "output": "output.box"
      },
      {
        "type": "vagrant-cloud",
        "access_token": "{{user `vagrantcloud_token`}}",
        "box_tag": "hashicorp/example",
        "version": "{{user `version`}}"
      }
    ]
  ]
}
```

## Vagrant Share

Vagrant Share via Atlas has been deprecated, and instead Vagrant supports native integration with [ngrok](https://ngrok.com).
Users of Vagrant Share should switch to the [ngrok-powered Vagrant Share driver](https://www.vagrantup.com/docs/share) prior to June 27th, which will become the default in the next version of Vagrant

## Downtime

There will be a brief outage of Vagrant services within Atlas/Terraform Enterprise on June 27th at 6PM EDT/3PM PDT until the migration is complete.
We estimate that this will take less than 30 minutes.
