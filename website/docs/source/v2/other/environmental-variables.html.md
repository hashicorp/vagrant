---
page_title: "Environmental Variables"
sidebar_current: "other-envvars"
---

# Environmental Variables

Vagrant has a set of environmental variables that can be used to
configure and control it in a global way. This page lists those environmental
variables.

## VAGRANT\_DEBUG\_LAUNCHER

For performance reasons, especially for Windows users, Vagrant uses a static
binary to launch the actual Vagrant process. If you have _very_ early issues
when launching Vagrant from the official installer, you can specify the
`VAGRANT_DEBUG_LAUNCHER` environment variable to output debugging information
about the launch process.

## VAGRANT\_CHECKPOINT\_DISABLE

Vagrant does occasional network calls to check whether the version of Vagrant
that is running locally is up to date. We understand that software making remote
calls over the internet for any reason can be undesirable. To surpress these
calls, set the environment variable `VAGRANT_CHECKPOINT_DISABLE` to any
non-empty value.

## VAGRANT\_CWD

`VAGRANT_CWD` can be set to change the working directory of Vagrant. By
default, Vagrant uses the current directory you're in. The working directory
is important because it is where Vagrant looks for the Vagrantfile. It
also defines how relative paths in the Vagrantfile are expanded, since they're
expanded relative to where the Vagrantfile is found.

This environmental variable is most commonly set when running Vagrant from
a scripting environment in order to set the directory that Vagrant sees.

## VAGRANT\_DOTFILE\_PATH

`VAGRANT_DOTFILE_PATH` can be set to change the directory where Vagrant stores VM-specific state, such as the VirtualBox VM UUID. By default, this is set to `.vagrant`. If you keep your Vagrantfile in a Dropbox folder in order to share the folder between your desktop and laptop (for example), Vagrant will overwrite the files in this directory with the details of the VM on the most recently-used host. To avoid this, you could set `VAGRANT_DOTFILE_PATH` to `.vagrant-laptop` and `.vagrant-desktop` on the respective machines. (Remember to update your `.gitignore`!)

## VAGRANT\_HOME

`VAGRANT_HOME` can be set to change the directory where Vagrant stores
global state. By default, this is set to `~/.vagrant.d`. The Vagrant home
directory is where things such as boxes are stored, so it can actually become
quite large on disk.

## VAGRANT\_LOG

`VAGRANT_LOG` specifies the verbosity of log messages from Vagrant.
By default, Vagrant does not actively show any log messages.

Log messages are very useful when troubleshooting issues, reporting
bugs, or getting support. At the most verbose level, Vagrant outputs
basically everything it is doing.

Available log levels are "debug," "info," "warn," and "error." Both
"warn" and "error" are practically useless since there are very few
cases of these, and Vagrant generally reports them within the normal
output.

"info" is a good level to start with if you're having problems, because
while it is much louder than normal output, it is still very human-readable
and can help identify certain issues.

"debug" output is _extremely_ verbose and can be difficult to read without
some knowledge of Vagrant internals. It is the best output to attach to
a support request or bug report, however.

## VAGRANT\_NO\_COLOR

If this is set to any value, then Vagrant will not use any colorized
output. This is useful if you're logging the output to a file or
on a system that doesn't support colors.

The equivalent behavior can be achieved by using the `--no-color` flag
on a command-by-command basis. This environmental variable is useful
for setting this flag globally.

## VAGRANT\_NO\_PLUGINS

If this is set to any value, then Vagrant will not load any 3rd party
plugins. This is useful if you install a plugin and it is introducing
instability to Vagrant, or if you want a specific Vagrant environment to
not load plugins.

Note that any `vagrant plugin` commands automatically don't load any
plugins, so if you do install any unstable plugins, you can always use
the `vagrant plugin` commands without having to worry.

## VAGRANT\_SKIP\_SUBPROCESS\_JAILBREAK

As of Vagrant 1.7.3, Vagrant tries to intelligently detect if it is running in
the installer or running via Bundler. Although not officially supported, Vagrant
tries its best to work when executed via Bundler. When Vagrant detects that you
have spawned a subprocess that lives outside of Vagrant's installer, Vagrant
will do its best to reset the preserved environment dring the subprocess
execution.

If Vagrant detects it is running outside of the officially installer, the
original environment will always be restored. You can disable this automatic
jailbreak by setting the `VAGRANT_SKIP_SUBPROCES_JAILBREAK`.

## VAGRANT\_VAGRANTFILE

This specifies the filename of the Vagrantfile that Vagrant searches for.
By default, this is "Vagrantfile." Note that this is _not_ a file path,
but just a filename.

This environmental variable is commonly used in scripting environments
where a single folder may contain multiple Vagrantfiles representing
different configurations.
