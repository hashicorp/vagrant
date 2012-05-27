---
layout: getting_started
title: Getting Started - Rebuild Instantly

current: Rebuild Instantly
previous: Teardown
previous_url: /docs/getting-started/teardown.html
---
# Rebuild Instantly

Let's assume its time to work on that web project again. Maybe
its the next day at work, maybe its the next _year_ at work, but
your boss wants you to work on that web project again. Worried
about dependencies? Software versions mismatched maybe?

Don't worry! We already built the development environment for the web
project with Vagrant! Rebuilding is a snap.

**Note:** If you're following along and haven't already completely
destroyed your virtual environment, please do so by running
`vagrant destroy` so you can really experience this step of the
getting started guide.

Are you ready for this? Go back to that web project directory
and issue the following command:

{% highlight bash %}
$ vagrant up
{% endhighlight %}

**That's _it_!** Really! In about 5 minutes or so after Vagrant
completes setting up your environment, it should be exactly as
you remembered it: same server layout, same dependency versions,
no extraneous software, etc.
