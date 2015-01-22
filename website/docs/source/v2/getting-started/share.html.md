---
page_title: "Share - Getting Started"
sidebar_current: "gettingstarted-share"
---

# Share

Now that we have a web server up and running and accessible from your machine,
we have a fairly functional development environment. But in addition to
providing a development environment, Vagrant also makes it easy to share
and collaborate on these environments. The primary feature to do this in
Vagrant is called [Vagrant Share](/v2/share/index.html).

Vagrant Share lets you share your Vagrant environment to anyone around the
world. It will give you a URL that will route directly to your Vagrant
environment from any device in the world that is connected to the internet.

## Login to HashiCorp's Atlas

Before being able to share your Vagrant environment, you'll need an account on
[HashiCorp's Atlas](https://atlas.hashicorp.com). Don't worry, it's free.

Once you have an account, log in using `vagrant login`:

```
$ vagrant login
Username or Email: mitchellh
Password (will be hidden):
You're now logged in!
```

## Share

Once you're logged in, run `vagrant share`:

```
$ vagrant share
...
==> default: Your Vagrant Share is running!
==> default: URL: http://frosty-weasel-0857.vagrantshare.com
...
```

Your URL will be different, so don't try the URL above. Instead, copy
the URL that `vagrant share` outputted for you and visit that in a web
browser. It should load the index page we setup in the previous pages.

Now, modify your "index.html" file and refresh the URL. It will be updated!
That URL is routing directly into your Vagrant environment, and works from
any device in the world that is connected to the internet.

To end the sharing session, hit `Ctrl+C` in your terminal. You can refresh
the URL again to verify that your environment is no longer being shared.

Vagrant Share is much more powerful than simply HTTP sharing. For more
details, see the [complete Vagrant Share documentation](/v2/share/index.html).

<a href="/v2/getting-started/networking.html" class="button inline-button prev-button">Networking</a>
<a href="/v2/getting-started/teardown.html" class="button inline-button next-button">Teardown</a>
