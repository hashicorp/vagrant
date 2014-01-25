---
page_title: "vagrant box - Command-Line Interface"
sidebar_current: "cli-box"
---

# Box

**Command: `vagrant box`**

This is the command used to manage (add, remove, etc.) [boxes](/v2/boxes.html).

The main functionality of this command is exposed via even more subcommands:

* `add`
* `list`
* `outdated`
* `remove`
* `repackage`
* `update`

# Box Add

**Command: `vagrant box add ADDRESS`**

This adds a box with the given address to Vagrant. The address can be
one of three things:

* A shorthand name from the
[public catalog of available Vagrant images](#),
such as "hashicorp/precise64".

* File path or HTTP URL to a box in a [catalog](#).
For HTTP, basic authentication is supported and `http_proxy` environmental
variables are respected. HTTPS is also supported.

* URL directly a box file. In this case, you must specify a `--name` flag
(see below) and versioning/updates won't work.

If an error occurs during the download or the download is interrupted with
a Ctrl-C, then Vagrant will attempt to resume the download the next time it
is requested. Vagrant will only attempt to resume a download for six hours
after the initial download.

## Options

* `--box-version VALUE` - The version of the box you want to add. By default,
  the latest version will be added. The value of this can be an exact version
  number such as "1.2.3" or it can be a set of version constraints. A version
  constraint looks like ">= 1.0, < 2.0".

* `--cacert CERTFILE` - The certificate for the CA used to verify the peer.
  This should be used if the remote end doesn't use a standard root CA.

* `--cert CERTFILE` - A client certificate to use when downloading the box, if
  necessary.

* `--clean` - If given, Vagrant will remove any old temporary files from
  prior downloads of the same URL. This is useful if you don't want Vagrant
  to resume a download from a previous point, perhaps because the contents
  changed.

* `--force` - When present, the box will be downloaded and overwrite any
  existing box with this name.

* `--insecure` - When present, SSL certificates won't be verified if the
  URL is an HTTPS URL.

* `--provider PROVIDER` - If given, Vagrant will verify the box you're
  adding is for the given provider. By default, Vagrant automatically
  detects the proper provider to use.

## Options for direct box files

The options below only apply if you're adding a box file directly (when
you're not using a catalog).

* `--checksum VALUE` - A checksum for the box that is downloaded. If specified,
  Vagrant will compare this checksum to what is actually downloaded and will
  error if the checksums do not match. This is highly recommended since
  box files are so large. If this is specified, `--checksum-type` must
  also be specified. If you're downloading from a catalog, the checksum is
  included within the catalog entry.

* `--checksum-type TYPE` - The type of checksum that `--checksum` is if it
  is specified. Supported values are currently "md5", "sha1", and "sha256".

* `--name VALUE` - Logical name for the box. This is the value that you
  would put into `config.vm.box` in your Vagrantfile. When adding a box from
  a catalog, the name is included in the catalog entry and doesn't have
  to be specified.

# Box List

**Command: `vagrant box list`**

This command lists all the boxes that are installed into Vagrant.

# Box Outdated

**Command: `vagrant box outdated`**

This command tells you whether or not the box you're using in
your current Vagrant environment is outdated. If the `--global` flag
is present, every installed box will be checked for updates.

Checking for updates involves refreshing the metadata associated with
a box. This generally requires an internet connection.

## Options

* `--global` - Check for updates for all installed boxes, not just the
  boxes for the current Vagrant environment.

# Box Remove

**Command: `vagrant box remove NAME`**

This command removes a box from Vagrant that matches the given name.

If a box has multiple providers, the exact provider must be specified
with the `--provider` flag. If a box has multiple versions, you can select
what versions to delete with the `--box-version` flag.

## Options

* `--box-version VALUE` - Version of version constraints of the boxes to
  remove. See documentation on this flag for `box add` for more details.

* `--provider VALUE` - The provider-specific box to remove with the given
  name. This is only required if a box is backed by multiple providers.
  If there is only a single provider, Vagrant will default to removing it.

# Box Repackage

**Command: `vagrant box repackage NAME PROVIDER`**

This command repackages the given box and puts it in the current
directory so you can redistribute it.

When you add a box, Vagrant unpacks it and stores it internally. The
original `*.box` file is not preserved. This command is useful for
reclaiming a `*.box` file from an installed Vagrant box.

# Box Update

**Command: `vagrant box update`**

This command updates the box for the current Vagrant environment if there
are updates available. The command can also update a specific box (outside
of an active Vagrant environment), by specifying the `--box` flag.

Note that updating the box will not update an already-running Vagrant
machine. To reflect the changes in the box, you'll have to destroy and
bring back up the Vagrant machine.

If you just want to check if there are updates available, use the
`vagrant box outdated` command.

## Options

* `--box VALUE` - Name of a specific box to update. If this flag is not
  specified, Vagrant will update the boxes for the active Vagrant
  environment.

* `--provider VALUE` - When `--box` is present, this controls what
  provider-specific box to update. This is not required unless the box has
  multiple providers. Without the `--box` flag, this has no effect.
