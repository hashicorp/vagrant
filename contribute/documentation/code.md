---
layout: contribute
title: Contribute Documentation - Get the Code

section: docs
current: Get the Code
---
# Get the Vagrant Website Code

The code for the Vagrant website is in the `docs` branch of the
main Vagrant source repository. [This branch can be viewed here](https://github.com/mitchellh/vagrant/tree/docs). To get the code, clone the repository and checkout
the `docs` branch:

{% highlight bash %}
$ git clone -b docs git://github.com/mitchellh/vagrant.git
$ cd vagrant
{% endhighlight %}

At this point, if you look at the files available, you should start
seeing many markdown files. If you look in the `static` folder, you'll
see static assets (images, CSS, etc.). In general, the folder structure
should begin to look like a website.

Congratulations, you now have the code to the website! The next section
covers how to run the site locally so you can see any changes you make.
