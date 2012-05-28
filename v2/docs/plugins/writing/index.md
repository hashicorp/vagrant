---
layout: v2_documentation
title: Documentation - Writing Plugins

section: plugins
current: Overview
---
# Writing Plugins

Plugins are written using Ruby code, and anything but the most trivial
plugins are distributed using RubyGems. Creating a Vagrant plugin requires
a small amount of Ruby knowledge, but most of it can be picked up along the
way as long as you're programmed before.

If you're writing your first plugin, I recommend writing it directly
in a `Vagrantfile`, so that you don't have to worry about RubyGems. If
you're looking to distribute your plugin, the documentation covers the
entire [RubyGems packaging process](#) for you.

Plugins are composed of a number of parts:

* The [plugin definition](/v2/docs/plugins/writing/definition.html) which
  contains metadata about the plugin and lets Vagrant know what other pieces
  the plugin contains.
* Zero or more [commands](#), [configuration keys](#), [guests](#), [hosts](#),
  or [provisioners](#).

To get started, write your first [plugin definition](/v2/docs/plugins/writing/definition.html).
After this, you can either extend your plugin with full-fledged commands, provisioners,
etc. or you can start with an [easy plugin](#) to get something working
much more quickly.
