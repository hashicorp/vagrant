# Built-in Plugins

This directory contains all the "built-in" plugins. These are real plugins,
they dogfood the full plugin SDK, do not depend on any internal packages,
and they are executed via subprocess just like a real plugin would be.

The difference is that these plugins are linked directly into the single
command binary. We do this currently for ease of development of the project.
In future we will split these out into standalone repositories and
binaries.
