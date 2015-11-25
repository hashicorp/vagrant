---
page_title: "vagrant port - Command-Line Interface"
sidebar_current: "cli-port"
---

# Port

**Command: `vagrant port`**

The port command displays the full list of guest ports mapped to the host
machine ports:

```
$ vagrant port
    22 (guest) => 2222 (host)
    80 (guest) => 8080 (host)
```

In a multi-machine Vagrantfile, the name of the machine must be specified:

```
$ vagrant port my-machine
```

## Options

* `--guest PORT` - This displays just the host port that corresponds to the
  given guest port. If the guest is not forwarding that port, an error is
  returned. This is useful for quick scripting, for example:

        $ ssh -p $(vagrant port --guest 22)

* `--machine-readable` - This tells Vagrant to display machine-readable output
  instead of the human-friendly output. More information is available in the
  [machine-readable output](/v2/cli/machine-readable.html) documentation.
