---
layout: documentation
title: Documentation - Unison Shared Folder Syncing
---
# Unison Shared Folder Syncing

<div class="info">
  <h3>Warning! Unsupported Feature</h3>
  <p>
    Unison folder syncing was an attempt at a solution to slow VirtualBox
    shared folders. Since this attempt, NFS shared folders appear to be a
    stronger solution. Because of this, Unison shared folders are not officially
    supported, despite significant documentation and code in place.
  </p>
  <p>
    This documentation is simply left over here. Unison shared folders may
    be removed at any time.
  </p>
</div>

Its been a long known issue that VirtualBox shared folder performance
degrades quickly as the number of files in the shared folder increases.
As a project reaches thousands of files, doing simple things like running
unit tests or even just running an app server can be many orders
of magnitude slower (e.g. from 5 seconds to taking 5 minutes).

If you're seeing this sort of performance drop-off in your shared folders,
[Unison](http://www.cis.upenn.edu/~bcpierce/unison/) shared folder syncing
can help! Vagrant will automate a cron job to call `unison` to sync the
real shared folder with a guest-local folder. You run all your unit tests,
app server, etc. on the guest-local folder, while the shared folder is
automatically synced to it.

<div class="info">
  <h3>The Trade-Off</h3>
  <p>
    There is a slight trade-off when using <code>unison</code> folder syncing: There
    will be a 5 to 10 seconds delay while Unison syncs the folders. So instead
    of seeing your file changes instantly on the guest, you'll have to wait
    a few seconds (shouldn't ever be more than 15 seconds), for the changes
    to propagate.
  </p>
  <p>
    For most people, including myself, this is a fine trade-off instead of
    waiting 5 minutes for something simple like running a single unit test.
  </p>
</div>

## Prerequisites

Before enabling shared folder syncing via unison for any shared folders,
the guest OS must have [Unison](http://www.cis.upenn.edu/~bcpierce/unison/)
installed.

Unison is available on most operating systems through their respective
package managers. For example, on Ubuntu, you can install unison with
a simple `sudo apt-get install unison`.

Its recommended that you install unison and package that box for the future
so you don't need to install unison every time you wish to use shared
folder syncing.

## Enabling Shared Folder Syncing

Shared folder syncing can be enabled by simpling setting a flag on the
`config.vm.share_folder` method. The example below overrides the default
root folder sharing to be setup for shared folder syncing:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.share_folder("v-root", "/vagrant", ".", :sync => true)
end
{% endhighlight %}

Setting the `:sync` flag will cause that folder to be synced via unison.

## How it Works

When a shared folder is flagged to be synced via Unison, Vagrant will
append a sync suffix to the end of the guest path (where the shared
folder will be), and will make Unison sync from that shared folder to
the actual path you specify.

To make this clear, consider the above example, where the root folder
was marked to be synced. The steps below are taken:

1. The shared folder is actually mounted to `/vagrant.sync`. This is
   the typical "slow" VirtualBox shared folder.
2. Unison is configured on a cron to sync the folder to the original
   guest path: `/vagrant`.
3. The syncing script runs in the background constantly (with the cron
   verifying its running every minute) to sync the two folders. Any
   app servers, unit test runners, etc, should use the syncced folder:
   `/vagrant` and _not_ the VirtualBox shared folder.

## Unison Customization

[Unison](http://www.cis.upenn.edu/~bcpierce/unison/) comes with
[many configurable options](http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#prefs) and Vagrant does not prevent
you from setting any of these. You can customize the command line
parameters to unison via the `config.unison.options` value. Note
that changing these may cause the syncing to fail or hang. To diagnose
these failures, check the log files which are typically dumped in
the user's home directory.

There are other options which are configurable as well. Please see
the [Vagrantfile](/docs/vagrantfile.html) page for more information
on these.
