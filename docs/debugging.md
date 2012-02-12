---
layout: documentation
title: Documentation - Debugging
---
# Debugging

More information about debugging and troubleshooting Vagrant is forthcoming.
However, those who have prior experience debugging Ruby applications may find
enabling the built-in logging framework useful in debugging and developing
patches.

To do so, simply set the shell environment variable `VAGRANT_LOG` to the
desired log level name (case-insensitive), such as `INFO` or `DEBUG`. For
example:

    $ VAGRANT_LOG=INFO vagrant up

Or:

    $ export VAGRANT_LOG=DEBUG
    $ vagrant reload

Users are encouraged to start with the `INFO` level, as it adds a significant
amount of additional information over the default output without becoming
unreadable.
