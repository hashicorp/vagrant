---
layout: getting_started
title: Getting Started - SSH
---
# SSH

Even though Vagrant allows for a vast amount of configuration through its
commands and the Vagrantfile, nothing beats the power of the command line.
Some times you just have to get into the files and play around to get things
working just right or to debug an application.

Vagrant provides full SSH access to the virtual environments it creates
through a single command: `vagrant ssh`. By running `vagrant ssh`, Vagrant
will automatically drop you into a fully functional terminal shell (it
really is just `ssh`  being run, there is no middle man involved in communicating
from the VM to the host machine).

{% highlight bash %}
$ vagrant ssh
...
Welcome to your vagrant instance!
Last login: Fri Mar  5 23:21:47 2010 from 10.0.2.2
vagrant@vagrantbase:~$
{% endhighlight %}

<div class="info">
  <h3>Using Microsoft Windows?</h3>
  <p>
    SSH is not easy to install or use from the Windows command-line. Instead,
    Vagrant provides you with a <code>ppk</code> file which can be used with
    <a href="http://www.chiark.greenend.org.uk/~sgtatham/putty/">PuTTY</a> to
    connect to your virtual environments.
  </p>
  <p>
    Read more about this issue on the <a href="/docs/getting-started/setup/windows.html">Windows setup page</a>.
  </p>
</div>

## Accessing the Project Files

Vagrant bridges your application with the virtual environment by using a
VirtualBox shared folder. The shared folder location on the virtual machine
is specified with the `config.vm.project_directory` setting which can be set
in the Vagrantfile, but it defaults to `/vagrant`. This can be verified by
checking the files within that folder from the SSH session.

{% highlight bash %}
vagrant@vagrantbase:~$ ls /vagrant
app  config  db  doc  lib  log  public  Rakefile
README  script  test  tmp  Vagrantfile  vendor
{% endhighlight %}

The VM has both read and write access to the shared folder. Remember: Any
changes are mirrored across both systems.

## Creating the SQLite Database

Before we work on provisioning or anything else, its now important that
we create the SQLite database for the project. Sure, this could've been
done on the host side, but we're going to do it through SSH on the virtual
machine to verify that rails works, at least to that extent. Be sure to
`vagrant up` prior to doing this:

{% highlight bash %}
$ vagrant ssh
...
Welcome to your vagrant instance!
Last login: Fri Mar  5 23:21:47 2010 from 10.0.2.2
vagrant@vagrantbase:~$ cd /vagrant
vagrant@vagrantbase:/vagrant$ sudo rake db:create
(in /vagrant)
vagrant@vagrantbase:~$
{% endhighlight %}

