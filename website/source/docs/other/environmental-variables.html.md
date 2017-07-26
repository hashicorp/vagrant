---
layout: "docs"
page_title: "Environmental Variables"
sidebar_current: "other-envvars"
description: |-
  Vagrant has a set of environmental variables that can be used to
  configure and control it in a global way. This page lists those environmental
  variables.
---

# Environmental Variables

Vagrant has a set of environmental variables that can be used to
configure and control it in a global way. This page lists those environmental
variables.

## `VAGRANT_DEBUG_LAUNCHER`

For performance reasons, especially for Windows users, Vagrant uses a static
binary to launch the actual Vagrant process. If you have _very_ early issues
when launching Vagrant from the official installer, you can specify the
`VAGRANT_DEBUG_LAUNCHER` environment variable to output debugging information
about the launch process.

## `VAGRANT_DEFAULT_PROVIDER`

This configures the default provider Vagrant will use.

This normally does not need to be set since Vagrant is fairly intelligent
about how to detect the default provider. By setting this, you will force
Vagrant to use this provider for any _new_ Vagrant environments. Existing
Vagrant environments will continue to use the provider they came `up` with.
Once you `vagrant destroy` existing environments, this will take effect.

## `VAGRANT_PREFERRED_PROVIDERS`

This configures providers that Vagrant should prefer.

Much like the `VAGRANT_DEFAULT_PROVIDER` this environment variable normally
does not need to be set. By setting this you will instruct Vagrant to
_prefer_ providers defined in this environment variable for any _new_
Vagrant environments. Existing Vagrant environments will continue to use
the provider they came `up` with. Once you `vagrant destroy` existing environments,
this will take effect. A single provider can be defined within this environment
variable or a comma delimited list of providers.

## `VAGRANT_BOX_UPDATE_CHECK_DISABLE`

By default, Vagrant will query the metadata API server to see if a newer
box version is available for download. This optional can be disabled on a
per-Vagrantfile basis with `config.vm.box_check_update`, but it can also be
disabled globally setting `VAGRANT_BOX_UPDATE_CHECK_DISABLE` to any non-empty
value.

This option will not affect global box functions like `vagrant box update`.

## `VAGRANT_CHECKPOINT_DISABLE`

Vagrant does occasional network calls to check whether the version of Vagrant
that is running locally is up to date. We understand that software making remote
calls over the internet for any reason can be undesirable. To suppress these
calls, set the environment variable `VAGRANT_CHECKPOINT_DISABLE` to any
non-empty value.

If you use other HashiCorp tools like Packer and would prefer to configure this
setting only once, you can set `CHECKPOINT_DISABLE` instead.

## `VAGRANT_CWD`

`VAGRANT_CWD` can be set to change the working directory of Vagrant. By
default, Vagrant uses the current directory you are in. The working directory
is important because it is where Vagrant looks for the Vagrantfile. It
also defines how relative paths in the Vagrantfile are expanded, since they're
expanded relative to where the Vagrantfile is found.

This environmental variable is most commonly set when running Vagrant from
a scripting environment in order to set the directory that Vagrant sees.

## `VAGRANT_DOTFILE_PATH`

`VAGRANT_DOTFILE_PATH` can be set to change the directory where Vagrant stores
VM-specific state, such as the VirtualBox VM UUID. By default, this is set to
`.vagrant`. If you keep your Vagrantfile in a Dropbox folder in order to share
the folder between your desktop and laptop (for example), Vagrant will overwrite
the files in this directory with the details of the VM on the most recently-used
host. To avoid this, you could set `VAGRANT_DOTFILE_PATH` to `.vagrant-laptop`
and `.vagrant-desktop` on the respective machines. (Remember to update your
`.gitignore`!)

## `VAGRANT_HOME`

`VAGRANT_HOME` can be set to change the directory where Vagrant stores
global state. By default, this is set to `~/.vagrant.d`. The Vagrant home
directory is where things such as boxes are stored, so it can actually become
quite large on disk.

## `VAGRANT_LOG`

`VAGRANT_LOG` specifies the verbosity of log messages from Vagrant.
By default, Vagrant does not actively show any log messages.

Log messages are very useful when troubleshooting issues, reporting
bugs, or getting support. At the most verbose level, Vagrant outputs
basically everything it is doing.

Available log levels are "debug," "info," "warn," and "error." Both
"warn" and "error" are practically useless since there are very few
cases of these, and Vagrant generally reports them within the normal
output.

"info" is a good level to start with if you are having problems, because
while it is much louder than normal output, it is still very human-readable
and can help identify certain issues.

"debug" output is _extremely_ verbose and can be difficult to read without
some knowledge of Vagrant internals. It is the best output to attach to
a support request or bug report, however.

## `VAGRANT_NO_COLOR`

If this is set to any value, then Vagrant will not use any colorized
output. This is useful if you are logging the output to a file or
on a system that does not support colors.

The equivalent behavior can be achieved by using the `--no-color` flag
on a command-by-command basis. This environmental variable is useful
for setting this flag globally.

## `VAGRANT_FORCE_COLOR`

If this is set to any value, then Vagrant will force colored output, even
if it detected that there is no TTY or the current environment does not
support it.

The equivalent behavior can be achieved by using the `--color` flag on a
command-by-command basis. This environmental variable is useful for setting
this flag globally.

## `VAGRANT_NO_PLUGINS`

If this is set to any value, then Vagrant will not load any 3rd party
plugins. This is useful if you install a plugin and it is introducing
instability to Vagrant, or if you want a specific Vagrant environment to
not load plugins.

Note that any `vagrant plugin` commands automatically do not load any
plugins, so if you do install any unstable plugins, you can always use
the `vagrant plugin` commands without having to worry.

## `VAGRANT_ALLOW_PLUGIN_SOURCE_ERRORS`

If this is set to any value, then Vagrant will not error when a configured
plugin source is unavailable. When installing a Vagrant plugin Vagrant
will error and halt if a plugin source is inaccessible. In some cases it
may be desirable to ignore inaccessible sources and continue with the
plugin installation. Enabling this value will cause Vagrant to simply log
the plugin source error and continue.

## `VAGRANT_NO_PARALLEL`

If this is set, Vagrant will not perform any parallel operations (such as
parallel box provisioning). All operations will be performed in serial.

## `VAGRANT_DETECTED_OS`

This environment variable may be set by the Vagrant launcher to help determine
the current runtime platform. In general Vagrant will set this value when running
on a Windows host using a cygwin or msys based shell. If this value is set, the
Vagrant launcher will not modify it.

## `VAGRANT_DETECTED_ARCH`

This environment variable may be set by the Vagrant launcher to help determine
the current runtime architecture in use. In general Vagrant will set this value
when running on a Windows host using a cygwin or msys based shell. The value
the Vagrant launcher may set in this environment variable will not always match
the actual architecture of the platform itself. Instead it signifies the detected
architecture of the environment it is running within. If this value is set, the
Vagrant launcher will not modify it.

## `VAGRANT_WINPTY_DISABLE`

If this is set, Vagrant will _not_ wrap interactive processes with winpty where
required.

## `VAGRANT_PREFER_SYSTEM_BIN`

If this is set, Vagrant will prefer using utility executables (like `ssh` and `rsync`)
from the local system instead of those vendored within the Vagrant installation.
This currently only applies to Windows systems.

## `VAGRANT_SKIP_SUBPROCESS_JAILBREAK`

As of Vagrant 1.7.3, Vagrant tries to intelligently detect if it is running in
the installer or running via Bundler. Although not officially supported, Vagrant
tries its best to work when executed via Bundler. When Vagrant detects that you
have spawned a subprocess that lives outside of Vagrant's installer, Vagrant
will do its best to reset the preserved environment dring the subprocess
execution.

If Vagrant detects it is running outside of the officially installer, the
original environment will always be restored. You can disable this automatic
jailbreak by setting `VAGRANT_SKIP_SUBPROCESS_JAILBREAK`.

## `VAGRANT_VAGRANTFILE`

This specifies the filename of the Vagrantfile that Vagrant searches for.
By default, this is "Vagrantfile". Note that this is _not_ a file path,
but just a filename.

This environmental variable is commonly used in scripting environments
where a single folder may contain multiple Vagrantfiles representing
different configurations.
