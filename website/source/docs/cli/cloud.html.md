---
layout: "docs"
page_title: "vagrant cloud - Command-Line Interface"
sidebar_current: "cli-cloud"
description: |-
  The "vagrant cloud" command can be used for taking actions against
  Vagrant Cloud like searching or uploading a Vagrant Box
---

# Cloud

**Command: `vagrant cloud`**

This is the command used to manage anything related to [Vagrant Cloud](https://vagrantcloud.com).

The main functionality of this command is exposed via subcommands:

* [`auth`](#cloud-auth)
* [`box`](#cloud-box)
* [`provider`](#cloud-provider)
* [`publish`](#cloud-publish)
* [`search`](#cloud-search)
* [`version`](#cloud-version)

# Cloud Auth

**Command: `vagrant cloud auth`**

The `cloud auth` command is for handling all things related to authorization with
Vagrant Cloud.

* [`login`](#cloud-auth-login)
* [`logout`](#cloud-auth-logout)
* [`whoami`](#cloud-auth-whoami)

## Cloud Auth Login

**Command: `vagrant cloud auth login`**

The login command is used to authenticate with [HashiCorp's Vagrant Cloud](/docs/vagrant-cloud)
server. Logging in is only necessary if you are accessing protected boxes.

**Logging in is not a requirement to use Vagrant.** The vast majority
of Vagrant does _not_ require a login. Only certain features such as protected
boxes.

The reference of available command-line flags to this command
is available below.

### Options

* `--check` - This will check if you are logged in. In addition to outputting
  whether you are logged in or not, the command exit status will be 0 if you are
  logged in, or 1 if you are not.

* `--logout` - This will log you out if you are logged in. If you are already
  logged out, this command will do nothing. It is not an error to call this
  command if you are already logged out.

* `--token` - This will set the Vagrant Cloud login token manually to the provided
  string. It is assumed this token is a valid Vagrant Cloud access token.

### Examples

Securely authenticate to Vagrant Cloud using a username and password:

```text
$ vagrant cloud auth login
# ...
Vagrant Cloud username:
Vagrant Cloud password:
```

Check if the current user is authenticated:

```text
$ vagrant cloud auth login --check
You are already logged in.
```

Securely authenticate with Vagrant Cloud using a token:

```text
$ vagrant cloud auth login --token ABCD1234
The token was successfully saved.
```

## Cloud Auth Logout

**Command: `vagrant cloud auth logout`**

This will log you out if you are logged in. If you are already
logged out, this command will do nothing. It is not an error to call this
command if you are already logged out.

## Cloud Auth Whomi

**Command: `vagrant cloud auth whoami [TOKEN]`**

This command will validate your Vagrant Cloud token and will print the user who
it belongs to. If a token is passed in, it will attempt to validate it instead
of the token stored stored on disk.

# Cloud Box

**Command: `vagrant cloud box`**

The `cloud box` command is used to manage life cycle operations for all `box`
entities on Vagrant Cloud.

* [`create`](#cloud-box-create)
* [`delete`](#cloud-box-delete)
* [`show`](#cloud-box-show)
* [`update`](#cloud-box-update)

## Cloud Box Create

**Command: `vagrant cloud box create ORGANIZATION/BOX-NAME`**

The box create command is used to create a new box entry on Vagrant Cloud.

### Options

* `--description DESCRIPTION` - A full description of the box. Can be
  formatted with Markdown.
* `--short-description DESCRIPTION` - A short summary of the box.
* `--private` - Will make the new box private (Public by default)

## Cloud Box Delete

**Command: `vagrant cloud box delete ORGANIZATION/BOX-NAME`**

The box delete command will _permanently_ delete the given box entry on Vagrant Cloud. Before
making the request, it will ask if you are sure you want to delete the box.

## Cloud Box Show

**Command: `vagrant cloud box show ORGANIZATION/BOX-NAME`**

The box show command will display information about the latest version for the given Vagrant box.

## Cloud Box Update

**Command: `vagrant cloud box update ORGANIZATION/BOX-NAME`**

The box update command will update an already created box on Vagrant Cloud with the given options.

### Options

* `--description DESCRIPTION` - A full description of the box. Can be
  formatted with Markdown.
* `--short-description DESCRIPTION` - A short summary of the box.
* `--private` - Will make the new box private (Public by default)

# Cloud Provider

**Command: `vagrant cloud provider`**

The `cloud provider` command is used to manage the life cycle operations for all
`provider` entities on Vagrant Cloud.

* [`create`](#cloud-provider-create)
* [`delete`](#cloud-provider-delete)
* [`update`](#cloud-provider-update)
* [`upload`](#cloud-provider-upload)

## Cloud Provider Create

**Command: `vagrant cloud provider create ORGANIZATION/BOX-NAME PROVIDER-NAME VERSION [URL]`**


The provider create command is used to create a new provider entry on Vagrant Cloud.
The `url` argument is expected to be a remote URL that Vagrant Cloud can use
to download the provider. If no `url` is specified, the provider entry can be updated
later with a url or the [upload](#cloud-provider-upload) command can be used to
upload a Vagrant [box file](/docs/boxes.html).

## Cloud Provider Delete

**Command: `vagrant cloud provider delete ORGANIZATION/BOX-NAME PROVIDER-NAME VERSION`**

The provider delete command is used to delete a provider entry on Vagrant Cloud.
Before making the request, it will ask if you are sure you want to delete the provider.

## Cloud Provider Update

**Command: `vagrant cloud provider update ORGANIZATION/BOX-NAME PROVIDER-NAME VERSION [URL]`**

The provider update command will update an already created provider for a box on
Vagrant Cloud with the given options.

## Cloud Provider Upload

**Command: `vagrant cloud provider upload ORGANIZATION/BOX-NAME PROVIDER-NAME VERSION BOX-FILE`**

The provider upload command will upload a Vagrant [box file](/docs/boxes.html) to Vagrant Cloud for
the specified version and provider.

# Cloud Publish

**Command: `vagrant cloud publish ORGANIZATION/BOX-NAME VERSION PROVIDER-NAME [PROVIDER-FILE]`**

The publish command is a complete solution for creating and updating a
Vagrant box on Vagrant Cloud. Instead of having to create each attribute of a Vagrant
box with separate commands, the publish command instead asks you to provide all
the information required before creating or updating a new box.

## Options

* `--box-version VERSION` - Version to create for the box
* `--description DESCRIPTION` - A full description of the box. Can be
  formatted with Markdown.
* `--force` - Disables confirmation when creating or updating a box.
* `--short-description DESCRIPTION` - A short summary of the box.
* `--private` - Will make the new box private (Public by default)
* `--release` - Automatically releases the box after creation (Unreleased by default)
* `--url` - Valid remote URL to download the box file
* `--version-description DESCRIPTION` - Description of the version that will be created.

## Examples

Creating a new box on Vagrant Cloud:

```text
$ vagrant cloud publish briancain/supertest 1.0.0 virtualbox boxes/my/virtualbox.box -d "A really cool box to download and use" --version-description "A cool version" --release --short-description "Donwload me!"
You are about to create a box on Vagrant Cloud with the following options:
briancain/supertest (1.0.0) for virtualbox
Automatic Release:     true
Box Description:       A really cool box to download and use
Box Short Description: Download me!
Version Description:   A cool version
Do you wish to continue? [y/N] y
Creating a box entry...
Creating a version entry...
Creating a provider entry...
Uploading provider with file /Users/vagrant/boxes/my/virtualbox.box
Releasing box...
Complete! Published briancain/supertest
tag:                  briancain/supertest
username:             briancain
name:                 supertest
private:              false
downloads:            0
created_at:           2018-07-25T17:53:04.340Z
updated_at:           2018-07-25T18:01:10.665Z
short_description:    Download me!
description_markdown: A reall cool box to download and use
current_version:      1.0.0
providers:            virtualbox
```

# Cloud Search

**Command: `vagrant cloud search QUERY`**

The cloud search command will take a query and search Vagrant Cloud for any matching
Vagrant boxes. Various filters can be applied to the results.

## Options

* `--json` - Format search results in JSON.
* `--page PAGE` - The page to display. Defaults to the first page of results.
* `--short` - Shows a simple list of box names for the results.
* `--order ORDER` - Order to display results. Can either be `desc` or `asc`.
Defaults to `desc`.
* `--limit LIMIT` - Max number of search results to display. Defaults to 25.
* `--provider PROVIDER` - Filter search results to a single provider.
* `--sort-by SORT` - The field to sort results on. Can be `created`, `downloads`
, or `updated`. Defaults to `downloads`.

## Examples

If you are looking for a HashiCorp box:

```text
vagrant cloud search hashicorp --limit 5
| NAME                    | VERSION | DOWNLOADS | PROVIDERS                       |
+-------------------------+---------+-----------+---------------------------------+
| hashicorp/precise64     | 1.1.0   | 6,675,725 | virtualbox,vmware_fusion,hyperv |
| hashicorp/precise32     | 1.0.0   | 2,261,377 | virtualbox                      |
| hashicorp/boot2docker   | 1.7.8   |    59,284 | vmware_desktop,virtualbox       |
| hashicorp/connect-vm    | 0.1.0   |     6,912 | vmware_desktop,virtualbox       |
| hashicorp/vagrant-share | 0.1.0   |     3,488 | vmware_desktop,virtualbox       |
+-------------------------+---------+-----------+---------------------------------+
```

# Cloud Version

**Command: `vagrant cloud version`**

The `cloud version` command is used to manage life cycle operations for all `version`
entities for a box on Vagrant Cloud.

* [`create`](#cloud-version-create)
* [`delete`](#cloud-version-delete)
* [`release`](#cloud-version-release)
* [`revoke`](#cloud-version-revoke)
* [`update`](#cloud-version-update)

## Cloud Version Create

**Command: `vagrant cloud version create ORGANIZATION/BOX-NAME VERSION`**

The cloud create command creates a version entry for a box on Vagrant Cloud.

### Options

* `--description DESCRIPTION` - Description of the version that will be created.

## Cloud Version Delete

**Command: `vagrant cloud version delete ORGANIZATION/BOX-NAME VERSION`**

The cloud delete command deletes a version entry for a box on Vagrant Cloud.
Before making the request, it will ask if you are sure you want to delete the version.

## Cloud Version Release

**Command: `vagrant cloud version release ORGANIZATION/BOX-NAME VERSION`**

The cloud release command releases a version entry for a box on Vagrant Cloud
if it already exists. Before making the request, it will ask if you are sure you
want to release the version.

## Cloud Version Revoke

**Command: `vagrant cloud version revoke ORGANIZATION/BOX-NAME VERSION`**

The cloud revoke command revokes a version entry for a box on Vagrant Cloud
if it already exists. Before making the request, it will ask if you are sure you
want to revoke the version.

## Cloud Version Update

**Command: `vagrant cloud version update ORGANIZATION/BOX-NAME VERSION`**

### Options

* `--description DESCRIPTION` - Description of the version that will be created.
