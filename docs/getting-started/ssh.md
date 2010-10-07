---
layout: getting_started
title: Getting Started - SSH
---
# SSH

Even though Vagrant allows for a vast amount of configuration through its
commands and the Vagrantfile, nothing beats the power of the command line.
Sometimes you just have to get into the files and play around to get things
working just right or to debug an application.

Vagrant provides full SSH access to the virtual environments it creates
through a single command: `vagrant ssh`. By running `vagrant ssh`, Vagrant
will automatically drop you into a fully functional terminal shell (it
really is just `ssh`  being run, there is no middle man involved in communicating
from the VM to the host machine).

After running `vagrant ssh`, you should see something similar to the
following:

{% highlight bash %}
$ vagrant ssh
...
vagrant@vagrantup:~$
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
is specified with the `config.vm.project_directory` in the Vagrantfile, but
defaults to `/vagrant`. This can be verified by listing the files within
that folder in the SSH session:

{% highlight bash %}
vagrant@vagrantbase:~$ ls /vagrant
index.html Vagrantfile
{% endhighlight %}

The VM has both read and write access to the shared folder.

**Remember: Any changes are mirrored across both systems.**

[&larr; Boxes](/docs/getting-started/boxes.html) &middot; SSH &middot; [Provisioning &rarr;](/docs/getting-started/provisioning.html)
