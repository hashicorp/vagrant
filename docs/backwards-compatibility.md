---
layout: default
title: Backwards Compatibility
---

<h1 class="top">Backwards Compatibility Promise</h1>

Vagrant has set high goals for itself to **change the way web
developers work,** but we know that to achieve that, Vagrant needs
to be a _stable and reliable_ tool. One of the main benefits of Vagrant
is that you should be able to go back to a Vagrant powered project
a year later and still be able to build its environment as if it were
made the same day. We plan to uphold the promise to this feature, but to
do so we first need to settle on a standard API and configuration specification.

That being said, **our promise** is to provide backwards compatibility
for every major version of Vagrant. For example, once Vagrant 1.0 is released, we
promise to support that version forever (one way or another).

To reiterate our point, you should be able to go back to a Vagrant 1.0 project
when Vagrant 4.2 is released and still be able to get it up and running with a
single command:

{% highlight bash %}
$ vagrant up
{% endhighlight %}

It is a bold statement, one which we’re sure will introduce significant
development challenges in the future, but we’re committed to it.