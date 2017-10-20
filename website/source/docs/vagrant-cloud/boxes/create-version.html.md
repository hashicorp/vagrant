---
layout: "vagrant-cloud"
page_title: "Create a New Box Version"
sidebar_current: "vagrant-cloud-boxes-create-version"
---

# Create a New Box Version

To release a new version of a box to the public or to your team:

  1. Click on the name of the box you want to release a new version for.

  2. To the right of the box name, there is a dropdown of all the available
     versions. Click this, and click "Create a New Version"

  3. Enter details for your new version and click "Create Version." Note that
     after clicking create version, the version is not yet _released_.

  4. Click "Create new provider" on this next page to add at least one
     provider to the version. Specify the name of the provider (this is the
     same value you specify to `--provider` when using Vagrant). Then
     enter the URL to a self-hosted box file or upload a box to us.

  5. Once the provider is created, you now have the option to release the
     version by clicking "Release now," or you can add more providers.

Once you click "Release now," that version will be available for installation
with Vagrant. Before clicking this, Vagrant does not know the version even
exists.
