---
layout: getting_started
title: Getting Started - SSH

current: SSH
previous: Boxes
previous_url: /docs/getting-started/boxes.html
next: Provisioning
next_url: /docs/getting-started/provisioning.html
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

<div class="alert alert-block alert-notice">
  <h3>Using Microsoft Windows?</h3>
  <p>
    An SSH client is generally not distributed with Windows by default. Because of this,
    if you are on Windows, Vagrant will instead output SSH authentication info
    which you can use with your favorite SSH client, such as
    <a href="http://www.chiark.greenend.org.uk/~sgtatham/putty/">PuTTY</a>.
  </p>
  <p>
    PuTTY may not reconize the <code>insecure_private_key</code> provided by
    vagrant as a valid private key.  To remedy this, first grab the 
    <a href="http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html">PuTTYgen app</a>.  
    Then use PuTTYgen and import the <code>insecure_private_key</code> (found
    in the .vagrant.d dir in your home directory) and save a ppk file from that
    private key.  Use the ppk file instead of the default one when SSHing into
    your vagrant box.
  </p>
</div>

## Accessing the Project Files

Vagrant bridges your application with the virtual environment by using a
VirtualBox shared folder. The shared folder location on the virtual machine
defaults to `/vagrant`, but can be changed. This can be verified by listing
the files within that folder in the SSH session:

{% highlight bash %}
vagrant@vagrantbase:~$ ls /vagrant
index.html Vagrantfile
{% endhighlight %}

The VM has both read and write access to the shared folder.

**Remember: Any changes are mirrored across both systems.**
