---
layout: "vagrant-cloud"
page_title: "Creating a New Vagrant Box"
sidebar_current: "vagrant-cloud-boxes-create-x"
---

# Creating a New Vagrant Box

This page will cover creating a new box in Vagrant Cloud and how to distribute
it to users. Boxes can be distributed without Vagrant Cloud, but
miss out on several [important features](/docs/vagrant-cloud/boxes).

There are __three ways to create and upload Vagrant Boxes to Vagrant Cloud__. All
three options are outlined below.

We recommend using Packer, as is it is fully repeatable and keeps a strong
history of changes within Vagrant Cloud. However, for some situations, including
legacy workflows, the Web UI or API will work well.

All three options require you [sign up for Vagrant Cloud](https://vagrantcloud.com/account/new).

## Creating Boxes with Packer

Using Packer requires more up front effort, but the repeatable and
automated builds will end any manual management of boxes. Additionally,
all boxes will be stored and served from Vagrant Cloud, keeping a history along
 the way.

## Creating Boxes via the Vagrant Cloud Web Interface

You'll first need to create a box file. This can be done via
the [vagrant `package` command](http://docs.vagrantup.com/v2/boxes/base.html)
or with Packer locally.

After you've created the `.box` file, this guide can be followed.

1. Go to the [Create Box](https://vagrantcloud.com/boxes/new) page.

1. Name the box and give it a simple description

1. Create your first version for the box. This version
must match the format `[0-9].[0-9].[0-9]`

1. Create a provider for the box, matching the provider you need
locally in Vagrant. `virtualbox` is the most common provider.

1. Upload the `.box` file for each provider, or use a url to the `.box`
file that is publicly accessible

You can find all of your boxes in the [Vagrant section](https://vagrantcloud.com/vagrant) of Vagrant Cloud.

Once you've created and released a box, you can release new versions of
the box by clicking "Create New Version" under the versions sidebar on
a box page. For more information on the release lifecycle of boxes, see
the [help page dedicated to box lifecycle](/docs/vagrant-cloud/boxes/lifecycle.html).

## Creating Boxes with the API

This example uses the API to upload boxes with `curl`. To get started, you'll
need to get an [access token](https://vagrantcloud.com/settings/tokens).

Then, prepare the upload:

    $ curl 'https://vagrantcloud.com/api/v1/box/USERNAME/BOX_NAME/version/VERSION/provider/PROVIDER_NAME/upload?access_token=ACCESS_TOKEN'

This should return something like this:

    {
      "upload_path": "https://archivist.hashicorp.com/v1/object/630e42d9-2364-2412-4121-18266770468e"
    }

Then, upload your box with the following command, with the filename in this case being `foo.box`:

    $ curl -X PUT --upload-file foo.box https://archivist.hashicorp.com/v1/object/630e42d9-2364-2412-4121-18266770468e

When the upload finishes, you can verify it worked by making this request and matching the `hosted_token` it returns to the previously retrieved upload token.

    $ curl 'https://vagrantcloud.com/api/v1/box/USERNAME/BOX_NAME/version/VERSION_NUMBER/provider/PROVIDER_NAME?access_token=ACCESS_TOKEN'

Your box should then be available for download.
