---
layout: contribute
title: Contribute Documentation - Run the Site

section: docs
current: Run the Site
---
# Run the Vagrant Website Locally

Once you have checked out the code for the Vagrant website,
running it is simple! This page will cover how to get the tools necessary
to run the website, and then how to use those tools to get the
site up and running.

## Dependencies

The website for Vagrant is generated using [Jekyll](http://jekyllrb.com/).
The dependencies you'll need before running the website are:

* Ruby and RubyGems
* [Bundler](http://gembundler.com) gem.
* Python and [Pygments](http://pygments.org/) (for syntax highlighting)

Once the above dependencies are installed, go to the directory containing
the Vagrant source code, making sure you're on the `docs` branch. In that
directory, grab the Ruby dependencies by running `bundle`:

{% highlight bash %}
$ bundle
{% endhighlight %}

After this, all the dependencies should be satisfied.

## Run the Site

Once you have all the dependencies, running the website is simple:

{% highlight bash %}
$ jekyll --server --auto
{% endhighlight %}

The above command will start a local web server to serve the site.
The `--auto` flag tells Jekyll to autogenerate the pages as they
change. Note that the first time you run this, it may take anywhere
from 1 to 5 minutes to have the site completely generated.

You can typically visit the site now at `localhost:4000`, but you
should read the Jekyll output to verify this address.

The site you're viewing should be an identical clone to the
site available at `http://vagrantup.com`. If there are any major
differences, something may have gone wrong.
