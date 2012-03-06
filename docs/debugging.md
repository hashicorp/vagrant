---
layout: documentation
title: Documentation - Debugging

current: Debugging
---
# Debugging

If you run into issues with Vagrant, enabling logging can divulge helpful
information in order to troubleshoot your issues. To enable logging, the
`VAGRANT_LOG` environmental variable must be set to the desired log
level name, such as `INFO` or `DEBUG`. For example, on linux systems:

    $ VAGRANT_LOG=INFO vagrant up

On Windows, you must use `set` to set an environmental variable:

    > set VAGRANT_LOG=INFO
    > vagrant up

Users are encouraged to start with the `INFO` level, as it adds a significant
amount of additional information over the default output without becoming
unreadable.

If you plan on submitting a bug report or an issue, please attach `DEBUG`
level log output of the command that fails.
