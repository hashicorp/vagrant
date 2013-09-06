---
page_title: "vagrant package - Command-Line Interface"
sidebar_current: "cli-package"
---

# Package

**Command: `vagrant package`**

This packages a currently running _VirtualBox_ environment into a
re-usable [box](/v2/boxes.html). This command cannot be used with
any other [provider](/v2/providers/index.html). A future version of Vagrant
will address packaging boxes for other providers. Until then, they must
be made by hand.

## Options

* `--base NAME` - Instead of packaging a VirtualBox machine that Vagrant
  manages, this will package a VirtualBox machine that VirtualBox manages.
  `NAME` should be the name or UUID of the machine from the VirtualBox GUI.

* `--output NAME` - The resulting package will be saved as `NAME`. By default,
  it will be saved as `package.box`.

* `--include x,y,z` - Additional files will be packaged with the box. These
  can be used by a packaged Vagrantfile (documented below) to perform additional
  tasks.

* `--vagrantfile FILE` - Packages a Vagrantfile with the box, that is loaded
  as part of the [Vagrantfile load order](/v2/vagrantfile/index.html#load-order)
  when the resulting box is used.

<div class="alert alert-info">
	<p>
		<strong>A common misconception</strong> is that the <code>--vagrantfile</code>
		option will package a Vagrantfile that is used when <code>vagrant init</code>
		is used with this box. This is not the case. Instead, a Vagrantfile
		is loaded and read as part of the Vagrant load process when the box is
		used. For more information, read about the
		<a href="/v2/vagrantfile/index.html#load-order">Vagrantfile load order</a>.
	</p>
</div>

