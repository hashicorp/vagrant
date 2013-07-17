## 1.2.4 (July 16, 2013)

FEATURES:

  - Chef solo and client provisioning now support a `custom_config_path`
    setting that accepts a path to a Ruby file to load as part of Chef
    configuration, allowing you to override any setting available. [GH-876]
  - CFEngine provisioner: you can now specify the package name to install,
    so CFEngine enterprise is supported. [GH-1920]

IMPROVEMENTS:

  - `vagrant box remove` works with only the name of the box if that
    box exists only backed by one provider. [GH-1032]
  - `vagrant destroy` returns exit status 1 if any of the confirmations
    are declined. [GH-923]
  - Forwarded ports can specify a host IP and guest IP to bind to. [GH-1121]
  - You can now set the "ip" of a private network that uses DHCP. This will
    change the subnet and such that the DHCP server uses.
  - Add `file_cache_path` support for chef_solo. [GH-1897]

BUG FIXES:

  - VBoxManage or any other executable missing from PATH properly
    reported. Regression from 1.2.2. [GH-1928]
  - Boxes downloaded as part of `vagrant up` are now done so _prior_ to
    config validation. This allows Vagrantfiles to references files that
    may be in the box itself. [GH-1061]
  - Chef removes dna.json and encrypted data bag secret file prior to
    uploading. [GH-1111]
  - NFS synced folders exporting sub-directories of other exported folders now
    works properly. [GH-785]
  - NFS shared folders properly dereference symlinks so that the real path
    is used, avoiding mount errors [GH-1101]
  - SSH channel is closed after the exit status is received, potentially
    eliminating any SSH hangs. [GH-603]
  - Fix regression where VirtualBox detection wasn't working anymore. [GH-1918]
  - NFS shared folders with single quotes in their name now work properly. [GH-1166]
  - Debian/Ubuntu request DHCP renewal when hostname changes, which will
    fix issues with FQDN detecting. [GH-1929]
  - SSH adds the "DSAAuthentication=yes" option in case that is disabled
    on the user's system. [GH-1900]

## 1.2.3 (July 9, 2013)

FEATURES:

  - Puppet provisioner now supports Hiera by specifying a `hiera_config_path`.
  - Added a `working_directory` configuration option to the Puppet apply
    provisioner so you can specify the working directory when `puppet` is
    called, making it friendly to Hiera data and such. [GH-1670]
  - Ability to specify the host IP to bind forwarded ports to. [GH-1785]

IMPROVEMENTS:

  - Setting hostnames works properly on OmniOS. [GH-1672]
  - Better VBoxManage error detection on Windows systems. This avoids
    some major issues where Vagrant would sometimes "lose" your VM. [GH-1669]
  - Better detection of missing VirtualBox kernel drivers on Linux
    systems. [GH-1671]
  - More precise detection of Ubuntu/Debian guests so that running Vagrant
    within an LXC container works properly now.
  - Allow strings in addition to symbols to more places in V1 configuration
    as well as V2 configuration.
  - Add `ARPCHECK=0` to RedHat OS family network configuration. [GH-1815]
  - Add SSH agent forwarding sample to initial Vagrantfile. [GH-1808]
  - VirtualBox: Only configure networks if there are any to configure.
    This allows linux's that don't implement this capability to work with
    Vagrant. [GH-1796]
  - Default SSH forwarded port now binds to 127.0.0.1 so only local
    connections are allowed. [GH-1785]
  - Use `netctl` for Arch Linux network configuration. [GH-1760]
  - Improve fedora host detection regular expression. [GH-1913]
  - SSH shows a proper error on EHOSTUNREACH. [GH-1911]

BUG FIXES:

  - Ignore "guest not ready" errors when attempting to graceful halt and
    carry on checks whether the halt succeeded. [GH-1679]
  - Handle the case where a roles path for Chef solo isn't properly
	defined. [GH-1665]
  - Finding V1 boxes now works properly again to avoid "box not found"
    errors. [GH-1691]
  - Setting hostname on SLES 11 works again. [GH-1781]
  - `config.vm.guest` properly forces guests again. [GH-1800]
  - The `read_ip_address` capability for linux properly reads the IP
    of only the first network interface. [GH-1799]
  - Validate that an IP is given for a private network. [GH-1788]
  - Fix uninitialized constant error for Gentoo plugin. [GH-1698]

## 1.2.2 (April 23, 2013)

FEATURES:

  - New `DestroyConfirm` built-in middleware for providers so they can
    more easily conform to the `destroy` action.

IMPROVEMENTS:

  - No longer an error if the Chef run list is empty. It is now
    a warning. [GH-1620]
  - Better locking around handling the `box_url` parameter for
    parallel providers.
  - Solaris guest is now properly detected on SmartOS, OmniOS, etc. [GH-1639]
  - Guest addition version detection is more robust, attempting other
    routes to get the version, and also retrying a few times. [GH-1575]

BUG FIXES:

  - `vagrant package --base` works again. [GH-1615]
  - Box overrides specified in provider config overrides no longer
    fail to detect the box. [GH-1617]
  - In a multi-machine environment, a box not found won't be downloaded
    multiple times. [GH-1467]
  - `vagrant box add` with a file path now works correctly on Windows
    when a drive letter is specified.
  - DOS line endings are converted to Unix line endings for the
    shell provisioner automatically. [GH-1495]

## 1.2.1 (April 17, 2013)

FEATURES:

  - Add a `--[no-]parallel` flag to `vagrant up` to enable/disable
    parallelism. Vagrant will parallelize by default.

IMPROVEMENTS:

  - Get rid of arbitrary 4 second sleep when connecting via SSH. The
    issue it was attempting to work around may be gone now.

BUG FIXES:

  - Chef solo run list properly set. [GH-1608]
  - Follow 30x redirects when downloading boxes. [GH-1607]
  - Chef client config defaults are done properly. [GH-1609]
  - VirtualBox mounts shared folders with the proper owner/group. [GH-1611]
  - Use the Mozilla CA cert bundle for cURL so SSL validation works
    properly.

## 1.2.0 (April 16, 2013)

BACKWARDS INCOMPATIBILITIES:

  - WINDOWS USERS: Vagrant now defaults to using the 'USERPROFILE' environmental
    variable for the home directory if it is set. This means that the default
    location for the Vagrant home directory is now `%USERPROFILE%/.vagrant.d`.
    On Cygwin, this will cause existing Cygwin users to "lose" their boxes.
    To work around this, either set `VAGRANT_HOME` to your Cygwin ".vagrant.d"
    folder or move your ".vagrant.d" folder to `USERPROFILE`. The latter is
    recommended for long-term support.
  - The constant `Vagrant::Environment::VAGRANT_HOME` was removed in favor of
    `Vagrant::Environment#default_vagrant_home`.

FEATURES:

  - Providers can now parallelize! If they explicitly support it, Vagrant
    will run "up" and other commands in parallel. For providers such AWS,
    this means that your instances will come up in parallel. VirtualBox
    does not support this mode.
  - Box downloads are now done via `curl` rather than Ruby's built-in
    HTTP library. This results in massive speedups, support for SSL
    verification, FTP downloads, and more.
  - `config.vm.provider` now takes an optional second parameter to the block,
    allowing you to override any configuration value. These overrides are
    applied last, and therefore override any other configuration value.
    Note that while this feature is available, the "Vagrant way" is instead
    to use box manifests to ensure that the "box" for every provider matches,
    so these sorts of overrides are unnecessary.
  - A new "guest capabilities" system to replace the old "guest" system.
    This new abstraction allows plugins to define "capabilities" that
    certain guest operating systems can implement. This allows greater
    flexibility in doing guest-specific behavior.
  - Ansible provisioner support. [GH-1465]
  - Providers can now support multiple box formats by specifying the
    `box_format:` option.
  - CFEngine provisioner support.
  - `config.ssh.default` settings introduced to set SSH defaults that
    providers can still override. [GH-1479]

IMPROVEMENTS:

  - Full Windows support in cmd.exe, PowerShell, Cygwin, and MingW based
    environments.
  - By adding the "disabled" boolean flag to synced folders you can disable
    them altogether. [GH-1004]
  - Specify the default provider with the `VAGRANT_DEFAULT_PROVIDER`
    environmental variable. [GH-1478]
  - Invalid settings are now caught and shown in a user-friendly way. [GH-1484]
  - Detect PuTTY Link SSH client on Windows and show an error. [GH-1518]
  - `vagrant ssh` in Cygwin won't output DOS path file warnings.
  - Add `--rtcuseutc on` as a sane default for VirtualBox. [GH-912]
  - SSH will send keep-alive packets every 5 seconds by default to
    keep connections alive. Can be disabled with `config.ssh.keep_alive`. [GH-516]
  - Show a message on `vagrant up` if the machine is already running. [GH-1558]
  - "Running provisioner" output now shoes the provisioner shortcut name,
    rather than the less-than-helpful class name.
  - Shared folders with the same guest path will overwrite each other. No
    more shared folder IDs.
  - Shell provisioner outputs script it is running. [GH-1568]
  - Automatically merge forwarded ports that share the same host
    port.

BUG FIXES:

  - The `:mac` option for host-only networks is respected. [GH-1536]
  - Don't preserve modified time when untarring boxes. [GH-1539]
  - Forwarded port auto-correct will not auto-correct to a port
    that is also in use.
  - Cygwin will always output color by default. Specify `--no-color` to
    override this.
  - Assume Cygwin has a TTY for asking for input. [GH-1430]
  - Expand Cygwin paths to Windows paths for calls to VBoxManage and
    for VirtualBox shared folders.
  - Output the proper clear line text for shells in Cygwin when
    reporting dynamic progress.
  - When using `Builder` instances for hooks, the builders will be
    merged for the proper before/after chain. [GH-1555]
  - Use the Vagrant temporary directory again for temporary files
    since they can be quite large and were messing with tmpfs. [GH-1442]
  - Fix issue parsing extra SSH args in `vagrant ssh` in multi-machine
    environments. [GH-1545]
  - Networks come back up properly on RedHat systems after reboot. [GH-921]
  - `config.ssh` settings override all detected SSH settings (regression). [GH-1479]
  - `ssh-config` won't raise an exception if the VirtualBox machine
    is not created. [GH-1562]
  - Multiple machines defined in the same Vagrantfile with the same
    name will properly merge.
  - More robust hostname checking for RedHat. [GH-1566]
  - Cookbook path existence for Chef is no longer an error, so that
    things like librarian and berkshelf plugins work properly. [GH-1570]
  - Chef solo provisioner uses proper SSH username instead of hardcoded
    config. [GH-1576]
  - Shell provisioner takes ownership of uploaded files properly so
    that they can also be manually executed later. [GH-1576]

## 1.1.6 (April 3, 2013)

BUG FIXES:

  - Fix SSH re-use connection logic to drop connection if an
    error occurs.

## 1.1.5 (April 2, 2013)

IMPROVEMENTS:

  - More robust SSH connection close detection.
  - Don't load `vagrant plugin` installed plugins when in a Bundler
    environment. This happens during plugin development. This will make
    Vagrant errors much quieter when developing plugins.
  - Vagrant will detect Bundler environments, make assumptions that you're
    developing plugins, and will quiet its error output a bit.
  - More comprehensive synced folder configuration validation.
  - VBoxManage errors now show the output from the command so that
    users can potentially know what is wrong.

BUG FIXES:

  - Proper error message if invalid provisioner is used. [GH-1515]
  - Don't error on graceful halt if machine just shut down very
    quickly. [GH-1505]
  - Error message if private key for SSH isn't owned by the proper
    user. [GH-1503]
  - Don't error too early when `config.vm.box` is not properly set.
  - Show a human-friendly error if VBoxManage is not found (exit
    status 126). [GH-934]
  - Action hook prepend/append will only prepend or append once.
  - Retry SSH on Errno::EACCES.
  - Show an error if an invalid network type is used.
  - Don't share Chef solo folder if it doesn't exist on host.

## 1.1.4 (March 25, 2013)

BUG FIXES:

  - Default forwarded port adapter for VirtualBox should be 1.

## 1.1.3 (March 25, 2013)

IMPROVEMENTS:

  - Puppet apply provisioner now retains the default module path
    even while specifying custom module paths. [GH-1207]
  - Re-added DHCP support for host-only networks. [GH-1466]
  - Ability to specify a plugin version, plugin sources, and
    pre-release versions using `--plugin-version`, `--plugin-source`,
    and `--plugin-prerelease`. [GH-1461]
  - Move VirtualBox guest addition checks to after the machine
    boots. [GH-1179]
  - Removed `Vagrant::TestHelpers` because it doesn't really work anymore.
  - Add PLX linux guest support. [GH-1490]

BUG FIXES:

  - Attempt to re-establish SSH connection on `Net::SSH::Disconnect`
  - Allow any value that can convert to a string for `Vagrant.plugin`
  - Chef solo `recipe_url` works properly again. [GH-1467]
  - Port collision detection works properly in VirtualBox with
    auto-corrected ports. [GH-1472]
  - Fix obscure error when temp directory is world writable when
    adding boxes.
  - Improved error handling around network interface detection for
    VirtualBox [GH-1480]

## 1.1.2 (March 18, 2013)

BUG FIXES:

  - When not specifying a cookbooks_path for chef-solo, an error won't
    be shown if "cookbooks" folder is missing.
  - Fix typo for exception when no host-only network with NFS. [GH-1448]
  - Use UNSET_VALUE/nil with args on shell provisioner by default since
    `[]` was too truthy. [GH-1447]

## 1.1.1 (March 18, 2013)

IMPROVEMENTS:

  - Don't load plugins on any `vagrant plugin` command, so that errors
    are avoided. [GH-1418]
  - An error will be shown if you forward a port to the same host port
    multiple times.
  - Automatically convert network, provider, and provisioner names to
    symbols internally in case people define them as strings.
  - Using newer versions of net-ssh and net-scp. [GH-1436]

BUG FIXES:

  - Quote keys to StringBlockEditor so keys with spaces, parens, and
    so on work properly.
  - When there is no route to host for SSH, re-establish a new connection.
  - `vagrant package` once again works, no more nil error. [GH-1423]
  - Human friendly error when "metadata.json" is missing in a box.
  - Don't use the full path to the manifest file with the Puppet provisioner
    because it exposes a bug with Puppet path lookup on VMware.
  - Fix bug in VirtualBox provider where port forwarding just didn't work if
    you attempted to forward to a port under 1024. [GH-1421]
  - Fix cross-device box adds for Windows. [GH-1424]
  - Fix minor issues with defaults of configuration of the shell
    provisioner.
  - Fix Puppet server using "host_name" instead of "hostname" [GH-1444]
  - Raise a proper error if no hostonly network is found for NFS with
    VirtualBox. [GH-1437]

## 1.1.0 (March 14, 2013)

BACKWARDS INCOMPATIBILITIES:

  - Vagrantfiles from 1.0.x that _do not use_ any plugins are fully
    backwards compatible. If plugins are used, they must be removed prior
    to upgrading. The new plugin system in place will avoid this issue in
    the future.
  - Lots of changes introduced in the form of a new configuration version and
    format, but this is _opt-in_. Old Vagrantfile format continues to be supported,
    as promised. To use the new features that will be introduced throughout
    the 1.x series, you'll have to upgrade at some point.

FEATURES:

  - Groundwork for **providers**, alternate backends for Vagrant that
    allow Vagrant to power systems other than VirtualBox. Much improvement
    and change will come to this throughout the 1.x lifecycle. The API
    will continue to change, features will be added, and more. Specifically,
    a revamped system for handling shared folders gracefully across providers
    will be introduced in a future release.
  - New plugin system which adds much more structure and stability to
    the overall API. The goal of this system is to make it easier to write
    powerful plugins for Vagrant while providing a backwards-compatible API
    so that plugins will always _load_ (though they will almost certainly
    not be _functional_ in future versions of Vagrant).
  - Plugins are now installed and managed using the `vagrant plugin` interface.
  - Allow "file://" URLs for box URLs. [GH-1087]
  - Emit "vagrant-mount" upstart event when NFS shares are mounted. [GH-1118]
  - Add a VirtualBox provider config `auto_nat_dns_proxy` which when set to
    false will not attempt to automatically manage NAT DNS proxy settings
    with VirtualBox. [GH-1313]
  - `vagrant provision` accepts the `--provision-with` flag [GH-1167]
  - Set the name of VirtualBox machines with `virtualbox.name` in the
    VirtualBox provider config. [GH-1126]
  - `vagrant ssh` will execute an `ssh` binary on Windows if it is on
    your PATH. [GH-933]
  - The environmental variable `VAGRANT_VAGRANTFILE` can be used to
    specify an alternate Vagrantfile filename.

IMPROVEMENTS / BUG FIXES:

  - Vagrant works much better in Cygwin environments on Windows by
    properly resolving Cygwin paths. [GH-1366]
  - Improve the SSH "ready?" check by more gracefully handling timeouts. [GH-841]
  - Human friendly error if connection times out for HTTP downloads. [GH-849]
  - Detect when the VirtualBox installation is incomplete and error. [GH-846]
  - Detect when kernel modules for VirtualBox need to be installed on Gentoo
    systems and report a user-friendly error. [GH-710]
  - All `vagrant` commands that can take a target VM name can take one even
    if you're not in a multi-VM environment. [GH-894]
  - Hostname is set before networks are setup to avoid very slow `sudo`
    speeds on CentOS. [GH-922]
  - `config.ssh.shell` now includes the flags to pass to it, such as `-l` [GH-917]
  - The check for whether a port is open or not is more complete by
    catching ENETUNREACH errors. [GH-948]
  - SSH uses LogLevel FATAL so that errors are still shown.
  - Sending a SIGINT (Ctrl-C) very early on when executing `vagrant` no
    longer results in an ugly stack trace.
  - Chef JSON configuration output is now pretty-printed to be
    human readable. [GH-1146]
    that SSHing succeeds when booting a machine.
  - VMs in the "guru meditation" state can be destroyed now using
    `vagrant destroy`.
  - Fix issue where changing SSH key permissions didn't properly work. [GH-911]
  - Fix issue where Vagrant didn't properly detect VBoxManage on Windows
    if VBOX_INSTALL_PATH contained multiple paths. [GH-885]
  - Fix typo in setting host name for Gentoo guests. [GH-931]
  - Files that are included with `vagrant package --include` now properly
    preserve file attributes on earlier versions of Ruby. [GH-951]
  - Multiple interfaces now work with Arch linux guests. [GH-957]
  - Fix issue where subprocess execution would always spin CPU of Ruby
    process to 100%. [GH-832]
  - Fix issue where shell provisioner would sometimes never end. [GH-968]
  - Fix issue where puppet would reorder module paths. [GH-964]
  - When console input is asked for (destroying a VM, bridged interfaces, etc.),
    keystrokes such as ctrl-D and ctrl-C are more gracefully handled. [GH-1017]
  - Fixed bug where port check would use "localhost" on systems where
    "localhost" is not available. [GH-1057]
  - Add missing translation for "saving" state on VirtualBox. [GH-1110]
  - Proper error message if the remote end unexpectedly resets the connection
    while downloading a box over HTTP. [GH-1090]
  - Human-friendly error is raised if there are permission issues when
    using SCP to upload files. [GH-924]
  - Box adding doesn't use `/tmp` anymore which can avoid some cross-device
    copy issues. [GH-1199]
  - Vagrant works properly in folders with strange characters. [GH-1223]
  - Vagrant properly handles "paused" VirtualBox machines. [GH-1184]
  - Better behavior around permissions issues when copying insecure
    private key. [GH-580]

## 1.0.7 (March 13, 2013)

  - Detect if a newer version of Vagrant ran and error if it did,
    because we're not forward-compatible.
  - Check for guest additions version AFTER booting. [GH-1179]
  - Quote IdentityFile in `ssh-config` so private keys with spaces in
    the path work. [GH-1322]
  - Fix issue where multiple Puppet module paths can be re-ordered [GH-964]
  - Shell provisioner won't hang on Windows anymore due to unclosed
    tempfile. [GH-1040]
  - Retry setting default VM name, since it sometimes fails first time. [GH-1368]
  - Support setting hostname on Suse [GH-1063]

## 1.0.6 (December 21, 2012)

  - Shell provisioner outputs proper line endings on Windows [GH-1164]
  - SSH upload opens file to stream which fixes strange upload issues.
  - Check for proper exit codes for Puppet, since multiple exit codes
    can mean success. [GH-1180]
  - Fix issue where DNS doesn't resolve properly for 12.10. [GH-1176]
  - Allow hostname to be a substring of the box name for Ubuntu [GH-1163]
  - Use `puppet agent` instead of `puppetd` to be Puppet 3.x
    compatible. [GH-1169]
  - Work around bug in VirtualBox exposed by bug in OS X 10.8 where
    VirtualBox executables couldn't handle garbage being injected into
    stdout by OS X.

## 1.0.5 (September 18, 2012)

  - Work around a critical bug in VirtualBox 4.2.0 on Windows that
    causes Vagrant to not work. [GH-1130]
  - Plugin loading works better on Windows by using the proper
    file path separator.
  - NFS works on Fedora 16+. [GH-1140]
  - NFS works with newer versions of Arch hosts that use systemd. [GH-1142]

## 1.0.4 (September 13, 2012)

  - VirtualBox 4.2 driver. [GH-1120]
  - Correct `ssh-config` help to use `--host`, not `-h`.
  - Use "127.0.0.1" instead of "localhost" for port checking to fix problem
    where "localhost" is not properly setup. [GH-1057]
  - Disable read timeout on Net::HTTP to avoid `rbuf_fill` error. [GH-1072]
  - Retry SSH on `EHOSTUNREACH` errors.
  - Add missing translation for "saving" state. [GH-1110]

## 1.0.3 (May 1, 2012)

  - Don't enable NAT DNS proxy on machines where resolv.conf already points
    to localhost. This allows Vagrant to work once again with Ubuntu
    12.04. [GH-909]

## 1.0.2 (March 25, 2012)

  - Provisioners will still mount folders and such if `--no-provision` is
    used, so that `vagrant provision` works. [GH-803]
  - Nicer error message if an unsupported SSH key type is used. [GH-805]
  - Gentoo guests can now have their host names changed. [GH-796]
  - Relative paths can be used for the `config.ssh.private_key_path`
    setting. [GH-808]
  - `vagrant ssh` now works on Solaris, where `IdentitiesOnly` was not
    an available option. [GH-820]
  - Output works properly in the face of broken pipes. [GH-819]
  - Enable Host IO Cache on the SATA controller by default.
  - Chef-solo provisioner now supports encrypted data bags. [GH-816]
  - Enable the NAT DNS proxy by default, allowing your DNS to continue
    working when you switch networks. [GH-834]
  - Checking for port forwarding collisions also checks for other applications
    that are potentially listening on that port as well. [GH-821]
  - Multiple VM names can be specified for the various commands now. For
    example: `vagrant up web db service`. [GH-795]
  - More robust error handling if a VM fails to boot. The error message
    is much clearer now. [GH-825]

## 1.0.1 (March 11, 2012)

  - Installers are now bundled with Ruby 1.9.3p125. Previously they were
    bundled with 1.9.3p0. This actually fixes some IO issues with Windows.
  - Windows installer now outputs a `vagrant` binary that will work in msys
    or Cygwin environments.
  - Fix crashing issue which manifested itself in multi-VM environments.
  - Add missing `rubygems` require in `environment.rb` to avoid
    possible load errors. [GH-781]
  - `vagrant destroy` shows a nice error when called without a
    TTY (and hence can't confirm). [GH-779]
  - Fix an issue with the `:vagrantfile_name` option to `Vagrant::Environment`
    not working properly. [GH-778]
  - `VAGRANT_CWD` environmental variable can be used to set the CWD to
    something other than the current directory.
  - Downloading boxes from servers that don't send a content-length
    now works properly. [GH-788]
  - The `:facter` option now works for puppet server. [GH-790]
  - The `--no-provision` and `--provision-with` flags are available to
    `vagrant reload` now.
  - `:openbsd` guest which supports only halting at the moment. [GH-773]
  - `ssh-config -h` now shows help, instead of assuming a host is being
    specified. For host, you can still use `--host`. [GH-793]

## 1.0.0 (March 6, 2012)

  - `vagrant gem` should now be used to install Vagrant plugins that are
    gems. This installs the gems to a private gem folder that Vagrant adds
    to its own load path. This isolates Vagrant-related gems from system
    gems.
  - Plugin loading no longer happens right when Vagrant is loaded, but when
    a Vagrant environment is loaded. I don't anticipate this causing any
    problems but it is a backwards incompatible change should a plugin
    depend on this (but I don't see any reason why they would).
  - `vagrant destroy` now asks for confirmation by default. This can be
    overridden with the `--force` flag. [GH-699]
  - Fix issue with Puppet config inheritance. [GH-722]
  - Fix issue where starting a VM on some systems was incorrectly treated
    as failing. [GH-720]
  - It is now an error to specify the packaging `output` as a directory. [GH-730]
  - Unix-style line endings are used properly for guest OS. [GH-727]
  - Retry certain VirtualBox operations, since they intermittently fail.
    [GH-726]
  - Fix issue where Vagrant would sometimes "lose" a VM if an exception
    occurred. [GH-725]
  - `vagrant destroy` destroys virtual machines in reverse order. [GH-739]
  - Add an `fsid` option to Linux NFS exports. [GH-736]
  - Fix edge case where an exception could be raised in networking code. [GH-742]
  - Add missing translation for the "guru meditation" state. [GH-745]
  - Check that VirtualBox exists before certain commands. [GH-746]
  - NIC type can be defined for host-only network adapters. [GH-750]
  - Fix issue where re-running chef-client would sometimes cause
    problems due to file permissions. [GH-748]
  - FreeBSD guests can now have their hostnames changed. [GH-757]
  - FreeBSD guests now support host only networking and bridged networking. [GH-762]
  - `VM#run_action` is now public so plugin-devs can hook into it.
  - Fix crashing bug when attempting to run commands on the "primary"
    VM in a multi-VM environment. [GH-761]
  - With puppet you can now specify `:facter` as a dictionary of facts to
    override what is generated by Puppet. [GH-753]
  - Automatically convert all arguments to `customize` to strings.
  - openSUSE host system. [GH-766]
  - Fix subprocess IO deadlock which would occur on Windows. [GH-765]
  - Fedora 16 guest support. [GH-772]

## 0.9.7 (February 9, 2012)

  - Fix regression where all subprocess IO simply didn't work with
    Windows. [GH-721]

## 0.9.6 (February 7, 2012)

  - Fix strange issue with inconsistent childprocess reads on JRuby. [GH-711]
  - `vagrant ssh` does a direct `exec()` syscall now instead of going through
    the shell. This makes it so things like shell expansion oddities no longer
    cause problems. [GH-715]
  - Fix crashing case if there are no ports to forward.
  - Fix issue surrounding improper configuration of host only networks on
    RedHat guests. [GH-719]
  - NFS should work properly on Gentoo. [GH-706]

## 0.9.5 (February 5, 2012)

  - Fix crashing case when all network options are `:auto_config false`.
    [GH-689]
  - Type of network adapter can be specified with `:nic_type`. [GH-690]
  - The NFS version can be specified with the `:nfs_version` option
    on shared folders. [GH-557]
  - Greatly improved FreeBSD guest and host support. [GH-695]
  - Fix instability with RedHat guests and host only and bridged networks.
    [GH-698]
  - When using bridged networking, only list the network interfaces
    that are up as choices. [GH-701]
  - More intelligent handling of the `certname` option for puppet
    server. [GH-702]
  - You may now explicitly set the network to bridge to in the Vagrantfile
    using the `:bridge` parameter. [GH-655]

## 0.9.4 (January 28, 2012)

  - Important internal changes to middlewares that make plugin developer's
    lives much easier. [GH-684]
  - Match VM names that have parens, brackets, etc.
  - Detect when the VirtualBox kernel module is not loaded and error. [GH-677]
  - Set `:auto_config` to false on any networking option to not automatically
    configure it on the guest. [GH-663]
  - NFS shared folder guest paths can now contain shell expansion characters
    such as `~`.
  - NFS shared folders with a `:create` flag will have their host folders
    properly created if they don't exist. [GH-667]
  - Fix the precedence for Arch, Ubuntu, and FreeBSD host classes so
    they are properly detected. [GH-683]
  - Fix issue where VM import sometimes made strange VirtualBox folder
    layouts. [GH-669]
  - Call proper `id` command on Solaris. [GH-679]
  - More accurate VBoxManage error detection.
  - Shared folders can now be marked as transient using the `:transient`
    flag. [GH-688]

## 0.9.3 (January 24, 2012)

  - Proper error handling for not enough arguments to `box` commands.
  - Fix issue causing crashes with bridged networking. [GH-673]
  - Ignore host only network interfaces that are "down." [GH-675]
  - Use "printf" instead of "echo" to determine shell expanded files paths
    which is more generally POSIX compliant. [GH-676]

## 0.9.2 (January 20, 2012)

  - Support shell expansions in shared folder guest paths again. [GH-656]
  - Fix issue where Chef solo always expected the host to have a
    "cookbooks" folder in their directory. [GH-638]
  - Fix `forward_agent` not working when outside of blocks. [GH-651]
  - Fix issue causing custom guest implementations to not load properly.
  - Filter clear screen character out of output on SSH.
  - Log output now goes on `stderr`, since it is utility information.
  - Get rid of case where a `NoMethodError` could be raised while
    determining VirtualBox version. [GH-658]
  - Debian/Ubuntu uses `ifdown` again, instead of `ifconfig xxx down`, since
    the behavior seems different/wrong.
  - Give a nice error if `:vagrant` is used as a JSON key, since Vagrant
    uses this. [GH-661]
  - If there is only one bridgable interface, use that without asking
    the user. [GH-655]
  - The shell will have color output if ANSICON is installed on Windows. [GH-666]

## 0.9.1 (January 18, 2012)

  - Use `ifconfig device down` instead of `ifdown`. [GH-649]
  - Clearer invalid log level error. [GH-645]
  - Fix exception raised with NFS `recover` method.
  - Fix `ui` `NoMethodError` exception in puppet server.
  - Fix `vagrant box help` on Ruby 1.8.7. [GH-647]

## 0.9.0 (January 17, 2012)

  - VirtualBox 4.0 support backported in addition to supporting VirtualBox 4.1.
  - `config.vm.network` syntax changed so that the first argument is now the type
    of argument. Previously where you had `config.vm.network "33.33.33.10"` you
    should now put `config.vm.network :hostonly, "33.33.33.10"`. This is in order
    to support bridged networking, as well.
  - `config.vm.forward_port` no longer requires a name parameter.
  - Bridged networking. `config.vm.network` with `:bridged` as the option will
    setup a bridged network.
  - Host only networks can be configured with DHCP now. Specify `:dhcp` as
    the IP and it will be done.
  - `config.vm.customize` now takes a command to send to `VBoxManage`, so any
    arbitrary command can be sent. The older style of passing a block no longer
    works and Vagrant will give a proper error message if it notices this old-style
    being used.
  - `config.ssh.forwarded_port_key` is gone. Vagrant no longer cares about
    forwarded port names for any reason. Please use `config.ssh.guest_port`
    (more below).
  - `config.ssh.forwarded_port_destination` has been replaced by
    `config.ssh.guest_port` which more accurately reflects what it is
    used for. Vagrant will automatically scan forwarded ports that match the
    guest port to find the SSH port.
  - Logging. The entire Vagrant source has had logging sprinkled throughout
    to make debugging issues easier. To enable logging, set the VAGRANT_LOG
    environmental variable to the log level you wish to see. By default,
    logging is silent.
  - `system` renamed to `guest` throughout the source. Any `config.vm.system`
    configurations must be changed to `config.vm.guest`
  - Puppet provisioner no longer defaults manifest to "box.pp." Instead, it
    is now "default.pp"
  - All Vagrant commands that take a VM name in a Multi-VM environment
    can now be given a regular expression. If the name starts and ends with a "/"
    then it is assumed to be a regular expression. [GH-573]
  - Added a "--plain" flag to `vagrant ssh` which will cause Vagrant to not
    perform any authentication. It will simply `ssh` into the proper IP and
    port of the virtual machine.
  - If a shared folder now has a `:create` flag set to `true`, the path on the
    host will be created if it doesn't exist.
  - Added `--force` flag to `box add`, which will overwite any existing boxes
    if they exist. [GH-631]
  - Added `--provision-with` to `up` which configures what provisioners run,
    by shortcut. [GH-367]
  - Arbitrary mount options can be passed with `:extra` to any shared
    folders. [GH-551]
  - Options passed after a `--` to `vagrant ssh` are now passed directly to
    `ssh`. [GH-554]
  - Ubuntu guests will now emit a `vagrant-mounted` upstart event after shared
    folders are mounted.
  - `attempts` is a new option on chef client and chef solo provisioners. This
    will run the provisioner multiple times until erroring about failing
    convergence. [GH-282]
  - Removed Thor as a dependency for the command line interfaces. This resulted
    in general speed increases across all command line commands.
  - Linux uses `shutdown -h` instead of `halt` to hopefully more consistently
    power off the system. [GH-575]
  - Tweaks to SSH to hopefully be more reliable in coming up.
  - Helpful error message when SCP is unavailable in the guest. [GH-568]
  - Error message for improperly packaged box files. [GH-198]
  - Copy insecure private key to user-owned directory so even
    `sudo` installed Vagrant installations work. [GH-580]
  - Provisioner stdout/stderr is now color coded based on stdout/stderr.
    stdout is green, stderr is red. [GH-595]
  - Chef solo now prompts users to run a `reload` if shared folders
    are not found on the VM. [GH-253]
  - "--no-provision" once again works for certain commands. [GH-591]
  - Resuming a VM from a saved state will show an error message if there
    would be port collisions. [GH-602]
  - `vagrant ssh -c` will now exit with the same exit code as the command
    run. [GH-598]
  - `vagrant ssh -c` will now send stderr to stderr and stdout to stdout
    on the host machine, instead of all output to stdout.
  - `vagrant box add` path now accepts unexpanded shell paths such as
    `~/foo` and will properly expand them. [GH-633]
  - Vagrant can now be interrupted during the "importing" step.
  - NFS exports will no longer be cleared when an expected error occurs. [GH-577]

## 0.8.10 (December 10, 2011)

  - Revert the SSH tweaks made in 0.8.8. It affected stability

## 0.8.8 (December 1, 2011)

  - Mount shared folders shortest to longest to avoid mounting
    subfolders first. [GH-525]
  - Support for basic HTTP auth in the URL for boxes.
  - Solaris support for host only networks. [GH-533]
  - `vagrant init` respects `Vagrant::Environment` cwd. [GH-528]
  - `vagrant` commands will not output color when stdout is
    not a TTY.
  - Fix issue where `box_url` set with multiple VMs could cause issues. [GH-564]
  - Chef provisioners no longer depend on a "v-root" share being
    available. [GH-556]
  - NFS should work for FreeBSD hosts now. [GH-510]
  - SSH executed methods respect `config.ssh.max_tries`. [GH-508]
  - `vagrant box add` now respects the "no_proxy" environmental variable.
    [GH-502]
  - Tweaks that should make "Waiting for VM to boot" slightly more
    reliable.
  - Add comments to Vagrantfile to make it detected as Ruby file for
    `vi` and `emacs`. [GH-515]
  - More correct guest addition version checking. [GH-514]
  - Chef solo support on Windows is improved. [GH-542]
  - Put encrypted data bag secret into `/tmp` by default so that
    permissions are almost certainly guaranteed. [GH-512]

## 0.8.7 (September 13, 2011)

  - Fix regression with remote paths from chef-solo. [GH-431]
  - Fix issue where Vagrant crashes if `.vagrant` file becomes invalid. [GH-496]
  - Issue a warning instead of an error for attempting to forward a port
    <= 1024. [GH-487]

## 0.8.6 (August 28, 2011)

  - Fix issue with download progress not properly clearing the line. [GH-476]
  - NFS should work properly on Fedora. [GH-450]
  - Arguments can be specified to the `shell` provisioner via the `args` option. [GH-475]
  - Vagrant behaves much better when there are "inaccessible" VMs. [GH-453]

## 0.8.5 (August 15, 2011)

Note: 0.8.3 and 0.8.4 was yanked due to RubyGems encoding issue.

 - Fix SSH `exec!` to inherit proper `$PATH`. [GH-426]
 - Chef client now accepts an empty (`nil`) run list again. [GH-429]
 - Fix incorrect error message when running `provision` on halted VM. [GH-447]
 - Checking guest addition versions now ignores OSE. [GH-438]
 - Chef solo from a remote URL fixed. [GH-431]
 - Arch linux support: host only networks and changing the host name. [GH-439] [GH-448]
 - Chef solo `roles_path` and `data_bags_path` can only be be single paths. [GH-446]
 - Fix `virtualbox_not_detected` error message to require 4.1.x. [GH-458]
 - Add shortname (`hostname -s`) for hostname setting on RHEL systems. [GH-456]
 - `vagrant ssh -c` output no longer has a prefix and respects newlines
   from the output. [GH-462]

## 0.8.2 (July 22, 2011)

  - Fix issue with SSH disconnects not reconnecting.
  - Fix chef solo simply not working with roles/data bags. [GH-425]
  - Multiple chef solo provisioners now work together.
  - Update Puppet provisioner so no deprecation warning is shown. [GH-421]
  - Removed error on "provisioner=" in config, as this has not existed
    for some time now.
  - Add better validation for networking.

## 0.8.1 (July 20, 2011)

  - Repush of 0.8.0 to fix a Ruby 1.9.2 RubyGems issue.

## 0.8.0 (July 20, 2011)

  - VirtualBox 4.1 support _only_. Previous versions of VirtualBox
    are supported by earlier versions of Vagrant.
  - Performance optimizations in `virtualbox` gem. Huge speed gains.
  - `:chef_server` provisioner is now `:chef_client`. [GH-359]
  - SSH connection is now cached after first access internally,
    speeding up `vagrant up`, `reload`, etc. quite a bit.
  - Actions which modify the VM now occur much more quickly,
    greatly speeding up `vagrant up`, `reload`, etc.
  - SUSE host only networking support. [GH-369]
  - Show nice error message for invalid HTTP responses for HTTP
    downloader. [GH-403]
  - New `:inline` option for shell provisioner to provide inline
    scripts as a string. [GH-395]
  - Host only network now properly works on multiple adapters. [GH-365]
  - Can now specify owner/group for regular shared folders. [GH-350]
  - `ssh_config` host name will use VM name if given. [GH-332]
  - `ssh` `-e` flag changed to `-c` to align with `ssh` standard
    behavior. [GH-323]
  - Forward agent and forward X11 settings properly appear in
    `ssh_config` output. [GH-105]
  - Chef JSON can now be set with `chef.json =` instead of the old
    `merge` technique. [GH-314]
  - Provisioner configuration is no longer cleared when the box
    needs to be downloaded during an `up`. [GH-308]
  - Multiple Chef provisioners no longer overwrite cookbook folders. [GH-407]
  - `package` won't delete previously existing file. [GH-408]
  - Vagrantfile can be lowercase now. [GH-399]
  - Only one copy of Vagrant may be running at any given time. [GH-364]
  - Default home directory for Vagrant moved to `~/.vagrant.d` [GH-333]
  - Specify a `forwarded_port_destination` for SSH configuration and
    SSH port searching will fall back to that if it can't find any
    other port. [GH-375]

## 0.7.8 (July 19, 2011)

  - Make sure VirtualBox version check verifies that it is 4.0.x.

## 0.7.7 (July 12, 2011)

  - Fix crashing bug with Psych and Ruby 1.9.2. [GH-411]

## 0.7.6 (July 2, 2011)

  - Run Chef commands in a single command. [GH-390]
  - Add `nfs` option for Chef to mount Chef folders via NFS. [GH-378]
  - Add translation for `aborted` state in VM. [GH-371]
  - Use full paths with the Chef provisioner so that restart cookbook will
    work. [GH-374]
  - Add "--no-color" as an argument and no colorized output will be used. [GH-379]
  - Added DEVICE option to the RedHat host only networking entry, which allows
    host only networking to work even if the VM has multiple NICs. [GH-382]
  - Touch the network configuration file for RedHat so that the `sed` works
    with host only networking. [GH-381]
  - Load prerelease versions of plugins if available.
  - Do not load a plugin if it depends on an invalid version of Vagrant.
  - Encrypted data bag support in Chef server provisioner. [GH-398]
  - Use the `-H` flag to set the proper home directory for `sudo`. [GH-370]

## 0.7.5 (May 16, 2011)

  - `config.ssh.port` can be specified and takes highest precedence if specified.
    Otherwise, Vagrant will still attempt to auto-detect the port. [GH-363]
  - Get rid of RubyGems deprecations introduced with RubyGems 1.8.x
  - Search in pre-release gems for plugins as well as release gems.
  - Support for Chef-solo `data_bags_path` [GH-362]
  - Can specify path to Chef binary using `binary_path` [GH-342]
  - Can specify additional environment data for Chef using `binary_env` [GH-342]

## 0.7.4 (May 12, 2011)

  - Chef environments support (for Chef 0.10) [GH-358]
  - Suppress the "added to known hosts" message for SSH [GH-354]
  - Ruby 1.8.6 support [GH-352]
  - Chef proxy settings now work for chef server [GH-335]

## 0.7.3 (April 19, 2011)

  - Retry all SSH on Net::SSH::Disconnect in case SSH is just restarting. [GH-313]
  - Add NFS shared folder support for Arch linux. [GH-346]
  - Fix issue with unknown terminal type output for sudo commands.
  - Forwarded port protocol can now be set as UDP. [GH-311]
  - Chef server file cache path and file backup path can be configured. [GH-310]
  - Setting hostname should work on Debian now. [GH-307]

## 0.7.2 (February 8, 2011)

  - Update JSON dependency to 1.5.1, which works with Ruby 1.9 on
    Windows.
  - Fix sudo issues on sudo < 1.7.0 (again).
  - Fix race condition in SSH, which specifically manifested itself in
    the chef server provisioner. [GH-295]
  - Change sudo shell to use `bash` (configurable). [GH-301]
  - Can now set mac address of host only network. [GH-294]
  - NFS shared folders with spaces now work properly. [GH-293]
  - Failed SSH commands now show output in error message. [GH-285]

## 0.7.1 (January 28, 2011)

  - Change error output with references to VirtualBox 3.2 to 4.0.
  - Internal SSH through net-ssh now uses `IdentitiesOnly` thanks to
    upstream net-ssh fix.
  - Fix issue causing warnings to show with `forwardx11` enabled for SSH. [GH-279]
  - FreeBSD support for host only networks, NFS, halting, etc. [GH-275]
  - Make SSH commands which use sudo compatible with sudo < 1.7.0. [GH-278]
  - Fix broken puppet server provisioner which called a nonexistent
    method.
  - Default SSH host changed from `localhost` to `127.0.0.1` since
    `localhost` is not always loopback.
  - New `shell` provisioner which simply uploads and executes a script as
    root on the VM.
  - Gentoo host only networking no longer fails if alrady setup. [GH-286]
  - Set the host name of your guest OS with `config.vm.host_name` [GH-273]
  - `vagrant ssh-config` now outputs the configured `config.ssh.host`

## 0.7.0 (January 19, 2011)

  - VirtualBox 4.0 support. Support for VirtualBox 3.2 is _dropped_, since
    the API is so different. Stay with the 0.6.x series if you have VirtualBox
    3.2.x.
  - Puppet server provisioner. [GH-262]
  - Use numeric uid/gid in mounting shared folders to increase portability. [GH-252]
  - HTTP downloading follows redirects. [GH-163]
  - Downloaders have clearer output to note what they're doing.
  - Shared folders with no guest path are not automounted. [GH-184]
  - Boxes downloaded during `vagrant up` reload the Vagrantfile config, which
    fixes a problem with box settings not being properly loaded. [GH-231]
  - `config.ssh.forward_x11` to enable the ForwardX11 SSH option. [GH-255]
  - Vagrant source now has a `contrib` directory where contributions of miscellaneous
    addons for Vagrant will be added.
  - Vagrantfiles are now loaded only once (instead of 4+ times) [GH-238]
  - Ability to move home vagrant dir (~/.vagrant) by setting VAGRANT_HOME
    environmental variable.
  - Removed check and error for the "OSE" version of VirtualBox, since with
    VirtualBox 4 this distinction no longer exists.
  - Ability to specify proxy settings for chef. [GH-169]
  - Helpful error message shown if NFS mounting fails. [GH-135]
  - Gentoo guests now support host only networks. [GH-240]
  - RedHat (CentOS included) guests now support host only networks. [GH-260]
  - New Vagrantfile syntax for enabling and configuring provisioners. This
    change is not backwards compatible. [GH-265]
  - Provisioners are now RVM-friendly, meaning if you installed chef or puppet
    with an RVM managed Ruby, Vagrant now finds then. [GH-254]
  - Changed the unused host only network destroy mechanism to check for
    uselessness after the VM is destroyed. This should result in more accurate
    checks.
  - Networks are no longer disabled upon halt/destroy. With the above
    change, its unnecessary.
  - Puppet supports `module_path` configuration to mount local modules directory
    as a shared folder and configure puppet with it. [GH-270]
  - `ssh-config` now outputs `127.0.0.1` as the host instead of `localhost`.

## 0.6.9 (December 21, 2010)

  - Puppet provisioner. [GH-223]
  - Solaris system configurable to use `sudo`.
  - Solaris system registered, so it can be set with `:solaris`.
  - `vagrant package` include can be a directory name, which will cause the
    contents to be recursively copied into the package. [GH-241]
  - Arbitrary options to puppet binary can be set with `config.puppet.options`. [GH-242]
  - BSD hosts use proper GNU sed syntax for clearing NFS shares. [GH-243]
  - Enumerate VMs in a multi-VM environment in order they were defined. [GH-244]
  - Check for VM boot changed to use `timeout` library, which works better with Windows.
  - Show special error if VirtualBox not detected on 64-bit Windows.
  - Show error to Windows users attempting to use host only networking since
    it doesn't work yet.

## 0.6.8 (November 30, 2010)

  - Network interfaces are now up/down in distinct commands instead of just
    restarting "networking." [GH-192]
  - Add missing translation for chef binary missing. [GH-203]
  - Fix default settings for Opscode platform and comments. [GH-213]
  - Blank client name for chef server now uses FQDN by default, instead of "client" [GH-214]
  - Run list can now be nil, which will cause it to sync with chef server (when
    chef server is enabled). [GH-214]
  - Multiple NFS folders now work on linux. [GH-215]
  - Add translation for state "stuck" which is very rare. [GH-218]
  - virtualbox gem dependency minimum raised to 0.7.6 to verify FFI < 1.0.0 is used.
  - Fix issue where box downloading from `vagrant up` didn't reload the box collection. [GH-229]

## 0.6.7 (November 3, 2010)

  - Added validation to verify that a box is specified.
  - Proper error message when box is not found for `config.vm.box`. [GH-195]
  - Fix output of `vagrant status` with multi-vm to be correct. [GH-196]

## 0.6.6 (October 14, 2010)

  - `vagrant status NAME` works once again. [GH-191]
  - Conditional validation of Vagrantfile so that some commands don't validate. [GH-188]
  - Fix "junk" output for ssh-config. [GH-189]
  - Fix port collision handling with greater than two VMs. [GH-185]
  - Fix potential infinite loop with root path if bad CWD is given to environment.

## 0.6.5 (October 8, 2010)

  - Validations on base MAC address to avoid situation described in GH-166, GH-181
    from ever happening again.
  - Properly load sub-VM configuration on first-pass of config loading. Solves
    a LOT of problems with multi-VM. [GH-166] [GH-181]
  - Configuration now only validates on final Vagrantfile proc, so multi-VM
    validates correctly.
  - A nice error message is given if ".vagrant" is a directory and therefore
    can't be accessed. [GH-172]
  - Fix plugin loading in a Rails 2.3.x project. [GH-176]

## 0.6.4 (October 4, 2010)

  - Default VM name is now properly the parent folder of the working directory
    of the environment.
  - Added method to `TestHelpers` to assist with testing new downloaders.
  - `up --no-provision` works again. This disables provisioning during the
    boot process.
  - Action warden doesn't do recovery process on `SystemExit` exceptions,
    allowing the double ctrl-C to work properly again. [related to GH-166]
  - Initial Vagrantfile is now heavily commented with various available
    options. [GH-171]
  - Box add checks if a box already exists before the download. [GH-170]
  - NFS no longer attempts to clean exports file if VM is not created,
    which was causing a stack trace during recovery. [related to GH-166]
  - Basic validation added for Chef configuration (both solo and server).
  - Top config class is now available in all `Vagrant::Config::Base`
    subclasses, which is useful for config validation.
  - Subcommand help shows proper full command in task listing. [GH-168]
  - SSH gives error message if `ssh` binary is not found. [GH-161]
  - SSH gives proper error message if VM is not running. [GH-167]
  - Fix some issues with undefined constants in command errors.

## 0.6.1, 0.6.2, 0.6.3 (September 27, 2010)

A lot of quick releases which all were to fix issues with Ruby 1.8.7
compatibility.

## 0.6.0 (September 27, 2010)

  - VM name now defaults to the name of the containing folder, plus a timestamp.
    This should make it easier to identify VMs in the VirtualBox GUI.
  - Exposed Vagrant test helpers in `Vagrant::TestHelpers` for plugins to easily
    test themselves against Vagrant environments.
  - **Plugins** have landed. Plugins are simply gems which have a `vagrant_init.rb`
    file somewhere in their load path. Please read the documentation on
    vagrantup.com before attempting to create a plugin (which is very easy)
    for more information on how it all works and also some guidelines.
  - `vagrant package` now takes a `--vagrantfile` option to specify a
    Vagrantfile to package. The `--include` approach for including a Vagrantfile
    no longer works (previously built boxes will continue to work).
  - `vagrant package` has new logic with regards to the `--include` option
    depending on if the file path is relative or absolute (they can be
    intermixed):
      * _Relative_ paths are copied directly into the box, preserving
        their path. So `--include lib/foo` would be in the box as "lib/foo"
      * _Absolute_ paths are simply copied files into the root of the
        box. So `--include /lib/foo` would be in the box as "foo"
  - "vagrant_main" is no longer the default run list. Instead, chef
    run list starts empty. It is up to you to specify all recipes in
    the Vagrantfile now.
  - Fixed various issues with certain action middleware not working if
    the VM was not created.
  - SSH connection is retried 5 times if there is a connection refused.
    Related to GH-140.
  - If `http_proxy` environmental variable is set, it will be used as the proxy
    box adding via http.
  - Remove `config.ssh.password`. It hasn't been used for a few versions
    now and was only kept around to avoid exceptions in Vagrantfiles.
  - Configuration is now validated so improper input can be found in
    Vagrantfiles.
  - Fixed issue with not detecting Vagrantfile at root directory ("/").
  - Vagrant now gives a nice error message if there is a syntax error
    in any Vagrantfile. [GH-154]
  - The format of the ".vagrant" file which stores persisted VMs has
    changed. This is **backwards incompatible**. Will provide an upgrade
    utility prior to 0.6 launch.
  - Every [expected] Vagrant error now exits with a clean error message
    and a unique exit status, and raises a unique exception (if you're
    scripting Vagrant).
  - Added I18n gem dependency for pulling strings into clean YML files.
    Vagrant is now localizable as a side effect! Translations welcome.
  - Fixed issue with "Waiting for cleanup" message appearing twice in
    some cases. [GH-145]
  - Converted CLI to use Thor. As a tradeoff, there are some backwards
    incompatibilities:
      * `vagrant package` - The `--include` flag now separates filenames
        by spaces, instead of by commas. e.g. `vagrant package --include x y z`
      * `vagrant ssh` - If you specify a command to execute using the `--execute`
        flag, you may now only specify one command (before you were able to
        specify an arbitrary amount). e.g. `vagrant ssh -e "echo hello"`
      * `vagrant ssh-config` has become `vagrant ssh_config` due to a limitation
        in Thor.

## 0.5.4 (September 7, 2010)

  - Fix issue with the "exec failed" by running on Tiger as well.
  - Give an error when downloading a box which already exists prior
    to actually downloading the box.

## 0.5.3 (August 23, 2010)

  - Add erubis as a dependency since its rendering of `erb` is sane.
  - Fixed poorly formatted Vagrantfile after `vagrant init`. [GH-142]
  - Fixed NFS not working properly with multiple NFS folders.
  - Fixed chef solo provision to work on Windows. It was expanding a linux
    path which prepended a drive letter onto it.

## 0.5.2 (August 3, 2010)

  - `vagrant up` can be used as a way to resume the VM as well (same as
    `vagrant resume`). [GH-134]
  - Sudo uses "-E" flag to preserve environment for chef provisioners.
    This fixes issues with CentOS. [GH-133]
  - Added "IdentitiesOnly yes" to options when `vagrant ssh` is run to
    avoid "Too Many Authentication Failures" error. [GH-131]
  - Fix regression with `package` not working. [GH-132]
  - Added ability to specify box url in `init`, which populates the
    Vagrantfile with the proper `config.vm.box_url`.

## 0.5.1 (July 31, 2010)

  - Allow specifying cookbook paths which exist only on the VM in `config.chef.cookbooks_path`.
    This is used for specifying cookbook paths when `config.chef.recipe_url` is used. [GH-130]
    See updated chef solo documentation for more information on this.
  - No longer show "Disabling host only networks..." if no host only networks
    are destroyed. Quiets `destroy`, `halt`, etc output a bit.
  - Updated getting started guide to be more up to date and generic. [GH-125]
  - Fixed error with doing a `vagrant up` when no Vagrantfile existed. [GH-128]
  - Fixed NFS erroring when NFS wasn't even enabled if `/etc/exports` doesn't
    exist. [GH-126]
  - Fixed `vagrant resume` to properly resume a suspended VM. [GH-122]
  - Fixed `halt`, `destroy`, `reload` to where they failed if the VM was
    in a saved state. [GH-123]
  - Added `config.chef.recipe_url` which allows you to specify a URL to
    a gzipped tar file for chef solo to download cookbooks. See the
    [chef-solo docs](http://wiki.opscode.com/display/chef/Chef+Solo#ChefSolo-RunningfromaURL) for more information.
    [GH-121]
  - Added `vagrant box repackage` which repackages boxes which have
    been added. This is useful in case you want to redistribute a base
    box you have but may have lost the actual "box" file. [GH-120]

## Previous

The changelog began with version 0.5.1 so any changes prior to that
can be seen by checking the tagged releases and reading git commit
messages.

