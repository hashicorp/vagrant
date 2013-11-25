---
page_title: "Debugging and Troubleshooting"
sidebar_current: "other-debugging"
---

# Debugging

As much as we try to keep Vagrant stable and bug free, it is inevitable
that issues will arise and Vagrant will behave in unexpected ways. In
these cases, Vagrant has amazing [support](http://www.vagrantup.com/support.html)
channels available to assist you.

When using these support channels, it is generally helpful to include
debugging logs along with any error reports. These logs can often help you
troubleshoot any problems you may be having.

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
...
```

On Windows, multiple steps are required:

```
$ set VAGRANT_LOG=info
$ vagrant up
...
```

You can also get the debug level output using the `--debug` command line
option. For example:

```
$ vagrant up --debug
...
```

If you plan on submitting a bug report, please submit debug-level logs
along with the report using [gist](https://gist.github.com/) or
some other paste service.
