---
layout: "docs"
page_title: "Debugging and Troubleshooting"
sidebar_current: "other-debugging"
description: |-
  As much as we try to keep Vagrant stable and bug free, it is inevitable
  that issues will arise and Vagrant will behave in unexpected ways. In
  these cases, Vagrant has amazing support channels available to assist you.
---

# Debugging

As much as we try to keep Vagrant stable and bug free, it is inevitable
that issues will arise and Vagrant will behave in unexpected ways.

When using these support channels, it is generally helpful to include
debugging logs along with any error reports. These logs can often help you
troubleshoot any problems you may be having.

!> **Scan for sensitive information!** Vagrant debug logs include information
about your system including environment variables and user information. If you
store sensitive information in the environment or in your user account, please
scan or scrub the debug log of this information before uploading the contents to
the public Internet.

~> **Submit debug logs using GitHub Gist.** If you plan on submitting a bug
report or issue that includes debug-level logs, please use a service like
[Gist](https://gist.github.com). **Do not** paste the raw debug logs into an
issue as it makes it very difficult to scroll and parse the information.

To enable detailed logging, set the `VAGRANT_LOG` environmental variable
to the desired log level name, which is one of `debug` (loud), `info` (normal),
`warn` (quiet), and `error` (very quiet). When asking for support, please
set this to `debug`. When troubleshooting your own issues, you should start
with `info`, which is much quieter, but contains important information
about the behavior of Vagrant.

On Linux and Mac systems, this can be done by prepending the `vagrant`
command with an environmental variable declaration:

```
$ VAGRANT_LOG=info vagrant up
```

On Windows, multiple steps are required:

```
$ set VAGRANT_LOG=info
$ vagrant up
```

You can also get the debug level output using the `--debug` command line
option. For example:

```
$ vagrant up --debug
```

On Linux and Mac, if you are saving the output to a file, you may need to redirect stderr and
stdout using `&>`:

```
$ vagrant up --debug &> vagrant.log
```

On Windows:
```
$ vagrant up --debug > vagrant.log 2>&1
```
