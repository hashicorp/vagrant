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
* `remove`
* `repackage`

# Box Add

**Command: `vagrant box add NAME URL`**

This adds a box at the given URL to Vagrant and stores it under the
logical name `NAME`.

The URL may be a file path or an HTTP URL. For HTTP, basic authentication
is supported and `http_proxy` environmental variables are respected. HTTPS
is also supported.

The name argument of this command is a _logical name_, meaning you can
effectively choose whatever you want. This is the name that Vagrant searches
for to match with the `config.vm.box` setting in Vagrantfiles.

If an error occurs during the download or the download is interrupted with
a Ctrl-C, then Vagrant will attempt to resume the download the next time it
is requested. Vagrant will only attempt to resume a download for six hours
after the initial download.

## Options

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

# Box List

**Command: `vagrant box list`**

This command lists all the boxes that are installed into Vagrant.

## Options

* `--box-info` - If given, Vagrant will display the URL from where the box
  has been downloaded and the date it was added

# Box Remove

**Command: `vagrant box remove NAME PROVIDER`**

This command removes a box from Vagrant that matches the given name and
provider.

# Box Repackage

**Command: `vagrant box repackage NAME PROVIDER`**

This command repackages the given box and puts it in the current
directory so you can redistribute it.

When you add a box, Vagrant unpacks it and stores it internally. The
original `*.box` file is not preserved. This command is useful for
reclaiming a `*.box` file from an installed Vagrant box.
