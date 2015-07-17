## 1.7.4 (July 17, 2015)

BUG FIXES:

  - communicators/winrm: catch timeout errors [GH-5971]
  - guests/fedora: networks can be configured without nmcli [GH-5931]
  - guests/redhat: systemd detection should happen on guest [GH-5948]
  - guests/ubuntu: setting hostname fixed in 12.04 [GH-5937]
  - hosts/linux: NFS can be configured without `$TMP` set on the host [GH-5954]
  - hosts/linux: NFS will sudo copying back to `/etc/exports` [GH-5957]
  - providers/docker: Add `pull` setting, default to false [GH-5932]
  - providers/virtualbox: remove UNC path conversion on Windows since it
      caused mounting regressions [GH-5933]
  - provisioners/puppet: Windows Puppet 4 paths work correctly [GH-5967]
  - provisioners/puppet: Fix config merging errors [GH-5958]
  - provisioners/salt: fix "dummy config" error on bootstrap [GH-5936]

## 1.7.3 (July 10, 2015)

FEATURES:

  - **New guest: `atomic`* - Project Atomic is supported as a guest
  - providers/virtualbox: add support for 5.0 [GH-5647]

IMPROVEMENTS:

  - core: add password authentication to rdp_info hash [GH-4726]
  - core: improve error message when packaging fails [GH-5399]
  - core: improve message when adding a box from a file path [GH-5395]
  - core: add support for network gateways [GH-5721]
  - core: allow redirecting stdout and stderr in the UI [GH-5433]
  - core: update version of winrm-fs to 0.2.0 [GH-5738]
  - core: add option to enabled trusted http(s) redirects [GH-4422]
  - core: capture additional information such as line numbers during
    Vagrantfile loading [GH-4711, GH-5769]
  - core: add .color? to UI objects to see if they support color [GH-5771]
  - core: ignore hidden directories when searching for boxes [GH-5748, GH-5785]
  - core: use `config.ssh.sudo_command` to customize the sudo command
      format [GH-5573]
  - core: add `Vagrant.original_env` for Vagrant and plugins to restore or
      inspect the original environment when Vagrant is being run from the
      installer [GH-5910]
  - guests/darwin: support inserting generated key [GH-5204]
  - guests/darwin: support mounting SMB shares [GH-5750]
  - guests/fedora: support Fedora 21 [GH-5277]
  - guests/fedora: add capabilities for nfs and flavor [GH-5770, GH-4847]
  - guests/linux: specify user's domain as separate parameter [GH-3620, GH-5512]
  - guests/redhat: support Scientific Linux 7 [GH-5303]
  - guests/photon: initial support [GH-5612]
  - guests/solaris,solaris11: support inserting generated key [GH-5182]
      [GH-5290]
  - providers/docker: images are pulled prior to starting [GH-5249]
  - provisioners/ansible: store the first ssh private key in the auto-generated inventory [GH-5765]
  - provisioners/chef: add capability for checking if Chef is installed on Windows [GH-5669]
  - provisioners/docker: restart containers if arguments have changed [GH-3055, GH-5924]
  - provisioners/puppet: add support for Puppet 4 and configuration options [GH-5601]
  - provisioners/puppet: add support for `synced_folder_args` in apply [GH-5359]
  - provisioners/salt: add configurable `config_dir` [GH-3138]
  - provisioners/salt: add support for masterless configuration [GH-3235]
  - provisioners/salt: provider path to missing file in errors [GH-5637]
  - provisioners/salt: add ability to run salt orchestrations [GH-4371]
  - provisioners/salt: update to 2015.5.2 [GH-4152, GH-5437]
  - provisioners/salt: support specifying version to install [GH-5892]
  - provisioners/shell: add :name attribute to shell provisioner [GH-5607]
  - providers/docker: supports file downloads with the file provisioner [GH-5651]
  - providers/docker: support named Dockerfile [GH-5480]
  - providers/docker: don't remove image on reload so that build cache can
      be used fully [GH-5905]
  - providers/hyperv: select a Hyper-V switch based on a `network_name` [GH-5207]
  - providers/hyperv: allow configuring VladID [GH-5539]
  - providers/virtualbox: regexp supported for bridge configuration [GH-5320]
  - providers/virtualbox: handle a list of bridged NICs [GH-5691]
  - synced_folders/rsync: allow showing rsync output in debug mode [GH-4867]
  - synced_folders/rsync: set `rsync__rsync_path` to specify the remote
      command used to execute rsync [GH-3966]

BUG FIXES:

  - core: push configurations are validated with global configs [GH-5130]
  - core: remove executable permissions on internal file [GH-5220]
  - core: check name and version in `has_plugin?` [GH-5218]
  - core: do not create duplicates when defining two private network addresses [GH-5325]
  - core: update ssh to check for Plink [GH-5604]
  - core: do not report plugins as installed when plugins are disabled [GH-5698, GH-5430]
  - core: Only take files when packaging a box to avoid duplicates [GH-5658, GH-5657]
  - core: escape curl urls and authentication [GH-5677]
  - core: fix crash if a value is missing for CLI arguments [GH-5550]
  - core: retry SSH key generation for transient RSA errors [GH-5056]
  - core: `ssh.private_key_path` will override the insecure key [GH-5632]
  - core: restore the original environment when shelling out to subprocesses
      outside of the installer [GH-5912]
  - core/cli: fix box checksum validation [GH-4665, GH-5221]
  - core/windows: allow Windows UNC paths to allow more than 256
      characters [GH-4815]
  - command/rsync-auto: don't crash if rsync command fails [GH-4991]
  - communicators/winrm: improve error handling significantly and improve
      the error messages shown to be more human-friendly. [GH-4943]
  - communicators/winrm: remove plaintext passwords from files after
      provisioner is complete [GH-5818]
  - hosts/nfs: allow colons (`:`) in NFS IDs [GH-5222]
  - guests/darwin: remove dots from LocalHostName [GH-5558]
  - guests/debian: Halt works properly on Debian 8. [GH-5369]
  - guests/fedora: recognize future fedora releases [GH-5730]
  - guests/fedora: reload iface connection by NetworkManager [GH-5709]
  - guests/fedora: do not use biosdevname if it is not installed [GH-5707]
  - guests/freebsd: provide an argument to the backup file [GH-5516, GH-5517]
  - guests/funtoo: fix incorrect path in configure networks [GH-4812]
  - guests/linux: fix edge case exception where no home directory
      is available on guest [GH-5846]
  - guests/linux: copy NFS exports to tmpdir to do edits to guarantee
      permissions are available [GH-5773]
  - guests/openbsd: output newline after inserted public key [GH-5881]
  - guests/tinycore: fix change hostname functionality [GH-5623]
  - guests/ubuntu: use `hostnamectl` to set hostname on Ubuntu Vivid [GH-5753]
  - guests/windows: Create rsync folder prior to rsync-ing. [GH-5282]
  - guests/windows: Changing hostname requires reboot again since
      the non-reboot code path was crashing Windows server. [GH-5261]
  - guests/windows: ignore virtual NICs [GH-5478]
  - hosts/windows: More accurately get host IP address in VPNs. [GH-5349]
  - plugins/login: allow users to login with a token [GH-5145]
  - providers/docker: Build image from `/var/lib/docker` for more disk
      space on some systems. [GH-5302]
  - providers/docker: Fix crash that could occur in some scenarios when
      the host VM path changed.
  - providers/docker: Fix crash that could occur on container destroy
      with VirtualBox shared folders [GH-5143]
  - providers/hyperv: allow users to configure memory, cpu count, and vmname [GH-5183]
  - providers/hyperv: import respects secure boot. [GH-5209]
  - providers/hyperv: only set EFI secure boot for gen 2 machines [GH-5538]
  - providers/virtualbox: read netmask from dhcpservers [GH-5233]
  - providers/virtualbox: Fix exception when VirtualBox version is empty. [GH-5308]
  - providers/virtualbox: Fix exception when VBoxManage.exe can't be run
      on Windows [GH-1483]
  - providers/virtualbox: Error if another user is running after a VM is
      created to avoid issue with VirtualBox "losing" the VM [GH-5895]
  - providers/virtualbox: The "name" setting on private networks will
      choose an existing hostonly network [GH-5389]
  - provisioners/ansible: fix SSH settings to support more than 5 ssh keys [GH-5017]
  - provisioners/ansible: increase ansible connection timeout to 30 seconds [GH-5018]
  - provisioners/ansible: disable color if Vagrant is not colored [GH-5531, GH-5532]
  - provisioners/ansible: only show ansible-playbook command when `verbose` option is enabled [GH-5803]
  - provisioners/ansible: fix a race condition in the inventory file generation [GH-5551]
  - provisioners/docker: use `service` to restart Docker instad of upstart [GH-5245, GH-5577]
  - provisioners/docker: Only add docker user to group if exists. [GH-5315]
  - provisioners/docker: Use https for repo [GH-5749]
  - provisioners/docker: `apt-get update` before installing linux kernel
      images to get the correct version [GH-5860]
  - provisioners/chef: Fix shared folders missing error [GH-5199]
  - provisioners/chef: Use `command -v` to check for binary instead of
      `which` since that doesn't exist on some systems. [GH-5170]
  - provisioners/chef-zero: support more chef-zero/local mode attributes [GH-5339]
  - provisioners/chef: use windows-specific paths in Chef provisioners [GH-5913]
  - provisioners/docker: use docker.com instead of docker.io [GH-5216]
  - provisioners/docker: use `--restart` instead of `-r` on daemon [GH-4477]
  - provisioners/file: validation of source is relative to Vagrantfile [GH-5252]
  - pushes/atlas: send additional box metadata [GH-5283]
  - pushes/local-exec: fix "text file busy" error for inline [GH-5695]
  - pushes/ftp: improve check for remote directory existence [GH-5549]
  - synced\_folders/rsync: add `IdentitiesOnly=yes` to the rsync command. [GH-5175]
  - synced\_folders/smb: use correct `password` option [GH-5805]
  - synced\_folders/smb: prever IPv4 over IPv6 address to mount [GH-5798]
  - virtualbox/config: fix misleading error message for private_network [GH-5536, GH-5418]

## 1.7.2 (January 6, 2015)

BREAKING CHANGES:

  - If you depended on the paths that Chef/Puppet provisioners use to
    store cookbooks (ex. "/tmp/vagrant-chef-1"), these will no longer be
    correct. Without this change, Chef/Puppet didn't work at all with
    `vagrant provision`. We expect this to affect only a minor number of
    people, since it's not something that was ever documented or recommended
    by Vagrant, or even meant to be supported.

FEATURES:

  - provisioners/salt: add support for grains [GH-4895]

IMPROVEMENTS:

  - commands/reload,up: `--provision-with` implies `--provision` [GH-5085]

BUG FIXES:

  - core: private boxes still referencing vagrantcloud.com will have
      their vagrant login access token properly appended
  - core: push plugin configuration is properly validated
  - core: restore box packaging functionality
  - commands/package: fix crash
  - commands/push: push lookups are by user-defined name, not push
      strategy name [GH-4975]
  - commands/push: validate the configuration
  - communicators/winrm: detect parse errors in PowerShell and error
  - guests/arch: fix network configuration due to poor line breaks. [GH-4964]
  - guests/solaris: Merge configurations properly so configs can be set
      in default Vagrantfiles. [GH-5092]
  - installer: SSL cert bundle contains 1024-bit keys, fixing SSL verification
      for a lot of sites.
  - installer: vagrant executable properly `cygpaths` the SSL bundle path
      for Cygwin
  - installer: Nokogiri (XML lib used by Vagrant and dependencies) linker
      dependencies fixed, fixing load issues on some platforms
  - providers/docker: Symlinks in shared folders work. [GH-5093]
  - providers/hyperv: VM start errors turn into proper Vagrant errors. [GH-5101]
  - provisioners/chef: fix missing shared folder error [GH-4988]
  - provisioners/chef: remove Chef version check from solo.rb generation and
      make `roles_path` populate correctly
  - provisioners/chef: fix bad invocation of `with_clean_env` [GH-5021]
  - pushes/atlas: support more verbose logging
  - pushes/ftp: expand file paths relative to the Vagrantfile
  - pushes/ftp: improved debugging output
  - pushes/ftp: create parent directories if they do not exist on the remote
      server

## 1.7.1 (December 11, 2014)

IMPROVEMENTS:

  - provisioners/ansible: Use Docker proxy if needed. [GH-4906]

BUG FIXES:

  - providers/docker: Add support of SSH agent forwarding. [GH-4905]

## 1.7.0 (December 9, 2014)

BREAKING CHANGES:

  - provisioners/ansible: `raw_arguments` has now highest priority
  - provisioners/ansible: only the `ssh` connection transport is supported
      (`paramiko` can be enabled with `raw_arguments` at your own risks)

FEATURES:

  - **Vagrant Push**: Vagrant can now deploy! `vagrant push` is a single
      command to deploy your application. Deploy to Heroku, FTP, or
      HashiCorp's commercial product Atlas. New push strategies can be
      added with plugins.
  - **Named provisioners**: Provisioners can now be named. This name is used
      for output as well as `--provision-with` for better control.
  - Default provider logic improved: Providers in `config.vm.provider` blocks
      in your Vagrantfile now have higher priority than plugins. Earlier
      providers are chosen before later ones. [GH-3812]
  - If the default insecure keypair is used, Vagrant will automatically replace
      it with a randomly generated keypair on first `vagrant up`. [GH-2608]
  - Vagrant Login is now part of Vagrant core
  - Chef Zero provisioner: Use Chef 11's "local" mode to run recipes against an
      in-memory Chef Server
  - Chef Apply provisioner: Specify inline Chef recipes and recipe snippets
      using the Chef Apply provisioner

IMPROVEMENTS:

  - core: `has_plugin?` function now takes a second argument which is a
      version constraint requirement. [GH-4650]
  - core: ".vagrantplugins" file in the same folder as your Vagrantfile
      will be loaded for defining inline plugins. [GH-3775]
  - commands/plugin: Plugin list machine-readable output contains the plugin
      name as the target for versions and other info. [GH-4506]
  - env/with_cleanenv: New helper for plugin developers to use when shelling out
      to another Ruby environment
  - guests/arch: Support predictable network interface naming. [GH-4468]
  - guests/suse: Support NFS client install, rsync setup. [GH-4492]
  - guests/tinycore: Support changing host names. [GH-4469]
  - guests/tinycore: Support DHCP-based networks. [GH-4710]
  - guests/windows: Hostname can be set without reboot. [GH-4687]
  - providers/docker: Build output is now shown. [GH-3739]
  - providers/docker: Can now start containers from private repositories
      more easily. Vagrant will login for you if you specify auth. [GH-4042]
  - providers/docker: `stop_timeout` can be used to modify the `docker stop`
      timeout. [GH-4504]
  - provisioners/chef: Automatically install Chef when using a Chef provisioner.
  - provisioners/ansible: Always show Ansible command executed when Vagrant log
      level is debug (even if ansible.verbose is false)
  - synced\_folders/nfs: Won't use `sudo` to write to /etc/exports if there
      are write privileges. [GH-2643]
  - synced\_folders/smb: Credentials from one SMB will be copied to the rest. [GH-4675]

BUG FIXES:

  - core: Fix cases where sometimes SSH connection would hang.
  - core: On a graceful halt, force halt if capability "insert public key"
      is missing. [GH-4684]
  - core: Don't share `/vagrant` if any "." folder is shared. [GH-4675]
  - core: Fix SSH private key permissions more aggressively. [GH-4670]
  - core: Custom Vagrant Cloud server URL now respected in more cases.
  - core: On downloads, don't continue downloads if the remote server
      doesn't support byte ranges. [GH-4479]
  - core: Box downloads recognize more complex content types that include
      "application/json" [GH-4525]
  - core: If all sub-machines are `autostart: false`, don't start any. [GH-4552]
  - core: Update global-status state in more cases. [GH-4513]
  - core: Only delete machine state if the machine is not created in initialize
  - commands/box: `--cert` flag works properly. [GH-4691]
  - command/docker-logs: Won't crash if container is removed. [GH-3990]
  - command/docker-run: Synced folders will be attached properly. [GH-3873]
  - command/rsync: Sync to Docker containers properly. [GH-4066]
  - guests/darwin: Hostname sets bonjour name and local host name. [GH-4535]
  - guests/freebsd: NFS mounting can specify the version. [GH-4518]
  - guests/linux: More descriptive error message if SMB mount fails. [GH-4641]
  - guests/rhel: Hostname setting on 7.x series works properly. [GH-4527]
  - guests/rhel: Installing NFS client works properly on 7.x [GH-4499]
  - guests/solaris11: Static IP address preserved after restart. [GH-4621]
  - guests/ubuntu: Detect with `lsb_release` instead of `/etc/issue`. [GH-4565]
  - hosts/windows: RDP client shouldn't map all drives by default. [GH-4534]
  - providers/docker: Create args works. [GH-4526]
  - providers/docker: Nicer error if package is called. [GH-4595]
  - providers/docker: Host IP restriction is forwarded through. [GH-4505]
  - providers/docker: Protocol is now honored in direct `ports settings.
  - providers/docker: Images built using `build_dir` will more robustly
      capture the final image. [GH-4598]
  - providers/docker: NFS synced folders now work. [GH-4344]
  - providers/docker: Read the created container ID more robustly.
  - providers/docker: `vagrant share` uses correct IP of proxy VM if it
      exists. [GH-4342]
  - providers/docker: `vagrant_vagrantfile` expands home directory. [GH-4000]
  - providers/docker: Fix issue where multiple identical proxy VMs would
      be created. [GH-3963]
  - providers/docker: Multiple links with the same name work. [GH-4571]
  - providers/virtualbox: Show a human-friendly error if VirtualBox didn't
      clean up an existing VM. [GH-4681]
  - providers/virtualbox: Detect case when VirtualBox reports 0.0.0.0 as
      IP address and don't allow it. [GH-4671]
  - providers/virtualbox: Show more descriptive error if VirtualBox is
      reporting an empty version. [GH-4657]
  - provisioners/ansible: Force `ssh` (OpenSSH) connection by default [GH-3396]
  - provisioners/ansible: Don't use or modify `~/.ssh/known_hosts` file by default,
      similarly to native vagrant commands [GH-3900]
  - provisioners/ansible: Use intermediate Docker host when needed. [GH-4071]
  - provisioners/docker: Get GPG key over SSL. [GH-4597]
  - provisioners/docker: Search for docker binary in multiple places. [GH-4580]
  - provisioners/salt: Highstate works properly with a master. [GH-4471]
  - provisioners/shell: Retry getting SSH info a few times. [GH-3924]
  - provisioners/shell: PowerShell scripts can have args. [GH-4548]
  - synced\_folders/nfs: Don't modify NFS exports file if no exports. [GH-4619]
  - synced\_folders/nfs: Prune exports for file path IDs. [GH-3815]

PLUGIN AUTHOR CHANGES:

  - `Machine#action` can be called with the option `lock: false` to not
      acquire a machine lock.
  - `Machine#reload` will now properly trigger the `machine_id_changed`
      callback on providers.

## 1.6.5 (September 4, 2014)

BUG FIXES:

  - core: forward SSH even if WinRM is used. [GH-4437]
  - communicator/ssh: Fix crash when pty is enabled with SSH. [GH-4452]
  - guests/redhat: Detect various RedHat flavors. [GH-4462]
  - guests/redhat: Fix typo causing crash in configuring networks. [GH-4438]
  - guests/redhat: Fix typo causing hostnames to not set. [GH-4443]
  - providers/virtualbox: NFS works when using DHCP private network. [GH-4433]
  - provisioners/salt: Fix error when removing non-existent bootstrap script
      on Windows. [GH-4614]

## 1.6.4 (September 2, 2014)

BACKWARDS INCOMPATIBILITIES:

  - commands/docker-run: Started containers are now deleted after run.
      Specify the new `--no-rm` flag to retain the original behavior. [GH-4327]
  - providers/virtualbox: Host IO cache is no longer enabled by default
      since it causes stale file issues. Please enable manually if you
      require this. [GH-3934]

IMPROVEMENTS:

  - core: Added `config.vm.box_server_url` setting to point at a
     Vagrant Cloud instance. [GH-4282]
  - core: File checksumming performance has been improved by at least
      100%. Memory requirements have gone down by half. [GH-4090]
  - commands/docker-run: Add the `--no-rm` flag. Containers are
      deleted by default. [GH-4327]
  - commands/plugin: Better error output is shown when plugin installation
      fails.
  - commands/reload: show post up messsage [GH-4168]
  - commands/rsync-auto: Add `--poll` flag. [GH-4392]
  - communicators/winrm: Show stdout/stderr if command fails. [GH-4094]
  - guests/nixos: Added better NFS support. [GH-3983]
  - providers/hyperv: Accept VHD disk format. [GH-4208]
  - providers/hyperv: Support generation 2 VMs. [GH-4324]
  - provisioners/docker: More verbose output. [GH-4377]
  - provisioners/salt: Get proper exit codes to detect failed runs. [GH-4304]

BUG FIXES:

  - core: Downloading box files should resume in more cases since the
      temporary file is preserved in more cases. [GH-4301]
  - core: Windows is not detected as NixOS in some cases. [GH-4302]
  - core: Fix encoding issues with Windows. There are still some outlying
      but this fixes a few. [GH-4159]
  - core: Fix crash case when destroying with an invalid provisioner. [GH-4281]
  - core: Box names with colons work on Windows. [GH-4100]
  - core: Cleanup all temp files. [GH-4103]
  - core: User curlrc is not loaded, preventing strange download issues.
      [GH-4328]
  - core: VM names may no longer contain brackets, since they cause
      issues with some providers. [GH-4319]
  - core: Use "-f" to `rm` files in case pty is true. [GH-4410]
  - core: SSH key doesn't have to be owned by our user if we're running
      as root. [GH-4387]
  - core: "vagrant provision" will cause "vagrant up" to properly not
      reprovision. [GH-4393]
  - commands/box/add: "Content-Type" header is now case-insensitive when
      looking for metadata type. [GH-4369]
  - commands/docker-run: Named docker containers no longer conflict. [GH-4294]
  - commands/package: base package won't crash with exception [GH-4017]
  - commands/rsync-auto: Destroyed machines won't raise exceptions. [GH-4031]
  - commands/ssh: Extra args are passed through to Docker container. [GH-4378]
  - communicators/ssh: Nicer error if remote unexpectedly disconects. [GH-4038]
  - communicators/ssh: Clean error when max sessions is hit. [GH-4044]
  - communicators/ssh: Fix many issues around PTY-enabled output parsing.
      [GH-4408]
  - communicators/winrm: Support `mkdir` [GH-4271]
  - communicators/winrm: Properly escape double quotes. [GH-4309]
  - communicators/winrm: Detect failed commands that aren't CLIs. [GH-4383]
  - guests/centos: Fix issues when NFS client is installed by restarting
      NFS [GH-4088]
  - guests/debian: Deleting default route on DHCP networks can fail. [GH-4262]
  - guests/fedora: Fix networks on Fedora 20 with libvirt. [GH-4104]
  - guests/freebsd: Rsync install for rsync synced folders work on
      FreeBSD 10. [GH-4008]
  - guests/freebsd: Configure vtnet devices properly [GH-4307]
  - guests/linux: Show more verbose error when shared folder mount fails.
      [GH-4403]
  - guests/redhat: NFS setup should use systemd for RH7+ [GH-4228]
  - guests/redhat: Detect RHEL 7 (and CentOS) and install Docker properly. [GH-4402]
  - guests/redhat: Configuring networks on EL7 works. [GH-4195]
  - guests/redhat: Setting hostname on EL7 works. [GH-4352]
  - guests/smartos: Use `pfexec` for rsync. [GH-4274]
  - guests/windows: Reboot after hostname change. [GH-3987]
  - hosts/arch: NFS works with latest versions. [GH-4224]
  - hosts/freebsd: NFS exports are proper syntax. [GH-4143]
  - hosts/gentoo: NFS works with latest versions. [GH-4418]
  - hosts/windows: RDP command works without crash. [GH-3962]
  - providers/docker: Port on its own will choose random host port. [GH-3991]
  - providers/docker: The proxy VM Vagrantfile can be in the same directory
      as the main Vagrantfile. [GH-4065]
  - providers/virtualbox: Increase network device limit to 36. [GH-4206]
  - providers/virtualbox: Error if can't detect VM name. [GH-4047]
  - provisioners/cfengine: Fix default Yum repo URL. [GH-4335]
  - provisioners/chef: Chef client cleanup should work. [GH-4099]
  - provisioners/puppet: Manifest file can be a directory. [GH-4169]
  - provisioners/puppet: Properly escape facter variables for PowerShell
      on Windows guests. [GH-3959]
  - provisioners/puppet: When provisioning fails, don't repeat all of
      stdout/stderr. [GH-4303]
  - provisioners/salt: Update salt minion version on Windows. [GH-3932]
  - provisioners/shell: If args is an array and contains numbers, it no
      longer crashes. [GH-4234]
  - provisioners/shell: If fails, the output/stderr isn't repeated
      again. [GH-4087]

## 1.6.3 (May 29, 2014)

FEATURES:

  - **New Guest:** NixOS - Supports changing host names and setting
      networks. [GH-3830]

IMPROVEMENTS:

  - core: A CA path can be specified in the Vagrantfile, not just
      a file, when using a custom CA. [GH-3848]
  - commands/box/add: `--capath` flag added for custom CA path. [GH-3848]
  - commands/halt: Halt in reverse order of up, like destroy. [GH-3790]
  - hosts/linux: Uses rdesktop to RDP into machines if available. [GH-3845]
  - providers/docker: Support for UDP forwarded ports. [GH-3886]
  - provisioners/salt: Works on Windows guests. [GH-3825]

BUG FIXES:

  - core: Provider plugins more easily are compatible with global-status
      and should show less stale data. [GH-3808]
  - core: When setting a synced folder, it will assume it is not disabled
      unless explicitly specified. [GH-3783]
  - core: Ignore UDP forwarded ports for collision detection. [GH-3859]
  - commands/package: Package with `--base` for VirtualBox doesn't
      crash. [GH-3827]
  - guests/solaris11: Fix issue with public network and DHCP on newer
      Solaris releases. [GH-3874]
  - guests/windows: Private networks with static IPs work when there
      is more than one. [GH-3818]
  - guests/windows: Don't look up a forwarded port for WinRM if we're
      not accessing the local host. [GH-3861]
  - guests/windows: Fix errors with arg lists that are too long over
      WinRM in some cases. [GH-3816]
  - guests/windows: Powershell exits with proper exit code, fixing
  -   issues where non-zero exit codes weren't properly detected. [GH-3922]
  - hosts/windows: Don't execute mstsc using PowerShell since it doesn't
      exit properly. [GH-3837]
  - hosts/windows: For RDP, don't remove the Tempfile right away. [GH-3875]
  - providers/docker: Never do graceful shutdown, always use
      `docker stop`. [GH-3798]
  - providers/docker: Better error messaging when SSH is not ready
      direct to container. [GH-3763]
  - providers/docker: Don't port map SSH port if container doesn't
      support SSH. [GH-3857]
  - providers/docker: Proper SSH info if using native driver. [GH-3799]
  - providers/docker: Verify host VM has SSH ready. [GH-3838]
  - providers/virtualbox: On Windows, check `VBOX_MSI_INSTALL_PATH`
      for VBoxManage path as well. [GH-3852]
  - provisioners/puppet: Fix setting facter vars with Windows
      guests. [GH-3776]
  - provisioners/puppet: On Windows, run in elevated prompt. [GH-3903]
  - guests/darwin: Respect mount options for NFS. [GH-3791]
  - guests/freebsd: Properly register the rsync_pre capability
  - guests/windows: Certain executed provisioners won't leave output
      and exit status behind. [GH-3729]
  - synced\_folders/rsync: `rsync__chown` can be set to `false` to
      disable recursive chown after sync. [GH-3810]
  - synced\_folders/rsync: Use a proper msys path if not in
      Cygwin. [GH-3804]
  - synced\_folders/rsync: Don't append args infinitely, clear out
      arg list on each run. [GH-3864]

PLUGIN AUTHOR CHANGES:

  - Providers can now implement the `rdp_info` provider capability
      to get proper info for `vagrant rdp` to function.

## 1.6.2 (May 12, 2014)

IMPROVEMENTS:

  - core: Automatically forward WinRM port if communicator is
      WinRM. [GH-3685]
  - command/rdp: Args after "--" are passed directly through to the
      RDP client. [GH-3686]
  - providers/docker: `build_args` config to specify extra args for
      `docker build`. [GH-3684]
  - providers/docker: Can specify options for the build dir synced
      folder when a host VM is in use. [GH-3727]
  - synced\_folders/nfs: Can tell Vagrant not to handle exporting
      by setting `nfs_export: false` [GH-3636]

BUG FIXES:

  - core: Hostnames can be one character. [GH-3713]
  - core: Don't lock machines on SSH actions. [GH-3664]
  - core: Fixed crash when adding a box from Vagrant Cloud that was the
      same name as a real directory. [GH-3732]
  - core: Parallelization is more stable, doesn't crash due to to
      bad locks. [GH-3735]
  - commands/package: Don't double included files in package. [GH-3637]
  - guests/linux: Rsync chown ignores symlinks. [GH-3744]
  - provisioners/shell: Fix shell provisioner config validation when the
    `binary` option is set to false [GH-3712]
  - providers/docker: default proxy VM won't use HGFS [GH-3687]
  - providers/docker: fix container linking [GH-3719]
  - providers/docker: Port settings expose to host properly. [GH-3723]
  - provisioners/puppet: Separate module paths with ';' on Windows. [GH-3731]
  - synced\_folders\rsync: Copy symlinks as real files. [GH-3734]
  - synced\_folders/rsync: Remove non-portable '-v' flag from chown. [GH-3743]

## 1.6.1 (May 7, 2014)

IMPROVEMENTS:

  - **New guest: Linux Mint** is now properly detected. [GH-3648]

BUG FIXES:

  - core: Global control works from directories that don't have a
      Vagrantfile.
  - core: Plugins that define config methods that collide with Ruby Kernel/Object
  -   methods are merged properly. [GH-3670]
  - commands/docker-run: `--help` works. [GH-3698]
  - commands/package: `--base` works without crashing for VirtualBox.
  - commands/reload: If `--provision` is specified, force provisioning. [GH-3657]
  - guests/redhat: Fix networking issues with CentOS. [GH-3649]
  - guests/windows: Human error if WinRM not in use to configure networks. [GH-3651]
  - guests/windows: Puppet exit code 2 doesn't cause Windows to raise
      an error. [GH-3677]
  - providers/docker: Show proper error message when on Linux. [GH-3654]
  - providers/docker: Proxy VM works properly even if default provider
      environmental variable set to "docker" [GH-3662]
  - providers/docker: Put sync folders in `/var/lib/docker` because
      it usually has disk space. [GH-3680]
  - synced\_folders/rsync: Create the directory before syncing.

## 1.6.0 (May 6, 2014)

BACKWARDS INCOMPATIBILITIES:

  - Deprecated: `halt_timeout` and `halt_check_interval` settings for
      SmartOS, Solaris, and Solaris11 guests. These will be fully
      removed in 1.7. A warning will be shown if they're in use in
      1.6.

FEATURES:

  - **New guest: Windows**. Vagrant now fully supports Windows as a guest
      VM. WinRM can be used for communication (or SSH), and the shell
      provisioner, Chef, and Puppet all work with Windows VMs.
  - **New command: global-status**. This command shows the state of every
      created Vagrant environment on the system for that logged in user.
  - **New command: rdp**. This command connects to the running machine
      via the Remote Desktop Protocol.
  - **New command: version**. This outputs the currently installed version
      as well as the latest version of Vagrant available.
  - **New provider: Docker**. This provider will back your development
      environments with Docker containers. If you're not on Linux, it will
      automatically spin up a VM for you on any provider. You can even
      specify a specific Vagrantfile to use as the Docker container host.
  - Control Vagrant environments from any directory. Using the UUIDs given
      in `vagrant global-status`, you can issue commands from anywhere on
      your machine, not just that environment's directory. Example:
      `vagrant destroy UUID` from anywhere.
  - Can now specify a `post_up_message` in your Vagrantfile that is shown
      after a `vagrant up`. This is useful for putting some instructions of how
      to use the development environment.
  - Can configure provisioners to run "once" or "always" (defaults to "once"),
      so that subsequent `vagrant up` or `reload` calls will always run a
      provisioner. [GH-2421]
  - Multi-machine environments can specify an "autostart" option (default
      to true). `vagrant up` starts all machines that have enabled autostart.
  - Vagrant is smarter about choosing a default provider. If
    `VAGRANT_DEFAULT_PROVIDER` is set, it still takes priority, but otherwise
    Vagrant chooses a "best" provider.

IMPROVEMENTS:

  - core: Vagrant locks machine access to one Vagrant process at a time.
      This will protect against two simultaneous `up` actions happening
      on the same environment.
  - core: Boxes can be compressed with LZMA now as well.
  - commands/box/remove: Warns if the box appears to be in use by an
      environment. Can be forced with `--force`.
  - commands/destroy: Exit codes changes. 0 means everything succeeded.
      1 means everything was declined. 2 means some were declined. [GH-811]
  - commands/destroy: Doesn't require box to exist anymore. [GH-1629]
  - commands/init: force flag. [GH-3564]
  - commands/init: flag for minimal Vagrantfile creation (no comments). [GH-3611]
  - commands/rsync-auto: Picks up and syncs provisioner folders if
      provisioners are backed by rsync.
  - commands/rsync-auto: Detects when new synced folders were added and warns
      user they won't be synced until `vagrant reload`.
  - commands/ssh-config: Works without a target in multi-machine envs [GH-2844]
  - guests/freebsd: Support for virtio interfaces. [GH-3082]
  - guests/openbsd: Support for virtio interfaces. [GH-3082]
  - guests/redhat: Networking works for upcoming RHEL7 release. [GH-3643]
  - providers/hyperv: Implement `vagrant ssh -c` support. [GH-3615]
  - provisioners/ansible: Support for Ansible Vault. [GH-3338]
  - provisioners/ansible: Show Ansible command executed. [GH-3628]
  - provisioners/salt: Colorize option. [GH-3603]
  - provisioners/salt: Ability to specify log level. [GH-3603]
  - synced\_folders: nfs: Improve sudo commands used to make them
      sudoers friendly. Examples in docs. [GH-3638]

BUG FIXES:

  - core: Adding a box from a network share on Windows works again. [GH-3279]
  - commands/plugin/install: Specific versions are now locked in.
  - commands/plugin/install: If insecure RubyGems.org is specified as a
      source, use that. [GH-3610]
  - commands/rsync-auto: Interrupt exits properly. [GH-3552]
  - commands/rsync-auto: Run properly on Windows. [GH-3547]
  - communicators/ssh: Detect if `config.ssh.shell` is invalid. [GH-3040]
  - guests/debian: Can set hostname if hosts doesn't contain an entry
      already for 127.0.1.1 [GH-3271]
  - guests/linux: For `read_ip_address` capability, set `LANG=en` so
      it works on international systems. [GH-3029]
  - providers/virtualbox: VirtalBox detection works properly again on
      Windows when the `VBOX_INSTALL_PATH` has multiple elements. [GH-3549]
  - providers/virtualbox: Forcing MAC address on private network works
      properly again. [GH-3588]
  - provisioners/chef-solo: Fix Chef version checking to work with prerelease
      versions. [GH-3604]
  - provisioners/salt: Always copy keys and configs on provision. [GH-3536]
  - provisioners/salt: Install args should always be present with bootstrap.
  - provisioners/salt: Overwrite keys properly on subsequent provisions [GH-3575]
  - provisioners/salt: Bootstrap uses raw GitHub URL rather than subdomain. [GH-3583]
  - synced\_folders/nfs: Acquires a process-level lock so exports don't
      collide with Vagrant running in parallel.
  - synced\_folders/nfs: Implement usability check so that hosts that
      don't support NFS get an error earlier. [GH-3625]
  - synced\_folders/rsync: Add UserKnownHostsFile option to not complain. [GH-3511]
  - synced\_folders/rsync: Proxy command is used properly if set. [GH-3553]
  - synced\_folders/rsync: Owner/group settings are respected. [GH-3544]
  - synced\_folders/smb: Passwords with symbols work. [GH-3642]

PLUGIN AUTHOR CHANGES:

  - **New host capability:** "rdp\_client". This capability gets the RDP connection
      info and must launch the RDP client on the system.
  - core: The "Call" middleware now merges the resulting middleware stack
      into the current stack, rather than running it as a separate stack.
      The result is that ordering is preserved.
  - core: The "Message" middleware now takes a "post" option that will
      output the message on the return-side of the middleware stack.
  - core: Forwarded port collision repair works when Vagrant is run in
      parallel with other Vagrant processes. [GH-2966]
  - provider: Providers can now specify that boxes are optional. This lets
      you use the provider without a `config.vm.box`. Useful for providers like
      AWS or Docker.
  - provider: A new class-level `usable?` method can be implemented on the
      provider implementation. This returns or raises an error when the
      provider is not usable (i.e. VirtualBox isn't installed for VirtualBox)
  - synced\_folders: New "disable" method for removing synced folders from
      a running machine.

## 1.5.4 (April 21, 2014)

IMPROVEMENTS:

  - commands/box/list: Doesn't parse Vagrantfile. [GH-3502]
  - providers/hyperv: Implement the provision command. [GH-3494]

BUG FIXES:

  - core: Allow overriding of the default SSH port. [GH-3474]
  - commands/box/remove: Make output nicer. [GH-3470]
  - commands/box/update: Show currently installed version. [GH-3467]
  - command/rsync-auto: Works properly on Windows.
  - guests/coreos: Fix test for Docker daemon running.
  - guests/linux: Fix test for Docker provisioner whether Docker is
      running.
  - guests/linux: Fix regression where rsync owner/group stopped
      working. [GH-3485]
  - provisioners/docker: Fix issue where we weren't waiting for Docker
      to properly start before issuing commands. [GH-3482]
  - provisioners/shell: Better validation of master config path, results
      in no more stack traces at runtime. [GH-3505]

## 1.5.3 (April 14, 2014)

IMPROVEMENTS:

  - core: 1.5 upgrade code gives users a chance to quit. [GH-3212]
  - commands/rsync-auto: An initial sync is done before watching folders. [GH-3327]
  - commands/rsync-auto: Exit immediately if there are no paths to watch.
      [GH-3446]
  - provisioners/ansible: custom vars/hosts files can be added in
      .vagrant/provisioners/ansible/inventory/ directory [GH-3436]

BUG FIXES:

  - core: Randomize some filenames internally to improve the parallelism
      of Vagrant. [GH-3386]
  - core: Don't error if network problems cause box update check to
      fail [GH-3391]
  - core: `vagrant` on Windows cmd.exe doesn't always exit with exit
      code zero. [GH-3420]
  - core: Adding a box from a network share has nice error on Windows. [GH-3279]
  - core: Setting an ID on a provisioner now works. [GH-3424]
  - core: All synced folder paths containing symlinks are fully
      expanded before sharing. [GH-3444]
  - core: Windows no longer sees "process not started" errors rarely.
  - commands/box/repackage: Works again. [GH-3372]
  - commands/box/update: Update should check for updates from latest
      version. [GH-3452]
  - commands/package: Nice error if includes contain symlinks. [GH-3200]
  - commands/rsync-auto: Don't crash if the machine can't be communicated
      to. [GH-3419]
  - communicators/ssh: Throttle connection attempt warnings if the warnings
      are the same. [GH-3442]
  - guests/coreos: Docker provisioner works. [GH-3425]
  - guests/fedora: Fix hostname setting. [GH-3382]
  - guests/fedora: Support predictable network interface names for
      public/private networks. [GH-3207]
  - guests/linux: Rsync folders have proper group if owner not set. [GH-3223]
  - guests/linux: If SMB folder mounting fails, the password will no
      longer be shown in plaintext in the output. [GH-3203]
  - guests/linux: SMB mount works with passwords with symbols. [GH-3202]
  - providers/hyperv: Check for PowerShell features. [GH-3398]
  - provisioners/docker: Don't automatically generate container name with
      a forward slash. [GH-3216]
  - provisioners/shell: Empty shell scripts don't cause errors. [GH-3423]
  - synced\_folders/smb: Only set the chmod properly by default on Windows
      if it isn't already set. [GH-3394]
  - synced\_folders/smb: Sharing folders with odd characters like parens
      works properly now. [GH-3405]

## 1.5.2 (April 2, 2014)

IMPROVEMENTS:

  - **New guest:** SmartOS
  - core: Change wording from "error" to "warning" on SSH retry output
    to convey actual meaning.
  - commands/plugin: Listing plugins now has machine-readable output. [GH-3293]
  - guests/omnios: Mount NFS capability [GH-3282]
  - synced\_folders/smb: Verify PowerShell v3 or later is running. [GH-3257]

BUG FIXES:

  - core: Vagrant won't collide with newer versions of Bundler [GH-3193]
  - core: Allow provisioner plugins to not have a config class. [GH-3272]
  - core: Removing a specific box version that doesn't exist doesn't
      crash Vagrant. [GH-3364]
  - core: SSH commands are forced to be ASCII.
  - core: private networks with DHCP type work if type parameter is
      a string and not a symbol. [GH-3349]
  - core: Converting to cygwin path works for folders with spaces. [GH-3304]
  - core: Can add boxes with spaces in their path. [GH-3306]
  - core: Prerelease plugins installed are locked to that prerelease
      version. [GH-3301]
  - core: Better error message when adding a box with a malformed version. [GH-3332]
  - core: Fix a rare issue where vagrant up would complain it couldn't
      check version of a box that doesn't exist. [GH-3326]
  - core: Box version constraint can't be specified with old-style box. [GH-3260]
  - commands/box: Show versions when listing. [GH-3316]
  - commands/box: Outdated check can list local boxes that are newer. [GH-3321]
  - commands/status: Machine readable output contains the target. [GH-3218]
  - guests/arch: Reload udev rules after network change. [GH-3322]
  - guests/debian: Changing host name works properly. [GH-3283]
  - guests/suse: Shutdown works correctly on SLES [GH-2775]
  - hosts/linux: Don't hardcode `exportfs` path. Now searches the PATH. [GH-3292]
  - providers/hyperv: Resume command works properly. [GH-3336]
  - providers/virtualbox: Add missing translation for stopping status. [GH-3368]
  - providers/virtualbox: Host-only networks set cableconnected property
      to "yes" [GH-3365]
  - provisioners/docker: Use proper flags for 0.9. [GH-3356]
  - synced\_folders/rsync: Set chmod flag by default on Windows. [GH-3256]
  - synced\_folders/smb: IDs of synced folders are hashed to work better
      with VMware. [GH-3219]
  - synced\_folders/smb: Properly remove existing folders with the
      same name. [GH-3354]
  - synced\_folders/smb: Passwords with symbols now work. [GH-3242]
  - synced\_folders/smb: Exporting works for non-english locale Windows
      machines. [GH-3251]

## 1.5.1 (March 13, 2014)

IMPROVEMENTS:

  - guests/tinycore: Will now auto-install rsync.
  - synced\_folders/rsync: rsync-auto will not watch filesystem for
    excluded paths. [GH-3159]

BUG FIXES:

  - core: V1 Vagrantfiles can upgrade provisioners properly. [GH-3092]
  - core: Rare EINVAL errors on box adding are gone. [GH-3094]
  - core: Upgrading the home directory for Vagrant 1.5 uses the Vagrant
    temp dir. [GH-3095]
  - core: Assume a box isn't metadata if it exceeds 20 MB. [GH-3107]
  - core: Asking for input works even in consoles that don't support
    hiding input. [GH-3119]
  - core: Adding a box by path in Cygwin on Windos works. [GH-3132]
  - core: PowerShell scripts work when they're in a directory with
    spaces. [GH-3100]
  - core: If you add a box path that doesn't exist, error earlier. [GH-3091]
  - core: Validation on forwarded ports to make sure they're between
    0 and 65535. [GH-3187]
  - core: Downloads with user/password use the curl `-u` flag. [GH-3183]
  - core: `vagrant help` no longer loads the Vagrantfile. [GH-3180]
  - guests/darwin: Fix an exception when configuring networks. [GH-3143]
  - guests/linux: Only chown folders/files in rsync if they don't
    have the proper owner. [GH-3186]
  - hosts/linux: Unusual sed delimiter to avoid conflicts. [GH-3167]
  - providers/virtualbox: Make more internal interactions with VBoxManage
    retryable to avoid spurious VirtualBox errors. [GH-2831]
  - providers/virtualbox: Import progress works again on Windows.
  - provisioners/ansible: Request SSH info within the provision method,
    when we know its available. [GH-3111]
  - synced\_folders/rsync: owner/group settings work. [GH-3163]

## 1.5.0 (March 10, 2014)

BREAKING CHANGES:

  - provisioners/ansible: the machine name (taken from Vagrantfile) is now
    set as default limit to ensure that vagrant provision steps only
    affect the expected machine.

DEPRECATIONS:

  - provisioners/chef-solo: The "nfs" setting has been replaced by
    `synced_folder_type`. The "nfs" setting will be removed in the next
    version.
  - provisioners/puppet: The "nfs" setting has been replaced by
    `synced_folder_type`. The "nfs" setting will be removed in the next
    version.

FEATURES:

  - **New provider:** Hyper-V. If you're on a Windows machine with Hyper-V
    enabled, Vagrant can now manage Hyper-V virtual machines out of the box.
  - **New guest:** Funtoo (change host name and networks supported)
  - **New guest:** NetBSD
  - **New guest:** TinyCore Linux. This allows features such as networking,
    halting, rsync and more work with Boot2Docker.
  - **New synced folder type:** rsync - Does a one-time one-directional sync
    to the guest machine. New commands `vagrant rsync` and `vagrant rsync-auto`
    can resync the folders.
  - **New synced folder type:** SMB- Allows bi-directional folder syncing
    using SMB on Windows hosts with any guest.
  - Password-based SSH authentication. This lets you use almost any off-the-shelf
    virtual machine image with Vagrant. Additionally, Vagrant will automatically
    insert a keypair into the machine.
  - Plugin versions can now be constrained to a range of versions. Example:
    `vagrant plugin install foo --plugin-version "> 1.0, < 1.1"`
  - Host-specific operations now use a "host capabilities" system much like
    guests have used "guest capabilities" for a few releases now. This allows
    plugin developers to create pluggable host-specific capabilities and makes
    further integrating Vagrant with new operating systems even easier.
  - You can now override provisioners within sub-VM configuration and
    provider overrides. See documentation for more info. [GH-1113]
  - providers/virtualbox: Provider-specific configuration `cpus` can be used
    to set the number of CPUs on the VM [GH-2800]
  - provisioners/docker: Can now build images using `docker build`. [GH-2615]

IMPROVEMENTS:

  - core: Added "error-exit" type to machine-readable output which contains
    error information that caused a non-zero exit status. [GH-2999]
  - command/destroy: confirmation will re-ask question if bad input. [GH-3027]
  - guests/solaris: More accurate Solaris >= 11, < 11 detection. [GH-2824]
  - provisioners/ansible: Generates a single inventory file, rather than
    one per machine. See docs for more info. [GH-2991]
  - provisioners/ansible: SSH forwarding support. [GH-2952]
  - provisioners/ansible: Multiple SSH keys can now be attempted [GH-2952]
  - provisioners/ansible: Disable SSH host key checking by default,
    which improves the experience. We believe this is a sane default
    for ephemeral dev machines.
  - provisioners/chef-solo: New config `synced_folder_type` replaces the
    `nfs` option. This can be used to set the synced folders the provisioner
    needs to any type. [GH-2709]
  - provisioners/chef-solo: `roles_paths` can now be an array of paths in
    Chef 11.8.0 and newer. [GH-2975]
  - provisioners/docker: Can start a container without daemonization.
  - provisioners/docker: Started containers are given names. [GH-3051]
  - provisioners/puppet: New config `synced_folder_type` replaces the
    `nfs` option. This can be used to set the synced folders the provisioner
    needs to any type. [GH-2709]
  - commands/plugin: `vagrant plugin update` will now update all installed
    plugins, respecting any constraints set.
  - commands/plugin: `vagrant plugin uninstall` can now uninstall multiple
    plugins.
  - commands/plugin: `vagrant plugin install` can now install multiple
    plugins.
  - hosts/redhat: Recognize Korora OS. [GH-2869]
  - synced\_folders/nfs: If the guest supports it, NFS clients will be
    automatically installed in the guest.

BUG FIXES:

  - core: If an exception was raised while attempting to connect to SSH
    for the first time, it would get swallowed. It is properly raised now.
  - core: Plugin installation does not fail if your local gemrc file has
    syntax errors.
  - core: Plugins that fork within certain actions will no longer hang
    indefinitely. [GH-2756]
  - core: Windows checks home directory permissions more correctly to
    warn of potential issues.
  - core: Synced folders set to the default synced folder explicitly won't
    be deleted. [GH-2873]
  - core: Static IPs can end in ".1". A warning is now shown. [GH-2914]
  - core: Adding boxes that have directories in them works on Windows.
  - core: Vagrant will not think provisioning is already done if
    the VM is manually deleted outside of Vagrant.
  - core: Box file checksums of large files works properly on Windows.
    [GH-3045]
  - commands/box: Box add `--force` works with `--provider` flag. [GH-2757]
  - commands/box: Listing boxes with machine-readable output crash is gone.
  - commands/plugin: Plugin installation will fail if dependencies conflict,
    rather than at runtime.
  - commands/ssh: When using `-c` on Windows, no more TTY errors.
  - commands/ssh-config: ProxyCommand is included in output if it is
    set. [GH-2950]
  - guests/coreos: Restart etcd after configuring networks. [GH-2852]
  - guests/linux: Don't chown VirtualBox synced folders if mounting
    as readonly. [GH-2442]
  - guests/redhat: Set hostname to FQDN, per the documentation for RedHat.
    [GH-2792]
  - hosts/bsd: Don't invoke shell for NFS sudo calls. [GH-2808]
  - hosts/bsd: Sort NFS exports to avoid false validation errors. [GH-2927]
  - hosts/bsd: No more checkexports NFS errors if you're sharing the
    same directory. [GH-3023]
  - hosts/gentoo: Look for systemctl in `/usr/bin` [GH-2858]
  - hosts/linux: Properly escape regular expression to prune NFS exports,
    allowing VMware to work properly. [GH-2934]
  - hosts/opensuse: Start NFS server properly. [GH-2923]
  - providers/virtualbox: Enabling internal networks by just setting "true"
    works properly. [GH-2751]
  - providers/virtualbox: Make more internal interactions with VBoxManage
    retryable to avoid spurious VirtualBox errors. [GH-2831]
  - providers/virtualbox: Config validation catches invalid keys. [GH-2843]
  - providers/virtualbox: Fix network adapter configuration issue if using
    provider-specific config. [GH-2854]
  - providers/virtualbox: Bridge network adapters always have their
    "cable connected" properly. [GH-2906]
  - provisioners/chef: When chowning folders, don't follow symlinks.
  - provisioners/chef: Encrypted data bag secrets also in Chef solo are
    now uploaded to the provisioning path to avoid perm issues. [GH-2845]
  - provisioners/chef: Encrypted data bag secret is removed from the
    machine before and after provisioning also with Chef client. [GH-2845]
  - provisioners/chef: Set `encrypted_data_bag_secret` on the VM to `nil`
    if the secret is not specified. [GH-2984]
  - provisioners/chef: Fix loading of the custom configure file. [GH-876]
  - provisioners/docker: Only add SSH user to docker group if the user
    isn't already in it. [GH-2838]
  - provisioners/docker: Configuring autostart works properly with
    the newest versions of Docker. [GH-2874]
  - provisioners/puppet: Append default module path to the module paths
    always. [GH-2677]
  - provisioners/salt: Setting pillar data doesn't require `deep_merge`
    plugin anymore. [GH-2348]
  - provisioners/salt: Options can now set install type and install args.
    [GH-2766]
  - provisioners/salt: Fix case when salt would say "options only allowed
    before install arguments" [GH-3005]
  - provisioners/shell: Error if script is encoded incorrectly. [GH-3000]
  - synced\_folders/nfs: NFS entries are pruned on every `vagrant up`,
    if there are any to prune. [GH-2738]

## 1.4.3 (January 2, 2014)

BUG FIXES:

  - providers/virtualbox: `vagrant package` works properly again. [GH-2739]

## 1.4.2 (December 31, 2013)

IMPROVEMENTS:

  - guests/linux: emit upstart event when NFS folders are mounted. [GH-2705]
  - provisioners/chef-solo: Encrypted data bag secret is removed from the
    machine after provisioning. [GH-2712]

BUG FIXES:

  - core: Ctrl-C no longer raises "trap context" exception.
  - core: The version for `Vagrant.configure` can now be an int. [GH-2689]
  - core: `Vagrant.has_plugin?` tries to use plugin's gem name before
    registered plugin name [GH-2617]
  - core: Fix exception if an EOFError was somehow raised by Ruby while
    checking a box checksum. [GH-2716]
  - core: Better error message if your plugin state file becomes corrupt
    somehow. [GH-2694]
  - core: Box add will fail early if the box already exists. [GH-2621]
  - hosts/bsd: Only run `nfsd checkexports` if there is an exports file.
    [GH-2714]
  - commands/plugin: Fix exception that could happen rarely when installing
    a plugin.
  - providers/virtualbox: Error when packaging if the package already exists
    _before_ the export is done. [GH-2380]
  - providers/virtualbox: NFS with static IP works even if VirtualBox
    guest additions aren't installed (regression). [GH-2674]
  - synced\_folders/nfs: sudo will only ask for password one at a time
    when using a parallel provider [GH-2680]

## 1.4.1 (December 18, 2013)

IMPROVEMENTS:

  - hosts/bsd: check NFS exports file for issues prior to exporting
  - provisioners/ansible: Add ability to use Ansible groups in generated
    inventory [GH-2606]
  - provisioners/docker: Add support for using the provisioner with RedHat
    based guests [GH-2649]
  - provisioners/docker: Remove "Docker" prefix from Client and Installer
    classes [GH-2641]

BUG FIXES:

  - core: box removal of a V1 box works
  - core: `vagrant ssh -c` commands are now executed in the context of
    a login shell (regression). [GH-2636]
  - core: specifying `-t` or `-T` to `vagrant ssh -c` as extra args
    will properly enable/disable a TTY for OpenSSH. [GH-2618]
  - commands/init: Error if can't write Vagrantfile to directory. [GH-2660]
  - guests/debian: fix `use_dhcp_assigned_default_route` to work properly.
    [GH-2648]
  - guests/debian,ubuntu: fix change\_host\_name for FQDNs with trailing
    dots [GH-2610]
  - guests/freebsd: configuring networks in the guest works properly
    [GH-2620]
  - guests/redhat: fix configure networks bringing down interfaces that
    don't exist. [GH-2614]
  - providers/virtualbox: Don't override NFS exports for all VMs when
    coming up. [GH-2645]
  - provisioners/ansible: Array arguments work for raw options [GH-2667]
  - provisioners/chef-client: Fix node/client deletion when node\_name is not
    set. [GH-2345]
  - provisioners/chef-solo: Force remove files to avoid cases where
    a prompt would be shown to users. [GH-2669]
  - provisioners/puppet: Don't prepend default module path for Puppet
    in case Puppet is managing its own paths. [GH-2677]

## 1.4.0 (December 9, 2013)

FEATURES:

  - New provisioner: Docker. Install Docker, pull containers, and run
    containers easier than ever.
  - Machine readable output. Vagrant now has machine-friendly output by
    using the `--machine-readable` flag.
  - New plugin type: synced folder implementation. This allows new ways of
    syncing folders to be added as plugins to Vagrant.
  - The `Vagrant.require_version` function can be used at the top of a Vagrantfile
    to enforce a minimum/maximum Vagrant version.
  - Adding boxes via `vagrant box add` and the Vagrantfile both support
    providing checksums of the box files.
  - The `--debug` flag can be specified on any command now to get debug-level
    log output to ease reporting bugs.
  - You can now specify a memory using `vb.memory` setting with VirtualBox.
  - Plugin developers can now hook into `environment_plugins_loaded`, which is
    executed after plugins are loaded but before Vagrantfiles are parsed.
  - VirtualBox internal networks are now supported. [GH-2020]

IMPROVEMENTS:

  - core: Support resumable downloads [GH-57]
  - core: owner/group of shared folders can be specified by integers. [GH-2390]
  - core: the VAGRANT\_NO\_COLOR environmental variable may be used to enable
    `--no-color` mode globally. [GH-2261]
  - core: box URL and add date is tracked and shown if `-i` flag is
    specified for `vagrant box list` [GH-2327]
  - core: Multiple SSH keys can be specified with `config.ssh.private_key_path`
    [GH-907]
  - core: `config.vm.box_url` can be an array of URLs. [GH-1958]
  - commands/box/add: Can now specify a custom CA cert for verifying
    certs from a custom CA. [GH-2337]
  - commands/box/add: Can now specify a client cert when downloading a
    box. [GH-1889]
  - commands/init: Add `--output` option for specifing output path, or
    "-" for stdin. [GH-1364]
  - commands/provision: Add `--no-parallel` option to disable provider
    parallelization if the provider supports it. [GH-2404]
  - commands/ssh: SSH compression is enabled by default. [GH-2456]
  - commands/ssh: Inline commands specified with "-c" are now executed
    using OpenSSH rather than pure-Ruby SSH. It is MUCH faster, and
    stdin works!
  - communicators/ssh: new configuration `config.ssh.pty` is a boolean for
    whether you want ot use a PTY for provisioning.
  - guests/linux: emit upstart event `vagrant-mounted` if upstart is
    available. [GH-2502]
  - guests/pld: support changing hostname [GH-2543]
  - providers/virtualbox: Enable symlinks for VirtualBox 4.1. [GH-2414]
  - providers/virtualbox: default VM name now includes milliseconds with
    a random number to try to avoid conflicts in CI environments. [GH-2482]
  - providers/virtualbox: customizations via VBoxManage are retried, avoiding
    VirtualBox flakiness [GH-2483]
  - providers/virtualbox: NFS works with DHCP host-only networks now. [GH-2560]
  - provisioners/ansible: allow files for extra vars [GH-2366]
  - provisioners/puppet: client cert and private key can now be specified
    for the puppet server provisioner. [GH-902]
  - provisioners/puppet: the manifests path can be in the VM. [GH-1805]
  - provisioners/shell: Added `keep_color` option to not automatically color
    output based on stdout/stderr. [GH-2505]
  - provisioners/shell: Arguments can now be an array of args. [GH-1949]
  - synced\_folders/nfs: Specify `nfs_udp` to false to disable UDP based
    NFS folders. [GH-2304]

BUG FIXES:

  - core: Make sure machine IDs are always strings. [GH-2434]
  - core: 100% CPU spike when waiting for SSH is fixed. [GH-2401]
  - core: Command lookup works on systems where PATH is not valid UTF-8 [GH-2514]
  - core: Human-friendly error if box metadata.json becomes corrupted. [GH-2305]
  - core: Don't load Vagrantfile on `vagrant plugin` commands, allowing
    Vagrantfiles that use plugins to work. [GH-2388]
  - core: global flags are ignored past the "--" on the CLI. [GH-2491]
  - core: provisoining will properly happen if `up` failed. [GH-2488]
  - guests/freebsd: Mounting NFS folders works. [GH-2400]
  - guests/freebsd: Uses `sh` by default for shell. [GH-2485]
  - guests/linux: upstart events listening for `vagrant-mounted` won't
    wait for jobs to complete, fixing issues with blocking during
    vagrant up [GH-2564]
  - guests/redhat: `DHCP_HOSTNAME` is set to the hostname, not the FQDN. [GH-2441]
  - guests/redhat: Down interface before messing up configuration file
    for networking. [GH-1577]
  - guests/ubuntu: "localhost" is preserved when changing hostnames.
    [GH-2383]
  - hosts/bsd: Don't set mapall if maproot is set in NFS. [GH-2448]
  - hosts/gentoo: Support systemd for NFS startup. [GH-2382]
  - providers/virtualbox: Don't start new VM if VirtualBox has transient
    failure during `up` from suspended. [GH-2479]
  - provisioners/chef: Chef client encrypted data bag secrets are now
    uploaded to the provisioning path to avoid perm issues. [GH-1246]
  - provisioners/chef: Create/chown the cache and backup folders. [GH-2281]
  - provisioners/chef: Verify environment paths exist in config
    validation step. [GH-2381]
  - provisioners/puppet: Multiple puppet definitions in a Vagrantfile
    work correctly.
  - provisioners/salt: Bootstrap on FreeBSD systems work. [GH-2525]
  - provisioners/salt: Extra args for bootstrap are put in the proper
    location. [GH-2558]

## 1.3.5 (October 15, 2013)

FEATURES:

  - VirtualBox 4.3 is now supported. [GH-2374]
  - ESXi is now a supported guest OS. [GH-2347]

IMPROVEMENTS:

  - guests/redhat: Oracle Linux is now supported. [GH-2329]
  - provisioners/salt: Support running overstate. [GH-2313]

BUG FIXES:

  - core: Fix some places where "no error message" errors were being
    reported when in fact there were errors. [GH-2328]
  - core: Disallow hyphens or periods for starting hostnames. [GH-2358]
  - guests/ubuntu: Setting hostname works properly. [GH-2334]
  - providers/virtualbox: Retryable VBoxManage commands are properly
    retried. [GH-2365]
  - provisioners/ansible: Verbosity won't be blank by default. [GH-2320]
  - provisioners/chef: Fix exception raised during Chef client node
    cleanup. [GH-2345]
  - provisioners/salt: Correct master seed file name. [GH-2359]

## 1.3.4 (October 2, 2013)

FEATURES:

  - provisioners/shell: Specify the `binary` option as true and Vagrant won't
    automatically replace Windows line endings with Unix ones.  [GH-2235]

IMPROVEMENTS:

  - guests/suse: Support installing CFEngine. [GH-2273]

BUG FIXES:

  - core: Don't output `\e[0K` anymore on Windows. [GH-2246]
  - core: Only modify `DYLD_LIBRARY_PATH` on Mac when executing commands
    in the installer context. [GH-2231]
  - core: Clear `DYLD_LIBRARY_PATH` on Mac if the subprocess is executing
    a setuid or setgid script. [GH-2243]
  - core: Defined action hook names can be strings now. They are converted
    to symbols internally.
  - guests/debian: FQDN is properly set when setting the hostname. [GH-2254]
  - guests/linux: Fix poor chown command for mounting VirtualBox folders.
  - guests/linux: Don't raise exception right away if mounting fails, allow
    retries. [GH-2234]
  - guests/redhat: Changing hostname changes DHCP_HOSTNAME. [GH-2267]
  - hosts/arch: Vagrant won't crash on Arch anymore. [GH-2233]
  - provisioners/ansible: Extra vars are converted to strings. [GH-2244]
  - provisioners/ansible: Output will show up on a task-by-task basis. [GH-2194]
  - provisioners/chef: Propagate disabling color if Vagrant has no color
    enabled. [GH-2246]
  - provisioners/chef: Delete from chef server exception fixed. [GH-2300]
  - provisioners/puppet: Work with restrictive umask. [GH-2241]
  - provisioners/salt: Remove bootstrap definition file on each run in
    order to avoid permissions issues. [GH-2290]

## 1.3.3 (September 18, 2013)

BUG FIXES:

  - core: Fix issues with dynamic linker not finding symbols on OS X. [GH-2219]
  - core: Properly clean up machine directories on destroy. [GH-2223]
  - core: Add a timeout to waiting for SSH connection and server headers
    on SSH. [GH-2226]

## 1.3.2 (September 17, 2013)

IMPROVEMENTS:

  - provisioners/ansible: Support more verbosity levels, better documentation.
    [GH-2153]
  - provisioners/ansible: Add `host_key_checking` configuration. [GH-2203]

BUG FIXES:

  - core: Report the proper invalid state when waiting for the guest machine
    to be ready
  - core: `Guest#capability?` now works with strings as well
  - core: Fix NoMethodError in the new `Vagrant.has_plugin?` method [GH-2189]
  - core: Convert forwarded port parameters to integers. [GH-2173]
  - core: Don't spike CPU to 100% while waiting for machine to boot. [GH-2163]
  - core: Increase timeout for individual SSH connection to 60 seconds. [GH-2163]
  - core: Call realpath after creating directory so NFS directory creation
    works. [GH-2196]
  - core: Don't try to be clever about deleting the machine state
    directory anymore. Manually done in destroy actions. [GH-2201]
  - core: Find the root Vagrantfile only if Vagrantfile is a file, not
    a directory. [GH-2216]
  - guests/linux: Try `id -g` in addition to `getent` for mounting
    VirtualBox shared folders [GH-2197]
  - hosts/arch: NFS exporting works properly, no exceptions. [GH-2161]
  - hosts/bsd: Use only `sudo` for writing NFS exports. This lets NFS
    exports work if you have sudo privs but not `su`. [GH-2191]
  - hosts/fedora: Fix host detection encoding issues. [GH-1977]
  - hosts/linux: Fix NFS export problems with `no_subtree_check`. [GH-2156]
  - installer/mac: Vagrant works properly when a library conflicts from
    homebrew. [GH-2188]
  - installer/mac: deb/rpm packages now have an epoch of 1 so that new
    installers don't appear older. [GH-2179]
  - provisioners/ansible: Default output level is now verbose again. [GH-2194]
  - providers/virtualbox: Fix an issue where destroy middlewares weren't
    being properly called. [GH-2200]

## 1.3.1 (September 6, 2013)

BUG FIXES:

  - core: Fix various issues where using the same options hash in a
    Vagrantfile can cause errors.
  - core: `VAGRANT_VAGRANTFILE` env var only applies to the project
    Vagrantfile name. [GH-2130]
  - core: Fix an issue where the data directory would be deleted too
    quickly in a multi-VM environment.
  - core: Handle the case where we get an EACCES cleaning up the .vagrant
    directory.
  - core: Fix exception on upgrade warnings from V1 to V2. [GH-2142]
  - guests/coreos: Proper IP detection. [GH-2146]
  - hosts/linux: NFS exporting works properly again. [GH-2137]
  - provisioners/chef: Work even with restrictive umask on user. [GH-2121]
  - provisioners/chef: Fix environment validation to be less restrictive.
  - provisioners/puppet: No more "shared folders cannot be found" error.
    [GH-2134]
  - provisioners/puppet: Work with restrictive umask on user by testing
    for folders with sudo. [GH-2121]

## 1.3.0 (September 5, 2013)

BACKWARDS INCOMPATIBILITY:

  - `config.ssh.max_tries` is gone. Instead of maximum tries, Vagrant now
    uses a simple overall timeout value `config.vm.boot_timeout` to wait for
    the machine to boot up.
  - `config.vm.graceful_halt_retry_*` settings are gone. Instead, a single
    timeout is now used to wait for a graceful halt to work, specified
    by `config.vm.graceful_halt_timeout`.
  - The ':extra' flag to shared folders for specifying arbitrary mount
    options has been replaced with the `:mount_options` flag, which is now
    an array of mount options.
  - `vagrant up` will now only run provisioning by default the first time
   it is run. Subsequent `reload` or `up` will need to explicitly specify
   the `--provision` flag to provision. [GH-1776]

FEATURES:

  - New command: `vagrant plugin update` to update specific installed plugins.
  - New provisioner: File provisioner. [GH-2112]
  - New provisioner: Salt provisioner. [GH-1626]
  - New guest: Mac OS X guest support. [GH-1914]
  - New guest: CoreOS guest support. Change host names and configure networks on
    CoreOS. [GH-2022]
  - New guest: Solaris 11 guest support. [GH-2052]
  - Support for environments in the Chef-solo provisioner. [GH-1915]
  - Provisioners can now define "cleanup" tasks that are executed on
    `vagrant destroy`. [GH-1302]
  - Chef Client provisioner will now clean up the node/client using
    `knife` if configured to do so.
  - `vagrant up` has a `--no-destroy-on-error` flag that will not destroy
    the VM if a fatal error occurs. [GH-2011]
  - NFS: Arbitrary mount options can be specified using the
   `mount_options` option on synced folders. [GH-1029]
  - NFS: Arbitrary export options can be specified using
   `bsd__nfs_options` and `linux__nfs_options`. [GH-1029]
  - Static IP can now be set on public networks. [GH-1745]
  - Add `Vagrant.has_plugin?` method for use in Vagrantfile to check
    if a plugin is installed. [GH-1736]
  - Support for remote shell provisioning scripts [GH-1787]

IMPROVEMENTS:

  - core: add `--color` to any Vagrant command to FORCE color output. [GH-2027]
  - core: "config.vm.host_name" works again, just an alias to hostname.
  - core: Reboots via SSH are now handled gracefully (without exception).
  - core: Mark `disabled` as true on forwarded port to disable. [GH-1922]
  - core: NFS exports are now namespaced by user ID, so pruning NFS won't
    remove exports from other users. [GH-1511]
  - core: "vagrant -v" no longer loads the Vagrantfile
  - commands/box/remove: Fix stack trace that happens if no provider
    is specified. [GH-2100]
  - commands/plugin/install: Post install message of a plugin will be
    shown if available. [GH-1986]
  - commands/status: cosmetic improvement to better align names and
    statuses [GH-2016]
  - communicators/ssh: Support a proxy_command. [GH-1537]
  - guests/openbsd: support configuring networks, changing host name,
    and mounting NFS. [GH-2086]
  - guests/suse: Supports private/public networks. [GH-1689]
  - hosts/fedora: Support RHEL as a host. [GH-2088]
  - providers/virtualbox: "post-boot" customizations will run directly
    after boot, and before waiting for SSH. [GH-2048]
  - provisioners/ansible: Many more configuration options. [GH-1697]
  - provisioners/ansible: Ansible `inventory_path` can be a directory now. [GH-2035]
  - provisioners/ansible: Extra verbose option by setting `config.verbose`
    to `extra`. [GH-1979]
  - provisioners/ansible: `inventory_path` will be auto-generated if not
    specified. [GH-1907]
  - provisioners/puppet: Add `nfs` option to puppet provisioner. [GH-1308]
  - provisioners/shell: Set the `privileged` option to false to run
    without sudo. [GH-1370]

BUG FIXES:

  - core: Clean up ".vagrant" folder more effectively.
  - core: strip newlines off of ID file values [GH-2024]
  - core: Multiple forwarded ports with different protocols but the same
    host port can be specified. [GH-2059]
  - core: `:nic_type` option for private networks is respected. [GH-1704]
  - commands/up: provision-with validates the provisioners given. [GH-1957]
  - guests/arch: use systemd way of setting host names. [GH-2041]
  - guests/debian: Force bring up eth0. Fixes hangs on setting hostname.
   [GH-2026]
  - guests/ubuntu: upstart events are properly emitted again. [GH-1717]
  - hosts/bsd: Nicer error if can't read NFS exports. [GH-2038]
  - hosts/fedora: properly detect later CentOS versions. [GH-2008]
  - providers/virtualbox: VirtualBox 4.2 now supports up to 36
    network adapters. [GH-1886]
  - provisioners/ansible: Execute ansible with a cwd equal to the
    path where the Vagrantfile is. [GH-2051]
  - provisioners/all: invalid config keys will be properly reported. [GH-2117]
  - provisioners/ansible: No longer report failure on every run. [GH-2007]
  - provisioners/ansible: Properly handle extra vars with spaces. [GH-1984]
  - provisioners/chef: Formatter option works properly. [GH-2058]
  - provisioners/chef: Create/chown the provisioning folder before
    reading contents. [GH-2121]
  - provisioners/puppet: mount synced folders as root to avoid weirdness
  - provisioners/puppet: Run from the correct working directory. [GH-1967]
    with Puppet. [GH-2015]
  - providers/virtualbox: Use `getent` to get the group ID instead of
    `id` in case the name doesn't have a user. [GH-1801]
  - providers/virtualbox: Will only set the default name of the VM on
    initial `up`. [GH-1817]

## 1.2.7 (July 28, 2013)

BUG FIXES:

  - On Windows, properly convert synced folder host path to a string
    so that separator replacement works properly.
  - Use `--color=false` for no color in Puppet to support older
    versions properly. [GH-2000]
  - Make sure the hostname configuration is a string. [GH-1999]
  - cURL downloads now contain a user agent which fixes some
    issues with downloading Vagrant through proxies. [GH-2003]
  - `vagrant plugin install` will now always properly show the actual
    installed gem name. [GH-1834]

## 1.2.6 (July 26, 2013)

BUG FIXES:

  - Box collections with multiple formats work properly by converting
    the supported formats to symbols. [GH-1990]

## 1.2.5 (July 26, 2013)

FEATURES:

  - `vagrant help <command>` now works. [GH-1578]
  - Added `config.vm.box_download_insecure` to allow the box_url setting
    to point to an https site that won't be validated. [GH-1712]
  - VirtualBox VBoxManage customizations can now be specified to run
    pre-boot (the default and existing functionality, pre-import,
    or post-boot. [GH-1247]
  - VirtualBox no longer destroys unused network interfaces by default.
    This didn't work across multi-user systems and required admin privileges
    on Windows, so it has been disabled by default. It can be enabled using
    the VirtualBox provider-specific `destroy_unused_network_interfaces`
    configuration by setting it to true. [GH-1324]

IMPROVEMENTS:

  - Remote commands that fail will now show the stdout/stderr of the
    command that failed. [GH-1203]
  - Puppet will run without color if the UI is not colored. [GH-1344]
  - Chef supports the "formatter" configuration for setting the
    formatter. [GH-1250]
  - VAGRANT_DOTFILE_PATH environmental variable reintroduces the
    functionality removed in 1.1 from "config.dotfile_name" [GH-1524]
  - Vagrant will show an error if VirtualBox 4.2.14 is running.
  - Added provider to BoxNotFound error message. [GH-1692]
  - If Ansible fails to run properly, show an error message. [GH-1699]
  - Adding a box with the `--provider` flag will now allow a box for
    any of that provider's supported formats.
  - NFS mounts enable UDP by default, resulting in higher performance.
    (Because mount is over local network, packet loss is not an issue)
   [GH-1706]

BUG FIXES:

  - `box_url` now handles the case where the provider doesn't perfectly
    match the provider in use, but the provider supports it. [GH-1752]
  - Fix uninitialized constant error when configuring Arch Linux network. [GH-1734]
  - Debian/Ubuntu change hostname works properly if eth0 is configured
    with hot-plugging. [GH-1929]
  - NFS exports with improper casing on Mac OS X work properly. [GH-1202]
  - Shared folders overriding '/vagrant' in multi-VM environments no
    longer all just use the last value. [GH-1935]
  - NFS export fsid's are now 32-bit integers, rather than UUIDs. This
    lets NFS exports work with Linux kernels older than 2.6.20. [GH-1127]
  - NFS export allows access from all private networks on the VM. [GH-1204]
  - Default VirtualBox VM name now contains the machine name as defined
    in the Vagrantfile, helping differentiate multi-VM. [GH-1281]
  - NFS works properly on CentOS hosts. [GH-1394]
  - Solaris guests actually shut down properly. [GH-1506]
  - All provisioners only output newlines when the provisioner sends a
    newline. This results in the output looking a lot nicer.
  - Sharing folders works properly if ".profile" contains an echo. [GH-1677]
  - `vagrant ssh-config` IdentityFile is only wrapped in quotes if it
    contains a space. [GH-1682]
  - Shared folder target path can be a Windows path. [GH-1688]
  - Forwarded ports don't auto-correct by default, and will raise an
    error properly if they collide. [GH-1701]
  - Retry SSH on ENETUNREACH error. [GH-1732]
  - NFS is silently ignored on Windows. [GH-1748]
  - Validation so that private network static IP does not end in ".1" [GH-1750]
  - With forward agent enabled and sudo being used, Vagrant will automatically
    discover and set `SSH_AUTH_SOCK` remotely so that forward agent
    works properly despite misconfigured sudoers. [GH-1307]
  - Synced folder paths on Windows containing '\' are replaced with
    '/' internally so that they work properly.
  - Unused config objects are finalized properly. [GH-1877]
  - Private networks work with Fedora guests once again. [GH-1738]
  - Default internal encoding of strings in Vagrant is now UTF-8, allowing
    detection of Fedora to work again (which contained a UTF-8 string). [GH-1977]

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
 - Chef solo `roles_path` and `data_bags_path` can only be single paths. [GH-446]
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
  - Gentoo host only networking no longer fails if already setup. [GH-286]
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

