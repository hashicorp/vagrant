---
layout: "docs"
page_title: "Share - Getting Started"
sidebar_current: "gettingstarted-share"
description: |-
  Now that we have a web server up and running and accessible from your machine,
  we have a fairly functional development environment. But in addition to
  providing a development environment, Vagrant also makes it easy to share
  and collaborate on these environments. The primary feature to do this in
  Vagrant is called Vagrant Share.
---

# Share

Now that we have a web server up and running and accessible from your machine,
we have a fairly functional development environment. But in addition to
providing a development environment, Vagrant also makes it easy to share
and collaborate on these environments. The primary feature to do this in
Vagrant is called [Vagrant Share](/docs/share/).

Vagrant Share lets you share your Vagrant environment to anyone around the
world with an Internet connection. It will give you a URL that will route
directly to your Vagrant environment from any device in the world that is
connected to the Internet.

## Login to HashiCorp's Atlas

Before being able to share your Vagrant environment, you will need an account on
[HashiCorp's Atlas](/docs/other/atlas.html). Do not worry, it is free.

Once you have an account, log in using `vagrant login`:

```
$ vagrant login
Username or Email: mitchellh
Password (will be hidden):
You are now logged in!
```

## Share

Once you are logged in, run `vagrant share`:

```
$ vagrant share
...
==> default: Your Vagrant Share is running!
==> default: URL: http://frosty-weasel-0857.vagrantshare.com
...
```

Your URL will be different, so do not try the URL above. Instead, copy
the URL that `vagrant share` outputted for you and visit that in a web
browser. It should load the Apache page we setup earlier.

If you modify the files in your shared folder and refresh the URL, you will
see it update! The URL is routing directly into your Vagrant environment,
and works from any device in the world that is connected to the internet.

To end the sharing session, hit `Ctrl+C` in your terminal. You can refresh
the URL again to verify that your environment is no longer being shared.

Vagrant Share is much more powerful than simply HTTP sharing. For more
details, see the [complete Vagrant Share documentation](/docs/share/).

~> **Vagrant share is not designed to serve production traffic!** Please do not
rely on Vagrant share outside of development or Q/A. The Vagrant share service
is not designed to carry production-level traffic.

## Next Steps

You have successfully shared your environment with the world. Congratulations!
Read on to learn about the [teardown process](/docs/getting-started/teardown.html).
