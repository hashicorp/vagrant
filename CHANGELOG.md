## Next version (Unreleased)

FEATURES:

- hyperv/disks: Add ability to manage virtual disks for guests ([GH-11541])

IMPROVEMENTS:

- core: Allow provisioners to be run when a communicator is not available ([GH-11579])
- core: Add `autocomplete` command that allows for install of bash or zsh autocomplete scripts ([GH-11523])
- core: Update to childprocess gem to 4.0.0 ([GH-11717])
- core: Add action to wait for cloud-init to finish running ([GH-11773])
- core: Update to net-ssh to 6.0 and net-sftp to 3.0 ([GH-11621])
- core: Optimize port in use check for faster validation ([GH-11810])
- core: Support for Ruby 2.7 ([GH-11814])
- guest/arch: Use systemd-networkd to configure networking for guests ([GH-11400])
- guest/haiku: Rsync install for rsync synced folders ([GH-11614])
- guest/solaris11: Add guest capability shell_expand_guest_path ([GH-11759])
- host/darwin: Add ability to build ISO ([GH-11694])
- hosts/linux: Add ability to build ISO ([GH-11750])
- hosts/windows: Add ability to build ISO ([GH-11750])
- providers/hyperv: Add support for SecureBootTemplate setting on import ([GH-11756])
- providers/hyperv: Add support for EnhancedSessionTransportType ([GH-11014])
- virtualbox/disks: Add ability to manage virtual dvds for guests ([GH-11613])

BUG FIXES:

- core: Ensure MapCommandOptions class is required ([GH-11629])
- core: Fix `:all` special value on triggers ([GH-11688])
- core: Ensure network addresses have a valid netmask ([GH-11679])
- core: Recover local machine metadata in global index ([GH-11656])
- core: Print CLI help message is ambiguous option provided ([GH-11746])
- core: Update how `/etc/hosts` gets updated for darwin, freebsd and openbsd ([GH-11719])
- core: Capture `[3J` escape sequence ([GH-11807])
- core: Treat empty box value as invalid ([GH-11618])
- core: Allow forwarding ports to unknown addresses ([GH-11810])
- commands/destroy: Add gracefull option to switch beween gracefully or forcefully shutting down a vm ([GH-11628])
- communicator/ssh: Raise an error for a nil exit status ([GH-11721])
- config/vm: Add option `allow_hosts_modification` to allow/disable Vagrant editing the guests `/etc/hosts` file ([GH-11565])
- config/vm: Add config option `hostname` to `config.vm.network` ([GH-11566])
- config/vm: Don't ignore NFS synced folders on Windows hosts ([GH-11631])
- host: Use regular port check for loopback addresses ([GH-11654])
- host: Allow windows and linux hosts to detach from rdp process ([GH-11732])
- host/windows: Properly register SMB password validation capability ([GH-11795])
- guests: Allow setting of hostname according to `hostname` option for multiple guests ([GH-11704])
- guest/alpine: Allow setting of hostname according to `hostname` option ([GH-11718])
- guest/esxi: Be more permissive with permissions of ssh directory ([GH-11587])
- guest/linux: Add virtual box shared folders to guest fstab ([GH-11570])
- guest/suse: Allow setting of hostname according to `hostname` option ([GH-11567])
- providers/docker: Ensure new containers don't grab existing bound ports ([GH-11602])
- providers/hyperv: Fix check for secure boot ([GH-11809])
- providers/virtualbox: Fix inability to create disk with same name across multiple guests ([GH-11767])
- provisioners/docker: Allow to specify docker image version using the `run` option ([GH-11806])
- provisioners/file: Allow creating empty folders ([GH-11805])
- provisioners/shell: Ensure Windows shell provisioner gets the correct file extension ([GH-11644])
- util/powershell: Use correct powershell executable for privileged commands ([GH-11787])

## 2.2.9 (May 07, 2020)

BUG FIXES:

- core/bundler: Properly handle plugin install with available specification ([GH-11592])
- provisioners/docker: Fix CentOS docker install and start service capabilities ([GH-11581])
- provisioners/podman: Seperate RHEL install from CentOS install ([GH-11584])

## 2.2.8 (May 04, 2020)

FEATURES:

- virtualbox/disks: Add ability to manage virtual disks for guests ([GH-11349])

IMPROVEMENTS:

- bin/vagrant: Automatically include global options within commands ([GH-11473])
- bin/vagrant: Suppress Ruby warnings when not running pre-release version ([GH-11446])
- communicator/ssh: Add support for configuring SSH connect timeout ([GH-11533])
- core: Update childprocess gem ([GH-11487])
- core: Add cli option `--no-tty` ([GH-11414])
- core: Overhaul call stack modifications implementation for hooks and triggers ([GH-11455])
- core/bundler: Cache plugin solution sets to speed up startup times ([GH-11363])
- config/vm: Add`box_download_options` config to specify extra download options for a box ([GH-11560])
- guest/alpine: Add ansible provisioner guest support ([GH-11411])
- guest/linux: Update systemd? check to use sudo ([GH-11398])
- guest/linux: Use systemd if available to halt and reboot system ([GH-11407])
- guests/linux: Mount smb folders with `mfsymlinks` option by default ([GH-11503])
- guest/redhat: Add support for SMB ([GH-11463])
- guest/windows: Rescue all regular exceptions during reboot wait ([GH-11428])
- providers/docker: Support catching container name when using podman ([GH-11356])
- provisioners/docker: Support Centos8 ([GH-11462])
- provisioners/podman: Add Podman as a provisioner ([GH-11472])
- provisioners/salt: Allow specifying python_version ([GH-11436])

BUG FIXES:

- communicators/winssh: Fix issues with Windows SSH communicator ([GH-11430])
- core/bundler: Activate vagrant specification when not active ([GH-11445])
- core/bundler: Properly resolve sets when Vagrant is in prerelease ([GH-11571])
- core/downloader: Always set `-q` flag as first option ([GH-11366])
- core/hooks: Update dynamic action hook implementation to prevent looping ([GH-11427])
- core/synced_folders: Validate type option if set ([GH-11359])
- guests/debian: Choose netplan renderer based on network configuration and installed tools ([GH-11498])
- host/darwin: Quote directories in /etc/exports ([GH-11441])
- host/linux: Ensure `/etc/exports` does not contain duplicate records ([GH-10591])
- host/windows: Check all interfaces for port conflict when host_ip: "0.0.0.0" ([GH-11454])
- providers/docker: Fix issue where Vagrant fails to remove image if it is in use ([GH-11355])
- providers/docker: Fix issue with getting correct docker image id from build output ([GH-11461])
- providers/hyperv: Prevent error when identity reference cannot be translated ([GH-11425])
- provider/hyperv: Use service id for manipulating vm integration services ([GH-11499])
- providers/virtualbox: Parse `list dhcpservers` output on VirtualBox 6.1 ([GH-11404])
- providers/virtualbox: Raise an error if guest IP ends in .1 ([GH-11500])
- provisioners/shell: Ensure windows shell provisioners always get an extension ([GH-11517])
- util/io: Fix encoding conversion errors ([GH-11571])

## 2.2.7 (January 27, 2020)

IMPROVEMENTS:

- guest/opensuse: Check for basename hostname prior to setting hostname ([GH-11170])
- host/linux: Check for modinfo in /sbin if it's not on PATH ([GH-11178])
- core: Show guest name in hostname error message ([GH-11175])
- provisioners/shell: Linux guests now support `reboot` option ([GH-11194])
- darwin/nfs: Put each NFS export on its own line ([GH-11216])
- contrib/bash: Add more completion flags to up command ([GH-11223])
- provider/virtualbox: Add VirtualBox provider support for version 6.1.x ([GH-11250])
- box/outdated: Allow to force check for box updates and ignore cached check ([GH-11231])
- guest/alpine: Update apk cache when installing rsync ([GH-11220])
- provider/virtualbox: Improve error message when machine folder is inaccessible ([GH-11239])
- provisioner/ansible_local: Add pip install method for arch guests ([GH-11265])
- communicators/winssh: Use Windows shell for `vagrant ssh -c` ([GH-11258])

BUG FIXES:

- command/snapshot/save: Fix regression that prevented snapshot of all guests in environment ([GH-11152])
- core: Update UI to properly retain newlines when adding prefix ([GH-11126])
- core: Check if box update is available locally ([GH-11188])
- core: Ensure Vagrant::Errors are loaded in file_checksum util ([GH-11183])
- cloud/publish: Improve argument handling for missing arguments to command ([GH-11184])
- core: Get latest version for current provider during outdated check ([GH-11192])
- linux/nfs: avoid adding extra newlines to /etc/exports ([GH-11201])
- guest/darwin: Fix VMware synced folders on APFS ([GH-11267])
- guest/redhat: Ensure `nfs-server` is restarted when installing nfs client ([GH-11212])
- core: Do not validate checksums if options are empty string ([GH-11211])
- provider/docker: Enhance docker build method to match against buildkit output ([GH-11205])
- provisioner/ansible_local: Don't prompt for input when installing Ansible on Ubuntu and Debian ([GH-11191])
- provisioner/ansible_local: Ensure all guest caps accept all passed in arguments ([GH-11265])
- host/windows: Fix regression that prevented port collisions from being detected ([GH-11244])
- core/provisioner: Set top level provisioner name if set in a provisioner config ([GH-11295])

## 2.2.6 (October 14, 2019)

FEATURES:

- core/provisioners: Introduce new Provisioner options: before and after ([GH-11043])
- guest/alpine: Integrate the vagrant-alpine plugin into Vagrant core ([GH-10975])

IMPROVEMENTS:

- command/box/prune: Allow prompt skip while preserving actively in use boxes ([GH-10908])
- command/cloud: Support providing checksum information with boxes ([GH-11101])
- dev: Fixed Vagrantfile for Vagrant development ([GH-11012])
- guest/alt: Improve handling for using network tools when setting hostname ([GH-11000])
- guest/suse: Add ipv6 network config templates for SUSE based distributions ([GH-11013])
- guest/windows: Retry on connection timeout errors for the reboot capability ([GH-11093])
- host/bsd: Use host resolve path capability to modify local paths if required ([GH-11108])
- host/darwin: Add host resolve path capability to provide real paths for firmlinks ([GH-11108])
- provisioners/chef: Update pkg install flags for chef on FreeBSD guests ([GH-11075])
- provider/hyperv: Improve error message when VMMS is not running ([GH-10978])
- provider/virtualbox: Raise additional errors for incomplete virtualbox installation on usable check ([GH-10938])
- util/filechecksum: Add support for more checksum types ([GH-11101])

BUG FIXES:

- command/rsync-auto: Fix path watcher bug so that all subdirectories are synced when changed ([GH-11089])
- command/snapshot/save: Ensure VM id is passed to list snapshots for hyper-v provider ([GH-11097])
- core: Ensure proper paths are shown in config loading exceptions ([GH-11056])
- guest/suse: Use hostnamectl instead of hostname to set the hostname under SUSE ([GH-11100])
- provider/docker: Fix default provider validation if password is used ([GH-11053])
- provider/docker: Fix Docker providers usable? check ([GH-11068])
- provisioner/ansible_local: Ensure pip_install_cmd is finalized to emptry string ([GH-11098])
- provisioner/file: Ensure relative path for file provisioner source is relative to guest machines cwd ([GH-11099])
- provider/docker: Ensure docker build_args option is properly set in docker compose config yaml ([GH-11106])
- guest/suse: Update nfs & service daemon names for suse based hosts and guests ([GH-11076])
- provider/docker: Determine ip address prefix workaround for docker public networks ([GH-11111])
- provider/docker: Only return interfaces where addr is not nil for networks ([GH-11116])

## 2.2.5 (June 19, 2019)

FEATURES:

- providers/docker: Private and Public networking support ([GH-10702])

IMPROVEMENTS:

- command/global-status: Provide machine-readable information ([GH-10506])
- command/snapshot: Separate snapshot names for guests when listing snapshots ([GH-10828])
- command/box/update: Ignore missing metadata files when updating all boxes ([GH-10829])
- core: Use consistent settings when unpacking boxes as root ([GH-10707])
- core: Write metadata.json file when packaging box ([GH-10706])
- core: Remove whitespace from id file on load ([GH-10727])
- core/bundler: Support resolution when installed within system ([GH-10894])
- guest/coreos:  Update network configuration and hostname setting ([GH-10752])
- guest/freebsd: Add proper VirtualBox share folders support for FreeBSD guests ([GH-10717])
- guest/freebsd: Add unmount share folder for  VirtualBox guests ([GH-10761])
- guest/freebsd: Simplify network interface listing when configuring networks ([GH-10763])
- providers/docker: Add usable? check to docker provider ([GH-10890])
- synced_folder/smb: Remove configuration information from synced folder data ([GH-10811])

BUG FIXES:

- command/box/update: Ensure the right version is picked when updating specific boxes ([GH-10810])
- command/cloud: Properly set variable from CLI argument parsing for `username` field ([GH-10726])
- command/rsync_auto: Use relative paths to machines folder path for file path Listener ([GH-10902])
- communicator/ssh: Remove net/sftp loading to prevent loading errors ([GH-10745])
- contrib/bash: Search for running_vm_list only in `machines` folder ([GH-10841])
- core/bundler: Properly parse multiple constants when installing plugins ([GH-10896])
- core/environment: Support plugin configuration within box Vagrantfiles ([GH-10889])
- core/triggers: Fix typo in UI output ([GH-10748])
- core/triggers: Properly exit with abort option ([GH-10824])
- core/triggers: Ensure guest names are string when filtering trigger configs ([GH-10854])
- core/triggers: Abort after all running processes have completed when parallel is enabled ([GH-10891])
- guest/void: Fix NFS capability detection ([GH-10713])
- guest/bsd: Properly set BSD options order for /etc/exports ([GH-10909])
- host/windows: Fix rubygems error when host has directory named `c` ([GH-10803])
- provider/virtualbox: Ensure non-existent machines do not attempt to list snapshots ([GH-10784])
- provider/docker: Properly set docker-compose config file with volume names ([GH-10820])
- provisioner/ansible: Fix pip installer hardcoded curl get_pip.py piped to python ([GH-10625])
- provisioner/chef: Update chef install check for guests ([GH-10917])
- synced_folders/rsync: Remove rsync__excludes from command if array is empty ([GH-10901])

## 2.2.4 (February 27, 2019)

FEATURES:

- core/triggers: Introduce new option `:type` for actions, hooks, and commands ([GH-10615])

IMPROVEMENTS:

- communicator/ssh: Update `#upload` behavior to work properly with new sshd path checks ([GH-10698])
- communicator/winrm: Update `#upload` behavior to match ssh communicator upload behavior ([GH-10698])
- guest/windows: Add reboot output to guest capability ([GH-10638])
- provisioner/file: Refactor path modification rules and allow communicator to handle details ([GH-10698])

BUG FIXES:

- core: Fix format finalization of plugins in Vagrantfile ([GH-10664])
- core: Fix SIGINT behavior and prevent backtrace ([GH-10666])
- core: Change remaining box_client_cert refs to box_download_client_cert ([GH-10622])
- core: Move over AddAuthentication middleware and hooks  out of deprecated class ([GH-10686])
- guest/debian: Properly set DHCP for systemd-networkd ips ([GH-10586])
- guest/solaris11: Create interface if required before configuration ([GH-10595])
- installers/appimage: Use ld path with appimage libs on suffix ([GH-10647])
- providers/docker: Expand paths when comparing synced folders on reload ([GH-10645])
- providers/virtualbox: Fix import paths on Windows with VirtualBox 6 ([GH-10629])
- synced_folders/rsync: Properly clean up tmp folder created during rsync ([GH-10690])

## 2.2.3 (January 9, 2019)

FEATURES:

- host/void: Add host support for void linux ([GH-10012])

IMPROVEMENTS:

- command/rsync-auto: Prevent crash on post-rsync command failure ([GH-10515])
- command/snapshot: Raise error for bad subcommand ([GH-10470])
- command/package: Ensure temp dir for package command is cleaned up ([GH-10479])
- command/powershell: Support running elevated commands ([GH-10528])
- communicator/ssh: Add `config` and `remote_user` options ([GH-10496])
- core: Display version update on stderr instead of stdout ([GH-10482])
- core: Add experimental feature flag ([GH-10485])
- core: Show box version during box outdated check ([GH-10573])
- guest/windows: Modify elevated username only on username failure ([GH-10488])
- host/windows: Prevent SMB setup commands from becoming too long ([GH-10489])
- host/windows: Automatically answer yes when pruning SMB shares ([GH-10524])
- provisioners/file: Show source and destination locations with file provisioner ([GH-10570])
- provisioners/salt: Validate that `install_type` is set if `version` is specified ([GH-10474])
- provisioners/salt: Update default install version ([GH-10537])
- provisioners/shell: Add `reboot` option for rebooting supported guest ([GH-10532])
- synced_folders/rsync: Support using rsync `--chown` option ([GH-10529])
- util/guest_inspection: Validate hostnamectl command works when detected ([GH-10512])
- util/platform: Use wslpath command for customized root on WSL ([GH-10574])

BUG FIXES:

- command/cloud publish: Ensure box file exists before path expanding ([GH-10468])
- command/cloud publish: Catch InvalidVersion errors from vagrant_cloud client ([GH-10513])
- command/snapshot: Retain consistent provisioning behavior across all commands ([GH-10490])
- command/validate: Bypass install checks for validating configs with the `--ignore-provider` flag ([GH-10467])
- communicator/ssh: Fix garbage output detection ([GH-10571])
- guest/alt: Fix network configuration errors ([GH-10527])
- guest/coreos: Fix grep command for network interface of CoreOS guest ([GH-10554])
- guest/freebsd: Fix defaultrouter rcvar in static network template ([GH-10469])
- guest/redhat: Fix network configuration errors ([GH-10527])
- providers/virtualbox: Adjust version requirement for NIC warning ([GH-10486])
- util/powershell: Use correct Base64 encoding for encoded commands ([GH-10487])

## 2.2.2 (November 27, 2018)

BUG FIXES:

- providers/virtualbox: Update default_nic_type implementation and add warning ([GH-10450])

## 2.2.1 (November 15, 2018)

FEATURES:

- core/plugins: Add reset! method to communicator ([GH-10399])
- providers/virtualbox: Add support for VirtualBox 6.0 ([GH-10379])

IMPROVEMENTS:

- command/validate: Allow validation of config while ignoring provider ([GH-10351])
- communicators/ssh: Prevent overly verbose output waiting for connection ([GH-10321])
- communicators/ssh: Support ed25519 keys ([GH-10365])
- communicators/ssh: Add reset! implementation ([GH-10399])
- communicators/winrm: Add reset! implementation ([GH-10399])
- core: Limit number of automatic box update checks ([GH-10359])
- host/windows: Remove PATH check in WSL detection ([GH-10313])
- providers/hyperv: Disable automatic checkpoints before deletion ([GH-10406])
- providers/virtualbox: Add `automount` flag if specified with synced_folder ([GH-10326])
- providers/virtualbox: Refactor host only network settings ([GH-7699])
- providers/virtualbox: Support setting default NIC type for network adapters ([GH-10383])
- providers/virtualbox: Update ssh_port helper to handle multiple matches ([GH-10409])
- provisioners/shell: Add :reset option to allow communicator reset ([GH-10399])
- synced_folders/smb: Allow for 'default' smb_username in prompt if set ([GH-10319])
- util/network_ip: Simplify `network_address` helper ([GH-7693])
- util/platform: Prevent hard failure during hyper-v enabled check ([GH-10332])

BUG FIXES:

- command/login: Only show deprecation warning when command is invoked ([GH-10374])
- core: Fallback to Vagrantfile defined box information ([GH-10368])
- core/bundler: Update source ordering to properly resolve with new RubyGems ([GH-10364])
- core/triggers: Only split inline script if host is non-Windows ([GH-10405])
- communicator/winrm: Prepend computer name to username when running elevated commands ([GH-10387])
- guest/debian: Fix halting issue when setting hostname by restarting networking on guest [GH-10301, GH-10330]
- guest/linux: Fix vagrant user access to docker after install ([GH-10399])
- guest/windows: Add reboot capability to fix hostname race condition ([GH-10347])
- guest/windows: Allow for reading key paths with spaces ([GH-10389])
- host/windows: Fix powershell to properly handle paths with spaces ([GH-10390])
- providers/docker: Deterministic host VM synced folder location for Docker VM ([GH-10311])
- providers/hyperv: Fix network vlan configuration script ([GH-10366])
- providers/hyperv: Properly output error message on failed guest import ([GH-10404])
- providers/hyperv: Fix typo in network configuration detection script ([GH-10410])

## 2.2.0 (October 16, 2018)

FEATURES:

- command/cloud: Introduce `vagrant cloud` subcommand to Vagrant ([GH-10148])
- command/upload: Add command for uploading files to guest ([GH-10263])
- command/winrm: Add command for executing guest commands via WinRM ([GH-10263])
- command/winrm-config: Add command for providing WinRM configuration ([GH-10263])

IMPROVEMENTS:

- core: Ensure file paths are identical when checking for cwd ([GH-10220])
- core: Add config option `ignore_box_vagrantfile` for ignoring vagrantfile inside box ([GH-10242])
- core/triggers: Add abort option to core triggers ([GH-10232])
- core/triggers: Introduce `ruby` option for trigger ([GH-10267])
- contrib/bash: Add completion for snapshot names for vagrant snapshot restore|delete ([GH-9054])
- providers/docker: Build docker from git repo ([GH-10221])
- providers/hyperv: Update Hyper-V admin check and allow override via ENV variable ([GH-10275])
- providers/virtualbox: Allow base_mac to be optional ([GH-10255])
- provisioners/salt: bootstrap-salt.sh: use -s with curl ([GH-9432])
- provisioners/salt: remove leading space with bootstrap_options ([GH-9431])

BUG FIXES:

- core/environment: Provide rgloader for local plugin installations ([GH-10279])
- contrib/sudoers/osx: Fix missing comma and add remove export alias ([GH-10235])
- guest/redhat: Update restart logic in redhat change_host_name cap ([GH-10223])
- guest/windows: Allow special characters in SMB password field ([GH-10219])
- providers/hyperv: Only use AutomaticCheckpointsEnabled when available ([GH-10264])
- providers/hyperv: Only use CheckpointType when available ([GH-10265])
- provisioners/ansible: Fix remote directory creation [GH-10259, GH-10258]
- provisioners/puppet: Properly set env variables for puppet provisioner on windows ([GH-10218])
- provisioners/salt: Properly set salt pillar variables for windows guests ([GH-10215])
- synced_folders/rsync: Ensure unique tmp dirs for ControlPath with rsync ([GH-10291])

## 2.1.5 (September 12, 2018)

IMPROVEMENTS:

- core: Add `Vagrant.version?` helper method ([GH-10191])
- core: Scrub sensitive values from logger output ([GH-10200])
- core: Prevent multiple evaluations of Vagrantfile ([GH-10199])
- command/init: Support VAGRANT_DEFAULT_TEMPLATE env var ([GH-10171])
- command/powershell: Improve doc help string and fix winrm locales error ([GH-10189])
- contrib/bash: autocomplete running VM names for destroy subcommand ([GH-10168])
- guest/debian: Use `sudo` to determine if systemd is in use for hardened systems ([GH-10198])
- guest/openbsd: Add IPv6 network template for OpenBSD machines ([GH-8912])
- provisioners/salt: Allow non-windows hosts to pass along version ([GH-10194])

BUG FIXES:

- core: Fix Vagrant.has_plugin? behavior before plugins are initialized ([GH-10165])
- core: Check verify_host_key for falsey or :never values when generating ssh config ([GH-10182])
- guest/linux: Filter out empty strings and loopback interfaces when constructing list of network interfaces ([GH-10092])
- provider/hyper-v: Check for automatic checkpoint support before configuring ([GH-10181])

## 2.1.4 (August 30, 2018)

BUG FIXES:

- core: Fix local plugin installation prompt answer parsing ([GH-10154])
- core: Reset internal environment after plugin loading ([GH-10155])
- host/windows: Fix SMB list parsing when extra fields are included ([GH-10156])
- provisioners/ansible_local: Fix umask setting permission bug ([GH-10140])

## 2.1.3 (August 29, 2018)

FEATURES:

- core: Support for project specific plugins ([GH-10037])

IMPROVEMENTS:

- command/reload: Add `--force` flag to reload command ([GH-10123])
- communicator/winrm: Display warning if vagrant-winrm plugin is detected ([GH-10076])
- contrib/bash: Replace -VAGRANTSLASH- with literal slash in completion ([GH-9987])
- core: Show installed version of Vagrant when displaying version check ([GH-9968])
- core: Retain information of original box backing active guest ([GH-10083])
- core: Only write box info if provider supports box objects ([GH-10126])
- core: Update net-ssh dependency constraint to ~> 5.0.0 ([GH-10066])
- core/triggers: Catch and allow for non-standard exit codes with triggers `run` options ([GH-10005])
- core/triggers: Allow for spaces in `path` for trigger run option ([GH-10118])
- guest/debian: Isolate network interface configuration to individual files for systemd ([GH-9889])
- guest/redhat: Use libnfs-utils package if available ([GH-9878])
- provider/docker: Support Docker volume consistency for synced folders ([GH-9811])
- provider/hyperv: Disable synced folders on non-DrvFs file systems by default ([GH-10001])
- util/downloader: Support custom suffix on user agent string ([GH-9966])
- util/downloader: Prevent false positive matches on Location header ([GH-10041])
- util/subprocess: Force system library paths for executables external to AppImage ([GH-10078])

BUG FIXES:

- core: Disable Vagrantfile loading with plugin commands ([GH-10030])
- core: Ensure the SecureRandom library is loaded for the trigger class ([GH-10063])
- core/triggers: Allow trigger run args option to be a single string ([GH-10116])
- util/powershell: Properly `join` commands from passed in array ([GH-10115])
- guest/solaris: Add back guest detection check for Solaris derived guests ([GH-10081])
- guest/windows: Be more explicit when invoking cmd.exe with mount_volume script ([GH-9976])
- host/linux: Fix sudo usage in NFS capability when modifying exports file ([GH-10084])
- host/windows: Remove localization dependency from SMB list generation ([GH-10043])
- provider/docker: Convert windows paths for volume mounts on docker driver ([GH-10100])
- provider/hyperv: Fix checkpoint configuration and properly disable automatic checkpoints by default ([GH-9999])
- provider/hyperv: Remove localization dependency from access check ([GH-10000])
- provider/hyperv: Enable ExposeVirtualizationExtensions only when available ([GH-10079])
- provider/virtualbox: Skip link-local when fixing IPv6 route [GH-9639, GH-10077]
- push/ftp: Custom error when attempting to push too many files ([GH-9952])
- util/downloader: Prevent errors when Location header contains relative path ([GH-10017])
- util/guest_inspection: Prevent nmcli check from hanging when pty is enabled ([GH-9926])
- util/platform: Always force string type conversion on path ([GH-9998])

## 2.1.2 (June 26, 2018)

IMPROVEMENTS:

- commands/suspend: Introduce flag for suspending all machines ([GH-9829])
- commands/global-status: Improve message about removing stale entries ([GH-9856])
- provider/hyperv: Attempt to determine import failure cause ([GH-9936])
- provider/hyperv: Update implementation. Include support for modifications on reload ([GH-9872])
- provider/hyperv: Validate maxmemory configuration setting ([GH-9932])
- provider/hyperv: Enable provider within WSL ([GH-9943])
- provider/hyperv: Add Hyper-V accessibility check on data directory path ([GH-9944])
- provisioners/ansible_local: Improve installation from PPA on Ubuntu guests.
    The compatibility is maintained only for active long-term support (LTS) versions,
    i.e. Ubuntu 12.04 (Precise Pangolin) is no longer supported. ([GH-9879])

BUG FIXES:

- communicator/ssh: Update ssh private key file permission handling on Windows [GH-9923, GH-9900]
- core: Display plugin commands in help ([GH-9808])
- core: Ensure guestpath or name is set with synced_folder option and dont set guestpath if not provided ([GH-9692])
- guest/debian: Fix netplan generation when using DHCP ([GH-9855])
- guest/debain: Update priority of network configuration file when using networkd ([GH-9867])
- guest/ubuntu: Update netplan config generation to detect NetworkManager ([GH-9824])
- guest/ubuntu: Fix failing Ansible installation from PPA on Bionic Beaver (18.04 LTS) ([GH-9796])
- host/windows: Prevent processing of last SMB line when using net share ([GH-9917])
- provisioner/chef: Prevent node_name set on configuration with chef_apply ([GH-9916])
- provisioner/salt: Remove usage of masterless? config attribute ([GH-9833])

## 2.1.1 (May 7, 2018)

IMPROVEMENTS:

- guest/linux: Support builtin vboxsf module for shared folders ([GH-9800])
- host/windows: Update SMB capability to work without Get-SmbShare cmdlet ([GH-9785])

BUG FIXES:

- core/triggers: Initialize internal trigger object for machine before initializing provider ([GH-9784])
- core/triggers: Ensure internal trigger fire does not get called if plugin installed ([GH-9799])
- provider/hyperv: Call import script with switchid instead of switchname ([GH-9781])

## 2.1.0 (May 3, 2018)

FEATURES:

- core: Integrate vagrant-triggers plugin functionality into core Vagrant ([GH-9713])

IMPROVEMENTS:

- core: Improve messaging around not finding requested provider ([GH-9735])
- core: Disable exception reports by default ([GH-9738])
- core: Continue on if vagrant fails to parse metadata box for update ([GH-9760])
- hosts/linux: Support RDP capability within WSL ([GH-9758])
- hosts/windows: Add SMB default mount options capability and set default version to 2.0 ([GH-9734])
- provider/hyperv: Include neighbor check for MAC on guest IP detection ([GH-9737])
- provider/virtualbox: Do not require VirtualBox availability within WSL ([GH-9759])
- provisioner/chef_zero: Support arrays for data_bags_path ([GH-9669])
- util/downloader: Don't raise error if response is HTTP 416 ([GH-9729])
- util/platform: Update Hyper-V enabled check ([GH-9746])

BUG FIXES:

- communicators/ssh: Log error and proceed on Windows private key permissions ([GH-9769])
- middleware/authentication: Prevent URL modification when no changes are required ([GH-9730])
- middleware/authentication: Ignore URLs which cannot be parsed ([GH-9739])
- provider/hyperv: Reference switches by ID instead of name ([GH-9747])
- provider/docker: Use Util::SafeExec if docker-exec is run with `-t` option ([GH-9761])
- provisioner/chef: Trim drive letter from path on Windows ([GH-9766])
- provisioner/puppet: Properly finalize structured_facts config option ([GH-9720])
- util/platform: Fix original WSL to Windows path for "root" directory ([GH-9696])

## 2.0.4 (April 20, 2018)

FEATURES:

- core: Vagrant aliases ([GH-9504])

IMPROVEMENTS:

- communicators/ssh: Update file permissions when generating new key pairs ([GH-9676])
- core: Make resolv-replace usage opt-in instead of opt-out ([GH-9644])
- core: Suppress error messages from checkpoint runs ([GH-9645])
- guests/coreos: Identify operating systems closely related to CoreOS ([GH-9600])
- guests/debian: Adjust network configuration file prefix to 50- ([GH-9646])
- guests/photon: Less specific string grep to fix PhotonOS 2.0 detection ([GH-9528])
- guests/windows: Fix slow timeout when updating windows hostname ([GH-9578])
- hosts/windows: Make powershell version detection timeout configurable ([GH-9506])
- providers/virtualbox: Improve network collision error message ([GH-9685])
- provisioner/chef_solo: Improve Windows drive letter removal hack for remote paths([GH-9490])
- provisioner/chef_zero: File path expand all chef_zero config path options ([GH-9690])
- provisioner/puppet: Puppet structured facts toyaml on provisioner ([GH-9670])
- provisioner/salt: Add master_json_config & minion_json_config options ([GH-9420])
- util/platform: Warn on ArgumentError exceptions from encoding ([GH-9506])

BUG FIXES:

- commands/package: Fix uninitialized constant error ([GH-9654])
- communicators/winrm: Fix command filter to properly parse commands ([GH-9673])
- hosts/windows: Properly respect the VAGRANT_PREFER_SYSTEM_BIN environment variable ([GH-9503])
- hosts/windows: Fix virtualbox shared folders path for windows guests ([GH-8099])
- guests/freebsd: Fix typo in command that manages configuring networks ([GH-9705])
- util/checkpoint_client: Respect VAGRANT_CHECKPOINT_DISABLE environment variable ([GH-9659])
- util/platform: Use `--version` instead of `version` for WSL validation ([GH-9674])

## 2.0.3 (March 15, 2018)

IMPROVEMENTS:

  - guests/solaris: More explicit Solaris 11 and inherit SmartOS from Solaris ([GH-9398])
  - hosts/windows: Add support for latest WSL release [GH-9525, GH-9300]
  - plugins/login: Update middleware to re-map hosts and warn on custom server ([GH-9499])
  - providers/hyper-v: Exit if Hyper-V is enabled and VirtualBox provider is used ([GH-9456])
  - provisioners/salt: Change to a temporary directory before downloading script files ([GH-9351])
  - sycned_folders/nfs: Default udp to false when using version 4 ([GH-8828])
  - util/downloader: Notify on host redirect ([GH-9344])

BUG FIXES:

  - core: Use provider override when specifying box_version ([GH-9502])
  - guests/debian: Renew DHCP lease on hostname change ([GH-9405])
  - guests/debian: Point hostname to 127.0.1.1 in /etc/hosts ([GH-9404])
  - guests/debian: Update systemd? check for guest inspection ([GH-9459])
  - guests/debian: Use ip route in dhcp template ([GH-8730])
  - guests/gentoo: Disable if/netplugd when setting up a static ip on a gentoo guest using openrc ([GH-9261])
  - guests/openbsd: Atomically apply new hostname.if(5) ([GH-9265])
  - hosts/windows: Fix halt problem when determining powershell version on old powershells ([GH-9470])
  - hosts/windows: Convert to windows path if on WSL during vbox export ([GH-9518])
  - providers/virtualbox: Fix hostonly matching not respecting :name argument ([GH-9302])
  - util/credential_scrubber: Ignore empty strings [GH-9472, GH-9462]

## 2.0.2 (January 29, 2018)

FEATURES:

  - core: Provide mechanism for removing sensitive data from output ([GH-9276])
  - core: Relax Ruby constraints to include 2.5 ([GH-9363])
  - core: Hide sensitive values in output ([GH-9369])
  - command/init: Support custom Vagrantfile templates ([GH-9202])
  - guests: Add support for the Haiku operating system [GH-7805, GH-9245]
  - synced_folders/smb: Add support for macOS hosts ([GH-9294])
  - vagrant-spec: Update vagrant-spec to include Windows platforms and updated linux boxes ([GH-9183])

IMPROVEMENTS:

  - config/ssh: Deprecate :paranoid in favor of :verify_host_key ([GH-9341])
  - core: Add optional timestamp prefix on log output ([GH-9269])
  - core: Print more helpful error message for NameEror exceptions in Vagrantfiles ([GH-9252])
  - core: Update checkpoint implementation to announce updates and support notifications ([GH-9380])
  - core: Use Ruby's Resolv by default ([GH-9394])
  - docs: Include virtualbox 5.2.x as supported in docs ([GH-9237])
  - docs: Improve how to pipe debug log on powershell ([GH-9330])
  - guests/amazon: Improve guest detection ([GH-9307])
  - guests/debian: Update guest configure networks ([GH-9338])
  - guests/dragonflybsd: Base guest on FreeBSD to inherit more functionality ([GH-9205])
  - guests/linux: Improve NFS service name detection and interactions ([GH-9274])
  - guests/linux: Support mount option overrides for SMB mounts ([GH-9366])
  - guests/linux: Use `ip` for reading guest address if available ([GH-9315])
  - guests/solaris: Improve guest detection for alternatives ([GH-9295])
  - hosts/windows: Check credentials during SMB prepare ([GH-9365])
  - providers/hyper-v: Ensure Hyper-V cmdlets are fully qualified ([GH-8863])
  - middleware/authentication: Add app.vagrantup.com to allowed hosts ([GH-9145])
  - provisioners/shell: Support hiding environment variable values in output ([GH-9367])
  - providers/virtualbox: Add a clean error message for invalid IP addresses ([GH-9275])
  - providers/virtualbox: Introduce flag for SharedFoldersEnableSymlinksCreate setting ([GH-9354])
  - providers/virtualbox: Provide warning for SharedFoldersEnableSymlinksCreate setting ([GH-9389])
  - provisioners/salt: Fixes timeout issue in salt bootstrapping for windows ([GH-8992])
  - synced_folders/smb: Update Windows implementation ([GH-9294])
  - util/ssh: Attempt to locate local ssh client before attempting installer provided ([GH-9400])

BUG FIXES:

  - commands/box: Show all box providers with `update outdated --global` ([GH-9347])
  - commands/destroy: Exit 0 if vagrant destroy finds no running vms ([GH-9251])
  - commands/package: Fix --output path with specified folder ([GH-9131])
  - guests/suse: Do not use full name when setting hostname ([GH-9212])
  - providers/hyper-v: Fix enable virtualization extensions on import ([GH-9255])
  - provisioners/ansible(both): Fix broken 'ask_sudo_pass' option ([GH-9173])

## 2.0.1 (November 2, 2017)

FEATURES:

  - core: Introduce Ruby 2.4 to Vagrant ([GH-9102])
  - providers/virtualbox: Virtualbox 5.2 support ([GH-8955])

IMPROVEMENTS:

  - command/destroy: Introduce parallel destroy for certain providers ([GH-9127])
  - communicators/winrm: Include APIPA check within ready check ([GH-8997])
  - core: Clear POSIXLY_CORRECT when using optparse ([GH-8685])
  - docs: Add auto_start_action and auto_stop_action to docs. ([GH-9029])
  - docs: Fix typo in box format doc ([GH-9100])
  - provisioners/chef: Handle chef provisioner reboot request ([GH-8874])
  - providers/salt: Support Windows Salt Minions greater than 2016.x.x ([GH-8926])
  - provisioners/salt: Add wget to bootstrap_salt options when fetching installer file ([GH-9112])
  - provisioners/shell: Use ui.detail for displaying output ([GH-8983])
  - util/downloader: Use CURL_CA_BUNDLE environment variable ([GH-9135])

BUG FIXES:

  - communicators/ssh: Retry on Errno::EPIPE exceptions ([GH-9065])
  - core: Rescue more exceptions when checking if port is open ([GH-8517])
  - guests/solaris11: Inherit from Solaris guest and keep solaris11 specific methods ([GH-9034])
  - guests/windows: Split out cygwin path helper for msys2/cygwin paths and ensure cygpath exists ([GH-8972])
  - guests/windows: Specify expected shell when executing on guest (fixes einssh communicator usage) ([GH-9012])
  - guests/windows: Include WinSSH Communicator when using insert_public_key ([GH-9105])
  - hosts/windows: Check for vagrant.exe when validating versions within WSL [GH-9107, GH-8962]
  - providers/docker: Isolate windows check within executor to handle running through VM ([GH-8921])
  - providers/hyper-v: Properly invoke Auto stop action ([GH-9000])
  - provisioners/puppet: Fix winssh communicator support in puppet provisioner ([GH-9014])
  - virtualbox/synced_folders: Allow synced folders to contain spaces in the guest path ([GH-8995])

## 2.0.0 (September 7, 2017)

IMPROVEMENTS:

  - commands/login: Add support for two-factor authentication ([GH-8935])
  - commands/ssh-config: Properly display windows path if invoked from msys2 or
      cygwin ([GH-8915])
  - guests/alt: Add support for ALT Linux ([GH-8746])
  - guests/kali: Fix file permissions on guest plugin ruby files ([GH-8950])
  - hosts/linux: Provide common systemd detection for services interaction, fix NFS
      host interactions ([GH-8938])
  - providers/salt: Remove duplicate stdout, stderr output from salt ([GH-8767])
  - providers/salt: Introduce salt_call_args and salt_args option for salt provisioner
      ([GH-8927])
  - providers/virtualbox: Improving resilience of some VirtualBox commands ([GH-8951])
  - provisioners/ansible(both): Add the compatibility_mode option, with auto-detection
      enabled by default [GH-8913, GH-6570]
  - provisioners/ansible: Add the version option to the host-based provisioner
      [GH-8913, GH-8914]
  - provisioners/ansible(both): Add the become and become_user options with deprecation
      of sudo and sudo_user options [GH-8913, GH-6570]
  - provisioners/ansible: Add the ask_become_pass option with deprecation of the
      ask_sudo_pass option [GH-8913, GH-6570]

BUG FIXES:

  - guests/shell_expand_guest_path : Properly expand guest paths that include relative
      path alias ([GH-8918])
  - hosts/linux: Remove duplicate export folders before writing /etc/exports ([GH-8945])
  - provisioners/ansible(both): Add single quotes to the inventory host variables, only
      when necessary ([GH-8597])
  - provisioners/ansible(both): Add the "all:vars" section to the inventory when defined
      in `groups` option ([GH-7730])
  - provisioners/ansible_local: Extra variables are no longer truncated when a dollar ($)
      character is present ([GH-7735])
  - provisioners/file: Align file provisioner functionality on all platforms ([GH-8939])
  - util/ssh: Properly quote key path for IdentityFile option to allow for spaces ([GH-8924])

BREAKING CHANGES:

  - Both Ansible provisioners are now capable of automatically setting the compatibility_mode that
      best fits with the Ansible version in use. You may encounter some compatibility issues when
      upgrading. If you were using Ansible 2.x and referring to the _ssh-prefixed variables present
      in the generated inventory (e.g. `ansible_ssh_host`). In this case, you can fix your Vagrant
      setup by setting compatibility_mode = "1.8", or by migrating to the new variable names (e.g.
      ansible_host).

## 1.9.8 (August 23, 2017)

IMPROVEMENTS:

  - bash: Add box prune to contrib bash completion ([GH-8806])
  - commands/login: Ask for description of Vagrant Cloud token ([GH-8876])
  - commands/validate: Improve functionality of the validate command ([GH-8889])n
  - core: Updated Vagrants rspec gem to 3.5.0 ([GH-8850])
  - core: Validate powershell availability and version before use ([GH-8839])
  - core: Introduce extra_args setting for ssh configs ([GH-8895])
  - docs: Align contrib/sudoers file for ubuntu linux with docs ([GH-8842])
  - provider/hyperv: Prefer IPv4 guest address [GH-8831, GH-8759]
  - provisioners/chef: Add config option omnibus_url for chef provisioners ([GH-8682])
  - provisioners/chef: Improve exception handling around missing folder paths ([GH-8775])

BUG FIXES:

  - box/update: Add force flag for box upgrade command ([GH-8871])
  - commands/rsync-auto: Ensure relative dirs are still rsync'd if defined ([GH-8781])
  - commands/up: Disable install providers when using global id on vagrant up ([GH-8910])
  - communicators/winssh: Fix public key insertion to retain ACL ([GH-8790])
  - core: Update util/ssh to use `-o` for identity files ([GH-8786])
  - guests/freebsd: Fix regex for listing network devices on some FreeBSD boxes. ([GH-8760])
  - hosts/windows: Prevent control characters in version check for WSL [GH-8902, GH-8901]
  - providers/docker: Split String type links into Array when using compose [GH-8837, GH-8821]
  - providers/docker: Expand relative volume paths correctly [GH-8838, GH-8822]
  - providers/docker: Error when compose option enabled with force_host_vm ([GH-8911])
  - provisioners/ansible: Update to use `-o` for identity files ([GH-8786])
  - provisioners/file: Ensure remote folder exists prior to scp file or folder ([GH-8880])
  - provisioners/salt: Fix error case when github is unreachable for installer ([GH-8864])
  - provisioners/shell: Allow frozen string scripts ([GH-8875])
  - provisioners/puppet: Remove `--manifestdir` flag from puppet apply in provisioner ([GH-8797])
  - synced_folders/rsync: Correctly format IPv6 host [GH-8840, GH-8809]

## 1.9.7 (July 7, 2017)

FEATURES:

  - core: Add support for preferred providers ([GH-8558])

IMPROVEMENTS:

  - guests/bsd: Invoke `tee` with explicit path ([GH-8740])
  - guests/smartos: Guest updates for host name and nfs capabilities ([GH-8695])
  - guests/windows: Add public key capabilities for WinSSH communicator ([GH-8761])
  - hosts/windows: Log command exec encoding failures and use original string on failure ([GH-8820])
  - providers/virtualbox: Filter machine IPs when preparing NFS settings ([GH-8819])

BUG FIXES:

  - communicators/winssh: Make script upload directory configurable ([GH-8761])
  - core: Update cygwin detection to prevent PATH related errors [GH-8749, GH-6788]
  - core: Fix URI parsing of box names to prevent errors [GH-8762, GH-8758]
  - provider/docker: Only rsync-auto current working dir with docker provider ([GH-8756])

## 1.9.6 (June 28, 2017)

IMPROVEMENTS:

  - commands/snapshot: Enforce unique snapshot names and introduce `--force` flag ([GH-7810])
  - commands/ssh: Introduce tty flag for `vagrant ssh -c` ([GH-6827])
  - core: Warn about vagrant CWD changes for a machine ([GH-3921])
  - core: Allow Compression and DSAAuthentication ssh flags to be configurable ([GH-8693])
  - core/box: Warn if user sets box as url ([GH-7118])
  - core/bundler: Enforce stict constraints on vendored libraries ([GH-8692])
  - guests/kali: Add support for guest ([GH-8553])
  - guests/smartos: Update halt capability and add public key insert and remove capabilities ([GH-8618])
  - provisioners/ansible: Fix SSH keys only behavior to be consistent with Vagrant ([GH-8467])
  - providers/docker: Add post install provisioner for docker setup ([GH-8722])
  - snapshot/delete: Improve error message when given snapshot doesn't exist ([GH-8653])
  - snapshot/list: Raise exception if provider does not support snapshots ([GH-8619])
  - snapshot/restore: Improve error message when given snapshot doesn't exist ([GH-8653])
  - snapshot/save: Raise exception if provider does not support snapshots ([GH-8619])

BUG FIXES:

  - communicators/ssh: Move `none` cipher to end of default cipher list in Net::SSH ([GH-8661])
  - core: Add unique identifier to provisioner objects ([GH-8680])
  - core: Stop config loader from loading dupe config if home and project dir are equal ([GH-8707])
  - core/bundler: Impose constraints on update and allow system plugins to properly update ([GH-8729])
  - guests/linux: Strip whitespace from GID [GH-8666, GH-8664]
  - guests/solaris: Do not use UNC style path for shared folders from windows hosts ([GH-7723])
  - guests/windows: Fix directory creation when using rsync for synced folders ([GH-8588])
  - hosts/windows: Force common encoding when running system commands ([GH-8725])
  - providers/docker: Fix check for docker-compose [GH-8659, GH-8660]
  - providers/docker: Fix SSH under docker provider ([GH-8706])
  - providers/hyperv: Fix box import [GH-8678, GH-8677]
  - provisioners/ansible_local: Catch pip_args in FreeBSD's and SUSE's ansible_install ([GH-8676])
  - provisioners/salt: Fix minion ID configuration [GH-7865, GH-7454]
  - snapshot/restore: Exit 1 if vm has not been created when command is invoked ([GH-8653])

## 1.9.5 (May 15, 2017)

FEATURES:

  - hosts/windows: Support running within WSL [GH-8570, GH-8582]

IMPROVEMENTS:

  - communicators/ssh: Retry on aborted connections [GH-8526, GH-8520]
  - communicators/winssh: Enabling shared folders and networking setup ([GH-8567])
  - core: Remove nokogiri dependency and constraint ([GH-8571])
  - guests: Do not modify existing /etc/hosts content [GH-8506, GH-7794]
  - guests/redhat: Update network configuration capability to properly handle NM ([GH-8531])
  - hosts/windows: Check for elevated shell for Hyper-V [GH-8548, GH-8510]
  - hosts/windows: Fix invalid share names on Windows guests from Windows hosts ([GH-8433])
  - providers: Return errors from docker/hyperv on ssh when not available [GH-8565, GH-8508]
  - providers/docker: Add support for driving provider with docker-compose ([GH-8576])

BUG FIXES:

  - guests/debian: Fix use_dhcp_assigned_default_route [GH-8577, GH-8575]
  - provisioners/shell: Fix Windows batch file provisioning [GH-8539, GH-8535]
  - providers/docker: Fall back to old style for SSH info lookup [GH-8566, GH-8552]
  - providers/hyperv: Fix import script ([GH-8529])
  - providers/hyperv: Use string comparison for conditional checks in import scripts [GH-8568, GH-8444]

## 1.9.4 (April 24, 2017)

FEATURES:

  - command/validate: Add Vagrantfile validation command [GH-8264, GH-8151]
  - communicators/winssh: Add WinSSH communicator for Win32-OpenSSH ([GH-8485])
  - provider/hyperv: Support integration services configuration [GH-8379, GH-8378]

IMPROVEMENTS:

  - core: Update internal dependencies [GH-8329, GH-8456]
  - core/bundler: Warn when plugin require fails instead of generating hard failure [GH-8400, GH-8392]
  - core/bundler: Error when configured plugin sources are unavailable ([GH-8442])
  - guests/elementary: Add support for new guest "Elementary OS" ([GH-8472])
  - guests/esxi: Add public_key capability ([GH-8310])
  - guests/freebsd: Add chef_install and chef_installed? capabilities ([GH-8443])
  - guests/gentoo: Add support for systemd in network configuration [GH-8407, GH-8406]
  - guests/windows: Support mounting synced folders via SSH on windows [GH-7425, GH-6220]
  - hosts/windows: Improve user permission detection ([GH-7797])
  - provider/docker: Improve IP and port detection [GH-7840, GH-7651]
  - provider/docker: Do not force docker host VM on Darwin or Windows [GH-8437, GH-7895]
  - provisioners/ansible_local: Add `pip_args` option to define additional parameters when installing Ansible via pip [GH-8170, GH-8405]
  - provisioners/ansible_local: Add `:pip_args_only` install mode to allow full custom pip installations ([GH-8405])
  - provisioners/salt: Update minion version installed to 2016.11.3 ([GH-8448])

BUG FIXES:

  - command/box: Remove extraneous sort from box list prior to display ([GH-8422])
  - command/box: Properly handle local paths with spaces for box add [GH-8503, GH-6825]
  - command/up: Prevent other provider installation when explicitly defined [GH-8393, GH-8389]
  - communicators/ssh: Do not yield empty output data [GH-8495, GH-8259]
  - core: Provide fallback and retry when 0.0.0.0 is unavailable during port check [GH-8399, GH-8395]
  - core: Support port checker methods that do not expect inclusion of host_ip [GH-8497, GH-8423]
  - core/bundler: Check if source is local path and prevent addition to remote sources ([GH-8401])
  - core/ui: Prevent deadlock detection errors [GH-8414, GH-8125]
  - guests/debian: Remove hardcoded device name in interface template [GH-8336, GH-7960]
  - guests/linux: Fix SMB mount capability [GH-8410, GH-8404]
  - hosts/windows: Fix issues with Windows encoding [GH-8385, GH-8380, GH-8212, GH-8207, GH-7516]
  - hosts/windows: Fix UNC path generation when UNC path is provided ([GH-8504])
  - provisioners/salt: Allow Salt version to match 2 digit month ([GH-8428])
  - provisioners/shell: Properly handle remote paths on Windows that include spaces [GH-8498, GH-7234]

## 1.9.3 (March 21, 2017)

IMPROVEMENTS:

  - command/plugin: Remove requirement for paths with no spaces ([GH-7967])
  - core: Support host_ip for forwarded ports [GH-7035, GH-8350]
  - core: Include disk space hint in box install failure message ([GH-8089])
  - core/bundler: Allow vagrant constraint matching in prerelease mode ([GH-8341])
  - provisioner/docker: Include /bin/docker as valid path ([GH-8390])
  - provider/hyperv: Support enabling Hyper-V nested virtualization [GH-8325, GH-7738]

BUG FIXES:

  - communicator/winrm: Prevent inaccurate WinRM address [GH-7983, GH-8073]
  - contrib/bash: Handle path spaces in bash completion ([GH-8337])
  - core: Fix box sorting on find and list [GH-7956, GH-8334]
  - core/bundler: Force path as preferred source on install ([GH-8327])
  - core/provision: Update "never" behavior to match documentation [GH-8366, GH-8016]
  - plugins/push: Isolate deprecation to Atlas strategy only
  - plugins/synced_folders: Give UID/GID precedence if found within mount options
      [GH-8122, GH-8064, GH-7859]

## 1.9.2 (February 27, 2017)

FEATURES:

  - providers/hyperv: Support packaging of Hyper-V boxes ([GH-7867])
  - util/command_deprecation: Add utility module for command deprecation ([GH-8300])
  - util/subprocess: Add #stop and #running? methods ([GH-8270])

IMPROVEMENTS:

  - commands/expunge: Display default value on prompt and validate input [GH-8192, GH-8171]
  - communicator/winrm: Refactor WinRM communicator to use latest WinRM
      gems and V2 API ([GH-8102])
  - core: Scrub URL credentials from output when adding boxes [GH-8194, GH-8117]
  - providers/hyperv: Prefer VMCX over XML configuration when VMCX is supported ([GH-8119])

BUG FIXES:

  - command/init: Include box version when using minimal option [GH-8283, GH-8282]
  - command/package: Fix SecureRandom constant error ([GH-8159])
  - communicator/ssh: Remove any STDERR output prior to command execution [GH-8291, GH-8288]
  - core/bundler: Prevent pristine warning messages [GH-8191, GH-8190, GH-8147]
  - core/bundler: Fix local installations of pre-release plugins [GH-8252, GH-8253]
  - core/bundler: Prefer user defined source when installing plugins [GH-8273, GH-8210]
  - core/environment: Prevent persisting original environment variable if name is empty
      [GH-8198, GH-8126]
  - core/environment: Fix gems_path location ([GH-8248])
  - core/environment: Properly expand dotfile path [GH-8196, GH-8108]
  - guests/arch: Fix configuring multiple network interfaces ([GH-8165])
  - guests/linux: Fix guest detection for names with spaces ([GH-8092])
  - guests/redhat: Fix network interface configuration ([GH-8148])

DEPRECATIONS:

  - command/push: Disable push command ([GH-8300])

## 1.9.1 (December 7, 2016)

IMPROVEMENTS:

  - core: Disable Vagrantfile loading when running plugin commands ([GH-8066])
  - guests/redhat: Detect and restart NetworkManager service if in use [GH-8052, GH-7994]

BUG FIXES:

  - core: Detect load failures within install solution sets and retry ([GH-8068])
  - core: Prevent interactive shell on plugin uninstall [GH-8086, GH-8087]
  - core: Remove bundler usage from Util::Env [GH-8090, GH-8094]
  - guests/linux: Prevent stderr output on init version check for synced folders ([GH-8051])

## 1.9.0 (November 28, 2016)

FEATURES:

  - commands/box: Add `prune` subcommand for removing outdated boxes ([GH-7978])
  - core: Remove Bundler integration for handling internal plugins [GH-7793, GH-8000, GH-8011, GH-8031]
  - providers/hyperv: Add support for Hyper-V binary configuration format
      [GH-7854, GH-7706, GH-6102]
  - provisioners/shell: Support MD5/SHA1 checksum validation of remote scripts [GH-7985, GH-6323]

IMPROVEMENTS:

  - commands/plugin: Retain name sorted output when listing plugins ([GH-8028])
  - communicator/ssh: Support custom environment variable export template
      [GH-7976, GH-6747]
  - provisioners/ansible(both): Add `config_file` option to point the location of an
      `ansible.cfg` file via ANSIBLE_CONFIG environment variable [GH-7195, GH-7918]
  - synced_folders: Support custom naming and disable auto-mount [GH-7980, GH-6836]

BUG FIXES:

  - guests/linux: Do not match interfaces with special characters when sorting [GH-7989, GH-7988]
  - provisioner/salt: Fix Hash construction for constant [GH-7986, GH-7981]

## 1.8.7 (November 4, 2016)

IMPROVEMENTS:

  - guests/linux: Place ethernet devices at start of network devices list ([GH-7848])
  - guests/linux: Provide more consistent guest detection [GH-7887, GH-7827]
  - guests/openbsd: Validate guest rsync installation success [GH-7929, GH-7898]
  - guests/redhat: Include Virtuozzo Linux 7 within flavor identification ([GH-7818])
  - guests/windows: Allow vagrant to start Windows Nano without provisioning ([GH-7831])
  - provisioners/ansible_local: Change the Ansible binary detection mechanism ([GH-7536])
  - provisioners/ansible(both): Add the `playbook_command` option ([GH-7881])
  - provisioners/puppet: Support custom environment variables [GH-7931, GH-7252, GH-2270]
  - util/safe_exec: Use subprocess for safe_exec on Windows ([GH-7802])
  - util/subprocess: Allow closing STDIN ([GH-7778])

BUG FIXES:

  - communicators/winrm: Prevent connection leakage ([GH-7712])
  - core: Prevent duplicate provider priorities ([GH-7756])
  - core: Allow Numeric type for box version [GH-7874, GH-6960]
  - core: Provide friendly error when user environment is too large [GH-7889, GH-7857]
  - guests: Remove `set -e` usage for better shell compatibility [GH-7921, GH-7739]
  - guests/linux: Fix incorrectly configured private network [GH-7844, GH-7848]
  - guests/linux: Properly order network interfaces
      [GH-7866, GH-7876, GH-7858, GH-7876]
  - guests/linux: Only emit upstart event if initctl is available ([GH-7813])
  - guests/netbsd: Fix rsync installation [GH-7922, GH-7901]
  - guests/photon: Fix networking setup [GH-7808, GH-7873]
  - guests/redhat: Properly configure network and restart service ([GH-7751])
  - guests/redhat: Prevent NetworkManager from managing devices on initial start ([GH-7926])
  - hosts/linux: Fix race condition in writing /etc/exports file for NFS configuration
      [GH-7947, GH-7938] - Thanks to Aron Griffis (@agriffis) for identifying this issue
  - plugins/rsync: Escape exclude paths [GH-7928, GH-7910]
  - providers/docker: Remove --interactive flag when pty is true ([GH-7688])
  - provisioners/ansible_local: Use enquoted path for file/directory existence checks
  - provisioners/salt: Synchronize configuration defaults with documentation [GH-7907, GH-6624]
  - pushes/atlas: Fix atlas push on Windows platform [GH-6938, GH-7802]

## 1.8.6 (September 27, 2016)

IMPROVEMENTS:

  - Add detection for DragonFly BSD ([GH-7701])
  - Implement auto_start and auto_stop actions for Hyper-V ([GH-7647])
  - communicators/ssh: Remove any content prepended to STDOUT [GH-7676, GH-7613]

BUG FIXES:

  - commands/package: Provide machine data directory for base box package
      [GH-5070, GH-7725]
  - core: Fix windows path formatting ([GH-6598])
  - core: Fixes for ssh-agent interactions [GH-7703, GH-7621, GH-7398]
  - core: Support VAGRANT_DOTFILE_PATH relative to the Vagrantfile ([GH-7623])
  - guests: Prevent ssh disconnect errors on halt command ([GH-7675])
  - guests/bsd: Remove Darwin matching ([GH-7701])
  - guests/linux: Fix SSH key permissions [GH-7610, GH-7611]
  - guests/linux: Always sort discovered network interfaces [GH-7705, GH-7668]
  - guests/linux: Fixes for user and group ID lookups for virtualbox shared folders
      [GH-7616, GH-7662, GH-7720]
  - guests/openbsd: Add custom halt capability ([GH-7701])
  - guests/ubuntu: Fix detection on older guests [GH-7632, GH-7524, GH-7625]
  - hosts/arch: Detect NFS server by service name on arch [GH-7630, GH-7629]
  - hosts/darwin: Fix generated RDP configuration file ([GH-7698])
  - provisioners/ansible: Add support for `ssh.proxy_command` setting ([GH-7752])
  - synced_folders/nfs: Display warning when configured for NFSv4 and UDP ([GH-7740])
  - synced_folders/rsync: Properly ignore excluded files within synced directory
      from `chown` command. [GH-5256, GH-7726]

## 1.8.5 (July 18, 2016)

FEATURES:

  - core: Provide a way to globally disable box update checks with the
      environment variable `VAGRANT_BOX_UPDATE_CHECK_DISABLE`. Setting this
      to any non-empty value will instruct Vagrant to not look for box updates
      when running `vagrant up`. Setting this environment variable has no
      effect on the `vagrant box` commands.

IMPROVEMENTS:

  - guests/arch: Support installing synced folder clients ([GH-7519])
  - guests/darwin: Allow ipv6 static networks ([GH-7491])
  - providers/virtualbox: Add support for 5.1 ([GH-7574])

BUG FIXES:

  - core: Bump listen gem and Ruby version to improve rsync performance
      [GH-7453, GH-7441]
  - core: Check process stdout when detecting if a hyperv admin
      [GH-7465, GH-7467]
  - core: Ensure removal of temporary directory when box download fails
      [GH-7496, GH-7499]
  - core: Fix regression for installing plugins from path [GH-7505, GH-7493]
  - core: Skip checking conflicts on disabled ports ([GH-7587])
  - core: Idempotent write-out for state file ([GH-7550])
  - core/guests: Create common BSD guest for shared logic
  - core/guests: Ignore empty output from `/sbin/ip`
      [GH-7539, GH-7537, GH-7533, GH-7605]
  - synced_folders/nfs: Shellescape rsync paths
      [GH-7540, GH-7605]
  - synced_folders/nfs: Ensure retries take place [GH-6360, GH-7605]
  - synced_folders/rsync: Shellescape rsync paths
      [GH-7580, GH-6690, GH-7579, GH-7605]
  - synced_folders/rsync: Translate Windows paths
      [GH-7012, GH-6702, GH-6568, GH-7046]
  - guests/bsd: Consolidate core logic for mounting NFS folders
      [GH-7480, GH-7474, GH-7466]
  - guests/bsd: Consolidate core logic for public key management ([GH-7481])
  - guests/bsd: Consolidate core logic for halting ([GH-7484])
  - guests/centos: Use `ip` instead of `ifconfig` to detect network interfaces
      ([GH-7460])
  - guests/debian: Ensure newline when inserting public key ([GH-7456])
  - guests/linux: Ensure NFS retries during mounting ([GH-7492])
  - guests/redhat: Use `/sbin/ip` to list and configure networks for
      compatability with older versions of CentOS ([GH-7482])
  - guests/redhat: Ensure newline when inserting public key [GH-7598, GH-7605]
  - guests/ubuntu: Use /etc/os-release to detect ([GH-7524])
  - guests/ubuntu: Use short hostname [GH-7488, GH-7605]
  - providers/hyperv: Fix version check and catch statement [GH-7447, GH-7487]

## 1.8.4 (June 13, 2016)

BUG FIXES:

  - core: Fix bundler plugin issue and version constraint [GH-7418, GH-7415]
  - providers/virtualbox: Use 8 network interfaces (due to Windows limitation)
      [GH-7417, GH-7419]
  - provisioners/ansible(both): Honor "galaxy_roles_path" option when running
      ansible-playbook [GH-7269, GH-7420]
  - provisioners/ansible_local: Add quotes around "ansible-galaxy" arguments
      ([GH-7420])

IMPROVEMENTS:

  - guests/redhat: Add CloudLinux detection [GH-7428, GH-7427]

## 1.8.3 (June 10, 2016)

BREAKING CHANGES:

  - The `winrm` communicator now shares the same upload behavior as the `ssh`
      communicator. This change should have no impact to most vagrant operations
      but may break behavior when uploading directories to an existing
      destination target. The `file` provisioner should be the only builtin
      provisioner affected by this change. When uploading a directory and the
      destination directory exists on the endpoint, the source base directory
      will be created below the destination directory on the endpoint and the
      source directory contents will be unzipped to that location. Prior to this
      release, the contents of the source directory would be unzipped to an
      existing destination directory without creating the source base directory.
      This new behavior is more consistent with SCP and other well known shell copy commands.
  - The Chef provisioner's `channel` default value has changed from "current" to
      "stable". The "current" channel includes nightly releases and should be
      opt-in only. Note that users wishing to download the Chef Development Kit
      will need to opt into the "current" channel until Chef Software promotes
      into the "stable" channel.
  - The Arch Linux host capability for NFS removed support for rc.d in favor or
      systemd which has been present since 2012. Please see GH-7181 for more
      information.

FEATURES:

  - provider/docker: Allow non-linux users to opt-out of the host VM to run
      Docker containers by setting `config.force_host_vm = false` in the
      Vagrantfile. This is especially useful for customers who wish to use
      the beta builds for Mac and Windows, dlite, or a custom provider.
      [GH-7277, GH-7298, 8c11b53]
  - provider/docker: New command: `docker-exec` allows attaching to an
      already-running container.
      [GH-7377, GH-6566, GH-5193, GH-4904, GH-4057, GH-4179, GH-4903]

IMPROVEMENTS:

  - core/downloader: increase box resume download limit to 24h
      [GH-7352, GH-7272]
  - core/package: run validations prior to packaging [GH-7353, GH-7351]
  - core/action: make `start` ("vagrant up") run provisioners [GH-4467, GH-4421]
  - commands/all: Make it clear that machine IDs can be specified
      [GH-7356, GH-7228]
  - commands/init: Add support for specifying the box version [GH-7363, GH-5004]
  - commands/login: Print a warning with both the environment variable and
      local login token are present [GH-7206, GH-7219]
  - communicators/winrm: Upgrade to latest WinRM gems ([GH-6922])
  - provisioners/ansible_local: Allow to install Ansible from pip,
      with version selection capability [GH-6654, GH-7167]
  - provisioners/ansible_local: Use `provisioning_path` as working directory
      for `ansible-galaxy` execution
  - provisioners/ansible(both provisioners): Add basic config
      validators/converters on `raw_arguments` and `raw_ssh_args` options
      ([GH-7103])
  - provisioners/chef: Add the ability to install on SUSE ([GH-6806])
  - provisioners/chef: Support legacy solo mode ([GH-7327])
  - provisioners/docker: Restart container if newer image is available
      [GH-7358, GH-6620]
  - hosts/arch: Remove sysvinit and assume systemd ([GH-7181])
  - hosts/linux: Do not use a pager with systemctl commands ([GH-7270])
  - hosts/darwin: Add `extra_args` support for RDP [GH-5523, GH-6602]
  - hosts/windows: Use SafeExec to capture history in Powershell ([GH-6749])
  - guests/amazon: Add detection [GH-7395, GH-7254]
  - guests/freebsd: Add quotes around hostname ([GH-6867])
  - guests/fedora: Add support for ipv6 static networks [GH-7275, GH-7276]
  - guests/tinycore: Add support for shared folders [GH-6977, GH-6968]
  - guests/trisquel: Add initial support [GH-6842, GH-6843]
  - guests/windows: Add support for automatic login (no password prompting)
      ([GH-5670])
  - core: Add `--no-delete` and provisioning flags to snapshot restore/pop
      ([GH-6879])
  - providers/docker: Allow TCP and UDP ports on the same number [GH-7365,
      GH-5527]
  - providers/hyperv: Add support for differencing disk ([GH-7090])
  - providers/hyperv: Add support for snapshots ([GH-7110])
  - providers/hyperv: Reinstate compatibility with PS 4 ([GH-7108])
  - providers/virtualbox: Add linked clone support for Virtualbox 1.4 ([GH-7050])
  - synced_folders/nfs: Read static and dynamic IPs [GH-7290, GH-7289]

BUG FIXES:

  - core: Bump nokogiri version to fix windows bug [GH-6766, GH-6848]
  - core: Revert a change made to the output of the identify file [GH-6962,
      GH-6929, GH-6589]
  - core: Fix login command behind a proxy [GH-6898, GH-6899]
  - core: Fix support for regular expressions on multi-machine `up`
      [GH-6908, GH-6909]
  - core: Allow boxes to use pre-release versions [GH-6892, GH-6893]
  - core: Rescue `Errno:ENOTCONN` waiting for port to be open [GH-7182, GH-7184]
  - core: Properly authenticate metadata box URLs [GH-6776, GH-7158]
  - core: Do not run provisioners if already run on resume [GH-7059, GH-6787]
  - core: Implement better tracking of tempfiles and tmpdirs to identify file
      leaks ([GH-7355])
  - core: Allow SSH forwarding on Windows [GH-7287, GH-7202]
  - core: Allow customizing `keys_only` SSH option [GH-7360, GH-4275]
  - core: Allow customizing `paranoid` SSH option [GH-7360, GH-4275]
  - command/box_update: Do not update the same box twice [GH-6042, GH-7379]
  - command/init: Remove unnecessary `sudo` from generated Vagrantfile
      [GH-7369, GH-7295]
  - docs & core: Be consistent about the "2" in the Vagrantfile version
      [GH-6961, GH-6963]
  - guests/all: Refactor guest capabilities to run in a single command -
      **please see GH-7393 for the complete list of changes!**
  - guests/arch: Restart network after configuration [GH-7120, GH-7119]
  - guests/debian: Do not return an error if ifdown fails [GH-7159,
      GH-7155, GH-6871]
  - guests/freebsd: Use `pkg` to install rsync ([GH-6760])
  - guests/freebsd: Use `netif` to configure networks [GH-5852, GH-7093]
  - guests/coreos: Detect all interface names [GH-6608, GH-6610]
  - providers/hyperv: Only specify Hyper-V if the parameter is support
      [GH-7101, GH-7098]
  - providers/virtualbox: Set maximum network adapters to 36 [GH-7293, GH-7286]
  - providers/virtualbox: Do not fail when master VM from linked clone is
      missing [GH-7126, GH-6742]
  - providers/virtualbox: Use scoped overrides in preparing NFS
      [GH-7387, GH-7386]
  - provisioners/ansible: Fix a race condition in the concurrent generations of
      the ansible inventory file, while running `vagrant up --parallel`
      [GH-6526, GH-7190]
  - provisioners/ansible_local: Don't quote the Ansible arguments defined in the
      `raw_arguments` option ([GH-7103])
  - provisioners/ansible_local: Format json `extra_vars` with double quotes
      [GH-6726, GH-7103]
  - provisioners/ansible_local: Fix errors in absolute paths to playbook or
      galaxy resources when running on a Windows host [GH-6740, GH-6757]
  - provisioners/ansible_local: Change the way to verify `ansible-galaxy`
      presence, to avoid a non-zero status code with Ansible 2.0 ([GH-6793])
  - provisioners/ansible(both provisioners): The Ansible configuration files
      detection is only executed by the `provision` action [GH-6763, GH-6984]
  - provisioners/chef: Do not use double sudo when installing
      [GGH-6805, GH-6804]
  - provisioners/chef: Change the default channel to "stable" (previously it
      was "current") [GH-7001, GH-6979]
  - provisioners/chef: Default node_name to hostname if present
      [GH-7063, GH-7153]
  - provisioners/docker: Fix -no-trunc command option ([GH-7085])
  - provisioners/docker: Allow provisioning when container name is specified
      [GH-7074, GH-7086]
  - provisioners/puppet: Use `where.exe` to locate puppet binary
      [GH-6912, GH-6876]
  - provisioners/salt: Move masterless config to apply to all platforms
      [GH-7207, Gh-6924, GH-6915]
  - pushes/ftp: Create parent directories when uploading [GH-7154, GH-6316]
  - synced_folders/smb: Do not interpolate configuration file ([GH-6906])

## 1.8.1 (December 21, 2015)

BUG FIXES:

  - core: Don't create ".bundle" directory in pwd ([GH-6717])
  - core: Fix exception on installing VirtualBox ([GH-6713])
  - core: Do not convert standalone drive letters such as "D:" to
      UNC paths ([GH-6598])
  - core: Fix a crash in parsing the config in some cases with network
      configurations ([GH-6730])
  - core: Clean up temporarily files created by bundler
    [GH-7354, GH-6301, GH-3469, GH-6231]
  - commands/up: Smarter logic about what provider to install, avoiding
      situations where VirtualBox was installed over the correct provider ([GH-6731])
  - guests/debian: Fix Docker install ([GH-6722])
  - provisioners/chef: convert chef version to a string before comparing for
    the command builder [GH-6709, GH-6711]
  - provisioners/shell: convert env var values to strings ([GH-6714])

## 1.8.0 (December 21, 2015)

FEATURES:

  - **New Command: `vagrant powershell`**: For machines that support it,
    this will open a PowerShell prompt.
  - **New Command: `vagrant port`**: For machines that support it, this will
    display the list of forwarded ports from the guest to the host.
  - **Linked Clones**: VirtualBox and VMware providers now support
    linked clones for very fast (millisecond) imports on up. ([GH-4484])
  - **Snapshots**: The `vagrant snapshot` command can be used to checkpoint
    and restore point-in-time snapshots.
  - **IPv6 Private Networks**: Private networking now supports IPv6. This
    only works with VirtualBox and VMware at this point. ([GH-6342])
  - New provisioner: `ansible_local` to execute Ansible from the guest
    machine. ([GH-2103])

BREAKING CHANGES:

  - The `ansible` provisioner now can override the effective ansible remote user
    (i.e. `ansible_ssh_user` setting) to always correspond to the vagrant ssh
    username. This change is enabled by default, but we expect this to affect
    only a tiny number of people as it corresponds to the common usage.
    If you however use multiple remote usernames in your Ansible plays, tasks,
    or custom inventories, you can simply set the option `force_remote_user` to
    false to make Vagrant behave the same as before.
  - provisioners/salt: the "config_dir" option has been removed. It has no
      effect in Vagrant 1.8. ([GH-6073])

IMPROVEMENTS:

  - core: allow removal of all box versions with `--all` flag ([GH-3462])
  - core: prune entries from global status on non-existent cwd ([GH-6535])
  - core: networking: allow specifying a DHCP IP ([GH-6325])
  - core: run provisioner cleanup tasks before powering off the VM ([GH-6553])
  - core: only run provisioner cleanup tasks if they're implemented ([GH-6603])
      This improves UX, but wasn't a bug before.
  - command/plugin: Add `--plugin-clean-sources` flag to reset plugin install
      sources, primarily for corp firewalls. ([GH-4738])
  - command/rsync-auto: SSH connection is cached for faster sync times ([GH-6399])
  - command/up: provisioners are run on suspend resume ([GH-5815])
  - communicators/ssh: allow specifying host environment variables to forward
    to guests [GH-4132, GH-6562]
  - communicators/winrm: Configurable execution time limit ([GH-6213])
  - providers/virtualbox: cache version lookup, which caused significant
      slowdown on some Windows hosts ([GH-6552])
  - providers/virtualbox: add `public_address` capability for virtualbox
    [GH-6583, GH-5978]
  - provisioners/chef: perform cleanup tasks on the guest instead of the host
  - provisioners/chef: automatically generate a node_name if one was not given
    ([GH-6555])
  - provisioners/chef: install Chef automatically on Windows ([GH-6557])
  - provisioners/chef: allow the user to specify the Chef product (such as
    the Chef Development Kit) ([GH-6557])
  - provisioners/chef: allow data_bags_path to be an array [GH-5988, GH-6561]
  - provisioners/shell: Support interactive mode for elevated PowerShell
      scripts ([GH-6185])
  - provisioners/shell: add `env` option [GH-6588, GH-6516]
  - provisioners/ansible+ansible_local: add support for ansible-galaxy ([GH-2718])
  - provisioners/ansible+ansible_local: add support for group and host variables
      in the generated inventory ([GH-6619])
  - provisioners/ansible+ansible_local: add support for alphanumeric patterns
      for groups in the generated inventory ([GH-3539])
  - provisioners/ansible: add support for WinRM settings ([GH-5086])
  - provisioners/ansible: add new `force_remote_user` option to control whether
    `ansible_ssh_user` parameter should be applied or not ([GH-6348])
  - provisioners/ansible: show a warning when running from a Windows Host ([GH-5292])
  - pushes/local-exec: add support for specifying script args [GH-6661, GH-6660]
  - guests/slackware: add support for networking ([GH-6514])

BUG FIXES:

  - core: Ctrl-C weirdness fixed where it would exit parent process
      before Vagrant finished cleaning up ([GH-6085])
  - core: DHCP network configurations don't warn on IP addresses ending
      in ".1" ([GH-6150])
  - core: only append `access_token` when it does not exist in the URL
    [GH-6395, GH-6534]
  - core: use the correct private key when packaging a box ([GH-6406])
  - core: fix crash when using invalid box checksum type ([GH-6327])
  - core: don't check for metadata if the download URL is not HTTP ([GH-6540])
  - core: don't make custom dotfile path if there is no Vagrantfile ([GH-6542])
  - core: more robust check for admin privs on Windows ([GH-5616])
  - core: properly detect when HTTP server doesn't support byte ranges and
      retry from scratch ([GH-4479])
  - core: line numbers show properly in Vagrantfile syntax errors
      on Windows ([GH-6445])
  - core: catch errors setting env vars on Windows ([GH-6017])
  - core: remove cached synced folders when they're removed from the
      Vagrantfile ([GH-6567])
  - core: use case-insensitive comparison for box checksum validations
    [GH-6648, GH-6650]
  - commands/box: add command with `~` paths on Windows works ([GH-5747])
  - commands/box: the update command supports CA settings ([GH-4473])
  - commands/box: removing all versions and providers of a box will properly
      clean all directories in `~/.vagrant.d/boxes` ([GH-3570])
  - commands/box: outdated global won't halt on metadata download failure ([GH-6453])
  - commands/login: respect environment variables in `vagrant login` command
    [GH-6590, GH-6422]
  - commands/package: when re-packaging a packaged box, preserve the
      generated SSH key ([GH-5780])
  - commands/plugin: retry plugin install automatically a few times to
      avoid network issues ([GH-6097])
  - commands/rdp: prefer `xfreerdp` if it is available on Linux ([GH-6475])
  - commands/up: the `--provision-with` flag works with provisioner names ([GH-5981])
  - communicator/ssh: fix potential crash case with PTY ([GH-6225])
  - communicator/ssh: escape IdentityFile path [GH-6428, GH-6589]
  - communicator/winrm: respect `boot_timeout` setting ([GH-6229])
  - communicator/winrm: execute scheduled tasks immediately on Windows XP
      since elevation isn't required ([GH-6195])
  - communicator/winrm: Decouple default port forwarding rules for "winrm" and
      "winrm-ssl" ([GH-6581])
  - communicator/winrm: Hide progress bars from PowerShell v5 ([GH-6309])
  - guests/arch: enable network device after setting it up ([GH-5737])
  - guests/darwin: advanced networking works with more NICs ([GH-6386])
  - guests/debian: graceful shutdown works properly with newer releases ([GH-5986])
  - guests/fedora: Preserve `localhost` entry when changing hostname ([GH-6203])
  - guests/fedora: Use dnf if it is available ([GH-6288])
  - guests/linux: when replacing a public SSH key, use POSIX-compliant
      sed flags ([GH-6565])
  - guests/suse: DHCP network interfaces properly configured ([GH-6502])
  - hosts/slackware: Better detection of NFS ([GH-6367])
  - providers/hyper-v: support generation 2 VMs ([GH-6372])
  - providers/hyper-v: support VMs with more than one NIC ([GH-4346])
  - providers/hyper-v: check if user is in the Hyper-V admin group if
      they're not a Windows admin ([GH-6662])
  - providers/virtualbox: ignore "Unknown" status bridge interfaces ([GH-6061])
  - providers/virtualbox: only fix ipv6 interfaces that are in use
      [GH-6586, GH-6552]
  - provisioners/ansible: use quotes for the `ansible_ssh_private_key_file`
    value in the generated inventory ([GH-6209])
  - provisioners/ansible: use quotes when passing the private key files via
      OpenSSH `-i` command line arguments ([GH-6671])
  - provisioners/ansible: don't show the `ansible-playbook` command when verbose
    option is an empty string
  - provisioners/chef: fix `nodes_path` for Chef Zero [GH-6025, GH-6049]
  - provisioners/chef: do not error when the `node_name` is unset
    [GH-6005, GH-6064, GH-6541]
  - provisioners/chef: only force the formatter on Chef 11 or higher
    [GH-6278, GH-6556]
  - provisioners/chef: require `nodes_path` to be set for Chef Zero
    [GH-6110, GH-6559]
  - provisioners/puppet: apply provisioner uses correct default manifests
    with environments. ([GH-5987])
  - provisioners/puppet: remove broken backticks ([GH-6404])
  - provisioners/puppet: find Puppet binary properly on Windows ([GH-6259])
  - provisioners/puppet-server: works with Puppet Collection 1 ([GH-6389])
  - provisioners/salt: call correct executables on Windows ([GH-5999])
  - provisioners/salt: log level and colorize works for masterless ([GH-6474])
  - push/local-exec: use subprocess on windows when fork does not exist
    [GH-5307, GH-6563]
  - push/heroku: use current branch ([GH-6554])
  - synced\_folders/rsync: on Windows, replace all paths with Cygwin
      paths since all rsync implementations require this ([GH-6160])
  - synced\_folders/smb: use credentials files to allow for more characters
      in password ([GH-4230])

PLUGIN AUTHOR CHANGES:

  - installer: Upgrade to Ruby 2.2.3

## 1.7.4 (July 17, 2015)

BUG FIXES:

  - communicators/winrm: catch timeout errors ([GH-5971])
  - communicators/ssh: use the same SSH args for `vagrant ssh` with and without
    a command [GH-4986, GH-5928]
  - guests/fedora: networks can be configured without nmcli ([GH-5931])
  - guests/fedora: biosdevname can return 4 or 127 ([GH-6139])
  - guests/redhat: systemd detection should happen on guest ([GH-5948])
  - guests/ubuntu: setting hostname fixed in 12.04 ([GH-5937])
  - hosts/linux: NFS can be configured without `$TMP` set on the host ([GH-5954])
  - hosts/linux: NFS will sudo copying back to `/etc/exports` ([GH-5957])
  - providers/docker: Add `pull` setting, default to false ([GH-5932])
  - providers/virtualbox: remove UNC path conversion on Windows since it
      caused mounting regressions ([GH-5933])
  - provisioners/puppet: Windows Puppet 4 paths work correctly ([GH-5967])
  - provisioners/puppet: Fix config merging errors ([GH-5958])
  - provisioners/salt: fix "dummy config" error on bootstrap ([GH-5936])

## 1.7.3 (July 10, 2015)

FEATURES:

  - **New guest: `atomic`* - Project Atomic is supported as a guest
  - providers/virtualbox: add support for 5.0 ([GH-5647])

IMPROVEMENTS:

  - core: add password authentication to rdp_info hash ([GH-4726])
  - core: improve error message when packaging fails ([GH-5399])
  - core: improve message when adding a box from a file path ([GH-5395])
  - core: add support for network gateways ([GH-5721])
  - core: allow redirecting stdout and stderr in the UI ([GH-5433])
  - core: update version of winrm-fs to 0.2.0 ([GH-5738])
  - core: add option to enabled trusted http(s) redirects ([GH-4422])
  - core: capture additional information such as line numbers during
    Vagrantfile loading [GH-4711, GH-5769]
  - core: add .color? to UI objects to see if they support color ([GH-5771])
  - core: ignore hidden directories when searching for boxes [GH-5748, GH-5785]
  - core: use `config.ssh.sudo_command` to customize the sudo command
      format ([GH-5573])
  - core: add `Vagrant.original_env` for Vagrant and plugins to restore or
      inspect the original environment when Vagrant is being run from the
      installer ([GH-5910])
  - guests/darwin: support inserting generated key ([GH-5204])
  - guests/darwin: support mounting SMB shares ([GH-5750])
  - guests/fedora: support Fedora 21 ([GH-5277])
  - guests/fedora: add capabilities for nfs and flavor [GH-5770, GH-4847]
  - guests/linux: specify user's domain as separate parameter [GH-3620, GH-5512]
  - guests/redhat: support Scientific Linux 7 ([GH-5303])
  - guests/photon: initial support ([GH-5612])
  - guests/solaris,solaris11: support inserting generated key ([GH-5182])
      ([GH-5290])
  - providers/docker: images are pulled prior to starting ([GH-5249])
  - provisioners/ansible: store the first ssh private key in the auto-generated inventory ([GH-5765])
  - provisioners/chef: add capability for checking if Chef is installed on Windows ([GH-5669])
  - provisioners/docker: restart containers if arguments have changed [GH-3055, GH-5924]
  - provisioners/puppet: add support for Puppet 4 and configuration options ([GH-5601])
  - provisioners/puppet: add support for `synced_folder_args` in apply ([GH-5359])
  - provisioners/salt: add configurable `config_dir` ([GH-3138])
  - provisioners/salt: add support for masterless configuration ([GH-3235])
  - provisioners/salt: provider path to missing file in errors ([GH-5637])
  - provisioners/salt: add ability to run salt orchestrations ([GH-4371])
  - provisioners/salt: update to 2015.5.2 [GH-4152, GH-5437]
  - provisioners/salt: support specifying version to install ([GH-5892])
  - provisioners/shell: add :name attribute to shell provisioner ([GH-5607])
  - providers/docker: supports file downloads with the file provisioner ([GH-5651])
  - providers/docker: support named Dockerfile ([GH-5480])
  - providers/docker: don't remove image on reload so that build cache can
      be used fully ([GH-5905])
  - providers/hyperv: select a Hyper-V switch based on a `network_name` ([GH-5207])
  - providers/hyperv: allow configuring VladID ([GH-5539])
  - providers/virtualbox: regexp supported for bridge configuration ([GH-5320])
  - providers/virtualbox: handle a list of bridged NICs ([GH-5691])
  - synced_folders/rsync: allow showing rsync output in debug mode ([GH-4867])
  - synced_folders/rsync: set `rsync__rsync_path` to specify the remote
      command used to execute rsync ([GH-3966])

BUG FIXES:

  - core: push configurations are validated with global configs ([GH-5130])
  - core: remove executable permissions on internal file ([GH-5220])
  - core: check name and version in `has_plugin?` ([GH-5218])
  - core: do not create duplicates when defining two private network addresses ([GH-5325])
  - core: update ssh to check for Plink ([GH-5604])
  - core: do not report plugins as installed when plugins are disabled [GH-5698, GH-5430]
  - core: Only take files when packaging a box to avoid duplicates [GH-5658, GH-5657]
  - core: escape curl urls and authentication ([GH-5677])
  - core: fix crash if a value is missing for CLI arguments ([GH-5550])
  - core: retry SSH key generation for transient RSA errors ([GH-5056])
  - core: `ssh.private_key_path` will override the insecure key ([GH-5632])
  - core: restore the original environment when shelling out to subprocesses
      outside of the installer ([GH-5912])
  - core/cli: fix box checksum validation [GH-4665, GH-5221]
  - core/windows: allow Windows UNC paths to allow more than 256
      characters ([GH-4815])
  - command/rsync-auto: don't crash if rsync command fails ([GH-4991])
  - communicators/winrm: improve error handling significantly and improve
      the error messages shown to be more human-friendly. ([GH-4943])
  - communicators/winrm: remove plaintext passwords from files after
      provisioner is complete ([GH-5818])
  - hosts/nfs: allow colons (`:`) in NFS IDs ([GH-5222])
  - guests/darwin: remove dots from LocalHostName ([GH-5558])
  - guests/debian: Halt works properly on Debian 8. ([GH-5369])
  - guests/fedora: recognize future fedora releases ([GH-5730])
  - guests/fedora: reload iface connection by NetworkManager ([GH-5709])
  - guests/fedora: do not use biosdevname if it is not installed ([GH-5707])
  - guests/freebsd: provide an argument to the backup file [GH-5516, GH-5517]
  - guests/funtoo: fix incorrect path in configure networks ([GH-4812])
  - guests/linux: fix edge case exception where no home directory
      is available on guest ([GH-5846])
  - guests/linux: copy NFS exports to tmpdir to do edits to guarantee
      permissions are available ([GH-5773])
  - guests/openbsd: output newline after inserted public key ([GH-5881])
  - guests/tinycore: fix change hostname functionality ([GH-5623])
  - guests/ubuntu: use `hostnamectl` to set hostname on Ubuntu Vivid ([GH-5753])
  - guests/windows: Create rsync folder prior to rsync-ing. ([GH-5282])
  - guests/windows: Changing hostname requires reboot again since
      the non-reboot code path was crashing Windows server. ([GH-5261])
  - guests/windows: ignore virtual NICs ([GH-5478])
  - hosts/windows: More accurately get host IP address in VPNs. ([GH-5349])
  - plugins/login: allow users to login with a token ([GH-5145])
  - providers/docker: Build image from `/var/lib/docker` for more disk
      space on some systems. ([GH-5302])
  - providers/docker: Fix crash that could occur in some scenarios when
      the host VM path changed.
  - providers/docker: Fix crash that could occur on container destroy
      with VirtualBox shared folders ([GH-5143])
  - providers/hyperv: allow users to configure memory, cpu count, and vmname ([GH-5183])
  - providers/hyperv: import respects secure boot. ([GH-5209])
  - providers/hyperv: only set EFI secure boot for gen 2 machines ([GH-5538])
  - providers/virtualbox: read netmask from dhcpservers ([GH-5233])
  - providers/virtualbox: Fix exception when VirtualBox version is empty. ([GH-5308])
  - providers/virtualbox: Fix exception when VBoxManage.exe can't be run
      on Windows ([GH-1483])
  - providers/virtualbox: Error if another user is running after a VM is
      created to avoid issue with VirtualBox "losing" the VM ([GH-5895])
  - providers/virtualbox: The "name" setting on private networks will
      choose an existing hostonly network ([GH-5389])
  - provisioners/ansible: fix SSH settings to support more than 5 ssh keys ([GH-5017])
  - provisioners/ansible: increase ansible connection timeout to 30 seconds ([GH-5018])
  - provisioners/ansible: disable color if Vagrant is not colored [GH-5531, GH-5532]
  - provisioners/ansible: only show ansible-playbook command when `verbose` option is enabled ([GH-5803])
  - provisioners/ansible: fix a race condition in the inventory file generation ([GH-5551])
  - provisioners/docker: use `service` to restart Docker instead of upstart [GH-5245, GH-5577]
  - provisioners/docker: Only add docker user to group if exists. ([GH-5315])
  - provisioners/docker: Use https for repo ([GH-5749])
  - provisioners/docker: `apt-get update` before installing linux kernel
      images to get the correct version ([GH-5860])
  - provisioners/chef: Fix shared folders missing error ([GH-5199])
  - provisioners/chef: Use `command -v` to check for binary instead of
      `which` since that doesn't exist on some systems. ([GH-5170])
  - provisioners/chef-zero: support more chef-zero/local mode attributes ([GH-5339])
  - provisioners/chef: use windows-specific paths in Chef provisioners ([GH-5913])
  - provisioners/docker: use docker.com instead of docker.io ([GH-5216])
  - provisioners/docker: use `--restart` instead of `-r` on daemon ([GH-4477])
  - provisioners/file: validation of source is relative to Vagrantfile ([GH-5252])
  - pushes/atlas: send additional box metadata ([GH-5283])
  - pushes/local-exec: fix "text file busy" error for inline ([GH-5695])
  - pushes/ftp: improve check for remote directory existence ([GH-5549])
  - synced\_folders/rsync: add `IdentitiesOnly=yes` to the rsync command. ([GH-5175])
  - synced\_folders/smb: use correct `password` option ([GH-5805])
  - synced\_folders/smb: prever IPv4 over IPv6 address to mount ([GH-5798])
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

  - provisioners/salt: add support for grains ([GH-4895])

IMPROVEMENTS:

  - commands/reload,up: `--provision-with` implies `--provision` ([GH-5085])

BUG FIXES:

  - core: private boxes still referencing vagrantcloud.com will have
      their vagrant login access token properly appended
  - core: push plugin configuration is properly validated
  - core: restore box packaging functionality
  - commands/package: fix crash
  - commands/push: push lookups are by user-defined name, not push
      strategy name ([GH-4975])
  - commands/push: validate the configuration
  - communicators/winrm: detect parse errors in PowerShell and error
  - guests/arch: fix network configuration due to poor line breaks. ([GH-4964])
  - guests/solaris: Merge configurations properly so configs can be set
      in default Vagrantfiles. ([GH-5092])
  - installer: SSL cert bundle contains 1024-bit keys, fixing SSL verification
      for a lot of sites.
  - installer: vagrant executable properly `cygpaths` the SSL bundle path
      for Cygwin
  - installer: Nokogiri (XML lib used by Vagrant and dependencies) linker
      dependencies fixed, fixing load issues on some platforms
  - providers/docker: Symlinks in shared folders work. ([GH-5093])
  - providers/hyperv: VM start errors turn into proper Vagrant errors. ([GH-5101])
  - provisioners/chef: fix missing shared folder error ([GH-4988])
  - provisioners/chef: remove Chef version check from solo.rb generation and
      make `roles_path` populate correctly
  - provisioners/chef: fix bad invocation of `with_clean_env` ([GH-5021])
  - pushes/atlas: support more verbose logging
  - pushes/ftp: expand file paths relative to the Vagrantfile
  - pushes/ftp: improved debugging output
  - pushes/ftp: create parent directories if they do not exist on the remote
      server

## 1.7.1 (December 11, 2014)

IMPROVEMENTS:

  - provisioners/ansible: Use Docker proxy if needed. ([GH-4906])

BUG FIXES:

  - providers/docker: Add support of SSH agent forwarding. ([GH-4905])

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
      providers are chosen before later ones. ([GH-3812])
  - If the default insecure keypair is used, Vagrant will automatically replace
      it with a randomly generated keypair on first `vagrant up`. ([GH-2608])
  - Vagrant Login is now part of Vagrant core
  - Chef Zero provisioner: Use Chef 11's "local" mode to run recipes against an
      in-memory Chef Server
  - Chef Apply provisioner: Specify inline Chef recipes and recipe snippets
      using the Chef Apply provisioner

IMPROVEMENTS:

  - core: `has_plugin?` function now takes a second argument which is a
      version constraint requirement. ([GH-4650])
  - core: ".vagrantplugins" file in the same folder as your Vagrantfile
      will be loaded for defining inline plugins. ([GH-3775])
  - commands/plugin: Plugin list machine-readable output contains the plugin
      name as the target for versions and other info. ([GH-4506])
  - env/with_cleanenv: New helper for plugin developers to use when shelling out
      to another Ruby environment
  - guests/arch: Support predictable network interface naming. ([GH-4468])
  - guests/suse: Support NFS client install, rsync setup. ([GH-4492])
  - guests/tinycore: Support changing host names. ([GH-4469])
  - guests/tinycore: Support DHCP-based networks. ([GH-4710])
  - guests/windows: Hostname can be set without reboot. ([GH-4687])
  - providers/docker: Build output is now shown. ([GH-3739])
  - providers/docker: Can now start containers from private repositories
      more easily. Vagrant will login for you if you specify auth. ([GH-4042])
  - providers/docker: `stop_timeout` can be used to modify the `docker stop`
      timeout. ([GH-4504])
  - provisioners/chef: Automatically install Chef when using a Chef provisioner.
  - provisioners/ansible: Always show Ansible command executed when Vagrant log
      level is debug (even if ansible.verbose is false)
  - synced\_folders/nfs: Won't use `sudo` to write to /etc/exports if there
      are write privileges. ([GH-2643])
  - synced\_folders/smb: Credentials from one SMB will be copied to the rest. ([GH-4675])

BUG FIXES:

  - core: Fix cases where sometimes SSH connection would hang.
  - core: On a graceful halt, force halt if capability "insert public key"
      is missing. ([GH-4684])
  - core: Don't share `/vagrant` if any "." folder is shared. ([GH-4675])
  - core: Fix SSH private key permissions more aggressively. ([GH-4670])
  - core: Custom Vagrant Cloud server URL now respected in more cases.
  - core: On downloads, don't continue downloads if the remote server
      doesn't support byte ranges. ([GH-4479])
  - core: Box downloads recognize more complex content types that include
      "application/json" ([GH-4525])
  - core: If all sub-machines are `autostart: false`, don't start any. ([GH-4552])
  - core: Update global-status state in more cases. ([GH-4513])
  - core: Only delete machine state if the machine is not created in initialize
  - commands/box: `--cert` flag works properly. ([GH-4691])
  - command/docker-logs: Won't crash if container is removed. ([GH-3990])
  - command/docker-run: Synced folders will be attached properly. ([GH-3873])
  - command/rsync: Sync to Docker containers properly. ([GH-4066])
  - guests/darwin: Hostname sets bonjour name and local host name. ([GH-4535])
  - guests/freebsd: NFS mounting can specify the version. ([GH-4518])
  - guests/linux: More descriptive error message if SMB mount fails. ([GH-4641])
  - guests/rhel: Hostname setting on 7.x series works properly. ([GH-4527])
  - guests/rhel: Installing NFS client works properly on 7.x ([GH-4499])
  - guests/solaris11: Static IP address preserved after restart. ([GH-4621])
  - guests/ubuntu: Detect with `lsb_release` instead of `/etc/issue`. ([GH-4565])
  - hosts/windows: RDP client shouldn't map all drives by default. ([GH-4534])
  - providers/docker: Create args works. ([GH-4526])
  - providers/docker: Nicer error if package is called. ([GH-4595])
  - providers/docker: Host IP restriction is forwarded through. ([GH-4505])
  - providers/docker: Protocol is now honored in direct `ports settings.
  - providers/docker: Images built using `build_dir` will more robustly
      capture the final image. ([GH-4598])
  - providers/docker: NFS synced folders now work. ([GH-4344])
  - providers/docker: Read the created container ID more robustly.
  - providers/docker: `vagrant share` uses correct IP of proxy VM if it
      exists. ([GH-4342])
  - providers/docker: `vagrant_vagrantfile` expands home directory. ([GH-4000])
  - providers/docker: Fix issue where multiple identical proxy VMs would
      be created. ([GH-3963])
  - providers/docker: Multiple links with the same name work. ([GH-4571])
  - providers/virtualbox: Show a human-friendly error if VirtualBox didn't
      clean up an existing VM. ([GH-4681])
  - providers/virtualbox: Detect case when VirtualBox reports 0.0.0.0 as
      IP address and don't allow it. ([GH-4671])
  - providers/virtualbox: Show more descriptive error if VirtualBox is
      reporting an empty version. ([GH-4657])
  - provisioners/ansible: Force `ssh` (OpenSSH) connection by default ([GH-3396])
  - provisioners/ansible: Don't use or modify `~/.ssh/known_hosts` file by default,
      similarly to native vagrant commands ([GH-3900])
  - provisioners/ansible: Use intermediate Docker host when needed. ([GH-4071])
  - provisioners/docker: Get GPG key over SSL. ([GH-4597])
  - provisioners/docker: Search for docker binary in multiple places. ([GH-4580])
  - provisioners/salt: Highstate works properly with a master. ([GH-4471])
  - provisioners/shell: Retry getting SSH info a few times. ([GH-3924])
  - provisioners/shell: PowerShell scripts can have args. ([GH-4548])
  - synced\_folders/nfs: Don't modify NFS exports file if no exports. ([GH-4619])
  - synced\_folders/nfs: Prune exports for file path IDs. ([GH-3815])

PLUGIN AUTHOR CHANGES:

  - `Machine#action` can be called with the option `lock: false` to not
      acquire a machine lock.
  - `Machine#reload` will now properly trigger the `machine_id_changed`
      callback on providers.

## 1.6.5 (September 4, 2014)

BUG FIXES:

  - core: forward SSH even if WinRM is used. ([GH-4437])
  - communicator/ssh: Fix crash when pty is enabled with SSH. ([GH-4452])
  - guests/redhat: Detect various RedHat flavors. ([GH-4462])
  - guests/redhat: Fix typo causing crash in configuring networks. ([GH-4438])
  - guests/redhat: Fix typo causing hostnames to not set. ([GH-4443])
  - providers/virtualbox: NFS works when using DHCP private network. ([GH-4433])
  - provisioners/salt: Fix error when removing non-existent bootstrap script
      on Windows. ([GH-4614])

## 1.6.4 (September 2, 2014)

BACKWARDS INCOMPATIBILITIES:

  - commands/docker-run: Started containers are now deleted after run.
      Specify the new `--no-rm` flag to retain the original behavior. ([GH-4327])
  - providers/virtualbox: Host IO cache is no longer enabled by default
      since it causes stale file issues. Please enable manually if you
      require this. ([GH-3934])

IMPROVEMENTS:

  - core: Added `config.vm.box_server_url` setting to point at a
     Vagrant Cloud instance. ([GH-4282])
  - core: File checksumming performance has been improved by at least
      100%. Memory requirements have gone down by half. ([GH-4090])
  - commands/docker-run: Add the `--no-rm` flag. Containers are
      deleted by default. ([GH-4327])
  - commands/plugin: Better error output is shown when plugin installation
      fails.
  - commands/reload: show post up message ([GH-4168])
  - commands/rsync-auto: Add `--poll` flag. ([GH-4392])
  - communicators/winrm: Show stdout/stderr if command fails. ([GH-4094])
  - guests/nixos: Added better NFS support. ([GH-3983])
  - providers/hyperv: Accept VHD disk format. ([GH-4208])
  - providers/hyperv: Support generation 2 VMs. ([GH-4324])
  - provisioners/docker: More verbose output. ([GH-4377])
  - provisioners/salt: Get proper exit codes to detect failed runs. ([GH-4304])

BUG FIXES:

  - core: Downloading box files should resume in more cases since the
      temporary file is preserved in more cases. ([GH-4301])
  - core: Windows is not detected as NixOS in some cases. ([GH-4302])
  - core: Fix encoding issues with Windows. There are still some outlying
      but this fixes a few. ([GH-4159])
  - core: Fix crash case when destroying with an invalid provisioner. ([GH-4281])
  - core: Box names with colons work on Windows. ([GH-4100])
  - core: Cleanup all temp files. ([GH-4103])
  - core: User curlrc is not loaded, preventing strange download issues.
      ([GH-4328])
  - core: VM names may no longer contain brackets, since they cause
      issues with some providers. ([GH-4319])
  - core: Use "-f" to `rm` files in case pty is true. ([GH-4410])
  - core: SSH key doesn't have to be owned by our user if we're running
      as root. ([GH-4387])
  - core: "vagrant provision" will cause "vagrant up" to properly not
      reprovision. ([GH-4393])
  - commands/box/add: "Content-Type" header is now case-insensitive when
      looking for metadata type. ([GH-4369])
  - commands/docker-run: Named docker containers no longer conflict. ([GH-4294])
  - commands/package: base package won't crash with exception ([GH-4017])
  - commands/rsync-auto: Destroyed machines won't raise exceptions. ([GH-4031])
  - commands/ssh: Extra args are passed through to Docker container. ([GH-4378])
  - communicators/ssh: Nicer error if remote unexpectedly disconnects. ([GH-4038])
  - communicators/ssh: Clean error when max sessions is hit. ([GH-4044])
  - communicators/ssh: Fix many issues around PTY-enabled output parsing.
      ([GH-4408])
  - communicators/winrm: Support `mkdir` ([GH-4271])
  - communicators/winrm: Properly escape double quotes. ([GH-4309])
  - communicators/winrm: Detect failed commands that aren't CLIs. ([GH-4383])
  - guests/centos: Fix issues when NFS client is installed by restarting
      NFS ([GH-4088])
  - guests/debian: Deleting default route on DHCP networks can fail. ([GH-4262])
  - guests/fedora: Fix networks on Fedora 20 with libvirt. ([GH-4104])
  - guests/freebsd: Rsync install for rsync synced folders work on
      FreeBSD 10. ([GH-4008])
  - guests/freebsd: Configure vtnet devices properly ([GH-4307])
  - guests/linux: Show more verbose error when shared folder mount fails.
      ([GH-4403])
  - guests/redhat: NFS setup should use systemd for RH7+ ([GH-4228])
  - guests/redhat: Detect RHEL 7 (and CentOS) and install Docker properly. ([GH-4402])
  - guests/redhat: Configuring networks on EL7 works. ([GH-4195])
  - guests/redhat: Setting hostname on EL7 works. ([GH-4352])
  - guests/smartos: Use `pfexec` for rsync. ([GH-4274])
  - guests/windows: Reboot after hostname change. ([GH-3987])
  - hosts/arch: NFS works with latest versions. ([GH-4224])
  - hosts/freebsd: NFS exports are proper syntax. ([GH-4143])
  - hosts/gentoo: NFS works with latest versions. ([GH-4418])
  - hosts/windows: RDP command works without crash. ([GH-3962])
  - providers/docker: Port on its own will choose random host port. ([GH-3991])
  - providers/docker: The proxy VM Vagrantfile can be in the same directory
      as the main Vagrantfile. ([GH-4065])
  - providers/virtualbox: Increase network device limit to 36. ([GH-4206])
  - providers/virtualbox: Error if can't detect VM name. ([GH-4047])
  - provisioners/cfengine: Fix default Yum repo URL. ([GH-4335])
  - provisioners/chef: Chef client cleanup should work. ([GH-4099])
  - provisioners/puppet: Manifest file can be a directory. ([GH-4169])
  - provisioners/puppet: Properly escape facter variables for PowerShell
      on Windows guests. ([GH-3959])
  - provisioners/puppet: When provisioning fails, don't repeat all of
      stdout/stderr. ([GH-4303])
  - provisioners/salt: Update salt minion version on Windows. ([GH-3932])
  - provisioners/shell: If args is an array and contains numbers, it no
      longer crashes. ([GH-4234])
  - provisioners/shell: If fails, the output/stderr isn't repeated
      again. ([GH-4087])

## 1.6.3 (May 29, 2014)

FEATURES:

  - **New Guest:** NixOS - Supports changing host names and setting
      networks. ([GH-3830])

IMPROVEMENTS:

  - core: A CA path can be specified in the Vagrantfile, not just
      a file, when using a custom CA. ([GH-3848])
  - commands/box/add: `--capath` flag added for custom CA path. ([GH-3848])
  - commands/halt: Halt in reverse order of up, like destroy. ([GH-3790])
  - hosts/linux: Uses rdesktop to RDP into machines if available. ([GH-3845])
  - providers/docker: Support for UDP forwarded ports. ([GH-3886])
  - provisioners/salt: Works on Windows guests. ([GH-3825])

BUG FIXES:

  - core: Provider plugins more easily are compatible with global-status
      and should show less stale data. ([GH-3808])
  - core: When setting a synced folder, it will assume it is not disabled
      unless explicitly specified. ([GH-3783])
  - core: Ignore UDP forwarded ports for collision detection. ([GH-3859])
  - commands/package: Package with `--base` for VirtualBox doesn't
      crash. ([GH-3827])
  - guests/solaris11: Fix issue with public network and DHCP on newer
      Solaris releases. ([GH-3874])
  - guests/windows: Private networks with static IPs work when there
      is more than one. ([GH-3818])
  - guests/windows: Don't look up a forwarded port for WinRM if we're
      not accessing the local host. ([GH-3861])
  - guests/windows: Fix errors with arg lists that are too long over
      WinRM in some cases. ([GH-3816])
  - guests/windows: Powershell exits with proper exit code, fixing
  -   issues where non-zero exit codes weren't properly detected. ([GH-3922])
  - hosts/windows: Don't execute mstsc using PowerShell since it doesn't
      exit properly. ([GH-3837])
  - hosts/windows: For RDP, don't remove the Tempfile right away. ([GH-3875])
  - providers/docker: Never do graceful shutdown, always use
      `docker stop`. ([GH-3798])
  - providers/docker: Better error messaging when SSH is not ready
      direct to container. ([GH-3763])
  - providers/docker: Don't port map SSH port if container doesn't
      support SSH. ([GH-3857])
  - providers/docker: Proper SSH info if using native driver. ([GH-3799])
  - providers/docker: Verify host VM has SSH ready. ([GH-3838])
  - providers/virtualbox: On Windows, check `VBOX_MSI_INSTALL_PATH`
      for VBoxManage path as well. ([GH-3852])
  - provisioners/puppet: Fix setting facter vars with Windows
      guests. ([GH-3776])
  - provisioners/puppet: On Windows, run in elevated prompt. ([GH-3903])
  - guests/darwin: Respect mount options for NFS. ([GH-3791])
  - guests/freebsd: Properly register the rsync_pre capability
  - guests/windows: Certain executed provisioners won't leave output
      and exit status behind. ([GH-3729])
  - synced\_folders/rsync: `rsync__chown` can be set to `false` to
      disable recursive chown after sync. ([GH-3810])
  - synced\_folders/rsync: Use a proper msys path if not in
      Cygwin. ([GH-3804])
  - synced\_folders/rsync: Don't append args infinitely, clear out
      arg list on each run. ([GH-3864])

PLUGIN AUTHOR CHANGES:

  - Providers can now implement the `rdp_info` provider capability
      to get proper info for `vagrant rdp` to function.

## 1.6.2 (May 12, 2014)

IMPROVEMENTS:

  - core: Automatically forward WinRM port if communicator is
      WinRM. ([GH-3685])
  - command/rdp: Args after "--" are passed directly through to the
      RDP client. ([GH-3686])
  - providers/docker: `build_args` config to specify extra args for
      `docker build`. ([GH-3684])
  - providers/docker: Can specify options for the build dir synced
      folder when a host VM is in use. ([GH-3727])
  - synced\_folders/nfs: Can tell Vagrant not to handle exporting
      by setting `nfs_export: false` ([GH-3636])

BUG FIXES:

  - core: Hostnames can be one character. ([GH-3713])
  - core: Don't lock machines on SSH actions. ([GH-3664])
  - core: Fixed crash when adding a box from Vagrant Cloud that was the
      same name as a real directory. ([GH-3732])
  - core: Parallelization is more stable, doesn't crash due to to
      bad locks. ([GH-3735])
  - commands/package: Don't double included files in package. ([GH-3637])
  - guests/linux: Rsync chown ignores symlinks. ([GH-3744])
  - provisioners/shell: Fix shell provisioner config validation when the
    `binary` option is set to false ([GH-3712])
  - providers/docker: default proxy VM won't use HGFS ([GH-3687])
  - providers/docker: fix container linking ([GH-3719])
  - providers/docker: Port settings expose to host properly. ([GH-3723])
  - provisioners/puppet: Separate module paths with ';' on Windows. ([GH-3731])
  - synced\_folders\rsync: Copy symlinks as real files. ([GH-3734])
  - synced\_folders/rsync: Remove non-portable '-v' flag from chown. ([GH-3743])

## 1.6.1 (May 7, 2014)

IMPROVEMENTS:

  - **New guest: Linux Mint** is now properly detected. ([GH-3648])

BUG FIXES:

  - core: Global control works from directories that don't have a
      Vagrantfile.
  - core: Plugins that define config methods that collide with Ruby Kernel/Object
  -   methods are merged properly. ([GH-3670])
  - commands/docker-run: `--help` works. ([GH-3698])
  - commands/package: `--base` works without crashing for VirtualBox.
  - commands/reload: If `--provision` is specified, force provisioning. ([GH-3657])
  - guests/redhat: Fix networking issues with CentOS. ([GH-3649])
  - guests/windows: Human error if WinRM not in use to configure networks. ([GH-3651])
  - guests/windows: Puppet exit code 2 doesn't cause Windows to raise
      an error. ([GH-3677])
  - providers/docker: Show proper error message when on Linux. ([GH-3654])
  - providers/docker: Proxy VM works properly even if default provider
      environmental variable set to "docker" ([GH-3662])
  - providers/docker: Put sync folders in `/var/lib/docker` because
      it usually has disk space. ([GH-3680])
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
      provisioner. ([GH-2421])
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
      1 means everything was declined. 2 means some were declined. ([GH-811])
  - commands/destroy: Doesn't require box to exist anymore. ([GH-1629])
  - commands/init: force flag. ([GH-3564])
  - commands/init: flag for minimal Vagrantfile creation (no comments). ([GH-3611])
  - commands/rsync-auto: Picks up and syncs provisioner folders if
      provisioners are backed by rsync.
  - commands/rsync-auto: Detects when new synced folders were added and warns
      user they won't be synced until `vagrant reload`.
  - commands/ssh-config: Works without a target in multi-machine envs ([GH-2844])
  - guests/freebsd: Support for virtio interfaces. ([GH-3082])
  - guests/openbsd: Support for virtio interfaces. ([GH-3082])
  - guests/redhat: Networking works for upcoming RHEL7 release. ([GH-3643])
  - providers/hyperv: Implement `vagrant ssh -c` support. ([GH-3615])
  - provisioners/ansible: Support for Ansible Vault. ([GH-3338])
  - provisioners/ansible: Show Ansible command executed. ([GH-3628])
  - provisioners/salt: Colorize option. ([GH-3603])
  - provisioners/salt: Ability to specify log level. ([GH-3603])
  - synced\_folders: nfs: Improve sudo commands used to make them
      sudoers friendly. Examples in docs. ([GH-3638])

BUG FIXES:

  - core: Adding a box from a network share on Windows works again. ([GH-3279])
  - commands/plugin/install: Specific versions are now locked in.
  - commands/plugin/install: If insecure RubyGems.org is specified as a
      source, use that. ([GH-3610])
  - commands/rsync-auto: Interrupt exits properly. ([GH-3552])
  - commands/rsync-auto: Run properly on Windows. ([GH-3547])
  - communicators/ssh: Detect if `config.ssh.shell` is invalid. ([GH-3040])
  - guests/debian: Can set hostname if hosts doesn't contain an entry
      already for 127.0.1.1 ([GH-3271])
  - guests/linux: For `read_ip_address` capability, set `LANG=en` so
      it works on international systems. ([GH-3029])
  - providers/virtualbox: VirtualBox detection works properly again on
      Windows when the `VBOX_INSTALL_PATH` has multiple elements. ([GH-3549])
  - providers/virtualbox: Forcing MAC address on private network works
      properly again. ([GH-3588])
  - provisioners/chef-solo: Fix Chef version checking to work with prerelease
      versions. ([GH-3604])
  - provisioners/salt: Always copy keys and configs on provision. ([GH-3536])
  - provisioners/salt: Install args should always be present with bootstrap.
  - provisioners/salt: Overwrite keys properly on subsequent provisions ([GH-3575])
  - provisioners/salt: Bootstrap uses raw GitHub URL rather than subdomain. ([GH-3583])
  - synced\_folders/nfs: Acquires a process-level lock so exports don't
      collide with Vagrant running in parallel.
  - synced\_folders/nfs: Implement usability check so that hosts that
      don't support NFS get an error earlier. ([GH-3625])
  - synced\_folders/rsync: Add UserKnownHostsFile option to not complain. ([GH-3511])
  - synced\_folders/rsync: Proxy command is used properly if set. ([GH-3553])
  - synced\_folders/rsync: Owner/group settings are respected. ([GH-3544])
  - synced\_folders/smb: Passwords with symbols work. ([GH-3642])

PLUGIN AUTHOR CHANGES:

  - **New host capability:** "rdp\_client". This capability gets the RDP connection
      info and must launch the RDP client on the system.
  - core: The "Call" middleware now merges the resulting middleware stack
      into the current stack, rather than running it as a separate stack.
      The result is that ordering is preserved.
  - core: The "Message" middleware now takes a "post" option that will
      output the message on the return-side of the middleware stack.
  - core: Forwarded port collision repair works when Vagrant is run in
      parallel with other Vagrant processes. ([GH-2966])
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

  - commands/box/list: Doesn't parse Vagrantfile. ([GH-3502])
  - providers/hyperv: Implement the provision command. ([GH-3494])

BUG FIXES:

  - core: Allow overriding of the default SSH port. ([GH-3474])
  - commands/box/remove: Make output nicer. ([GH-3470])
  - commands/box/update: Show currently installed version. ([GH-3467])
  - command/rsync-auto: Works properly on Windows.
  - guests/coreos: Fix test for Docker daemon running.
  - guests/linux: Fix test for Docker provisioner whether Docker is
      running.
  - guests/linux: Fix regression where rsync owner/group stopped
      working. ([GH-3485])
  - provisioners/docker: Fix issue where we weren't waiting for Docker
      to properly start before issuing commands. ([GH-3482])
  - provisioners/shell: Better validation of master config path, results
      in no more stack traces at runtime. ([GH-3505])

## 1.5.3 (April 14, 2014)

IMPROVEMENTS:

  - core: 1.5 upgrade code gives users a chance to quit. ([GH-3212])
  - commands/rsync-auto: An initial sync is done before watching folders. ([GH-3327])
  - commands/rsync-auto: Exit immediately if there are no paths to watch.
      ([GH-3446])
  - provisioners/ansible: custom vars/hosts files can be added in
      .vagrant/provisioners/ansible/inventory/ directory ([GH-3436])

BUG FIXES:

  - core: Randomize some filenames internally to improve the parallelism
      of Vagrant. ([GH-3386])
  - core: Don't error if network problems cause box update check to
      fail ([GH-3391])
  - core: `vagrant` on Windows cmd.exe doesn't always exit with exit
      code zero. ([GH-3420])
  - core: Adding a box from a network share has nice error on Windows. ([GH-3279])
  - core: Setting an ID on a provisioner now works. ([GH-3424])
  - core: All synced folder paths containing symlinks are fully
      expanded before sharing. ([GH-3444])
  - core: Windows no longer sees "process not started" errors rarely.
  - commands/box/repackage: Works again. ([GH-3372])
  - commands/box/update: Update should check for updates from latest
      version. ([GH-3452])
  - commands/package: Nice error if includes contain symlinks. ([GH-3200])
  - commands/rsync-auto: Don't crash if the machine can't be communicated
      to. ([GH-3419])
  - communicators/ssh: Throttle connection attempt warnings if the warnings
      are the same. ([GH-3442])
  - guests/coreos: Docker provisioner works. ([GH-3425])
  - guests/fedora: Fix hostname setting. ([GH-3382])
  - guests/fedora: Support predictable network interface names for
      public/private networks. ([GH-3207])
  - guests/linux: Rsync folders have proper group if owner not set. ([GH-3223])
  - guests/linux: If SMB folder mounting fails, the password will no
      longer be shown in plaintext in the output. ([GH-3203])
  - guests/linux: SMB mount works with passwords with symbols. ([GH-3202])
  - providers/hyperv: Check for PowerShell features. ([GH-3398])
  - provisioners/docker: Don't automatically generate container name with
      a forward slash. ([GH-3216])
  - provisioners/shell: Empty shell scripts don't cause errors. ([GH-3423])
  - synced\_folders/smb: Only set the chmod properly by default on Windows
      if it isn't already set. ([GH-3394])
  - synced\_folders/smb: Sharing folders with odd characters like parens
      works properly now. ([GH-3405])

## 1.5.2 (April 2, 2014)

IMPROVEMENTS:

  - **New guest:** SmartOS
  - core: Change wording from "error" to "warning" on SSH retry output
    to convey actual meaning.
  - commands/plugin: Listing plugins now has machine-readable output. ([GH-3293])
  - guests/omnios: Mount NFS capability ([GH-3282])
  - synced\_folders/smb: Verify PowerShell v3 or later is running. ([GH-3257])

BUG FIXES:

  - core: Vagrant won't collide with newer versions of Bundler ([GH-3193])
  - core: Allow provisioner plugins to not have a config class. ([GH-3272])
  - core: Removing a specific box version that doesn't exist doesn't
      crash Vagrant. ([GH-3364])
  - core: SSH commands are forced to be ASCII.
  - core: private networks with DHCP type work if type parameter is
      a string and not a symbol. ([GH-3349])
  - core: Converting to cygwin path works for folders with spaces. ([GH-3304])
  - core: Can add boxes with spaces in their path. ([GH-3306])
  - core: Prerelease plugins installed are locked to that prerelease
      version. ([GH-3301])
  - core: Better error message when adding a box with a malformed version. ([GH-3332])
  - core: Fix a rare issue where vagrant up would complain it couldn't
      check version of a box that doesn't exist. ([GH-3326])
  - core: Box version constraint can't be specified with old-style box. ([GH-3260])
  - commands/box: Show versions when listing. ([GH-3316])
  - commands/box: Outdated check can list local boxes that are newer. ([GH-3321])
  - commands/status: Machine readable output contains the target. ([GH-3218])
  - guests/arch: Reload udev rules after network change. ([GH-3322])
  - guests/debian: Changing host name works properly. ([GH-3283])
  - guests/suse: Shutdown works correctly on SLES ([GH-2775])
  - hosts/linux: Don't hardcode `exportfs` path. Now searches the PATH. ([GH-3292])
  - providers/hyperv: Resume command works properly. ([GH-3336])
  - providers/virtualbox: Add missing translation for stopping status. ([GH-3368])
  - providers/virtualbox: Host-only networks set cableconnected property
      to "yes" ([GH-3365])
  - provisioners/docker: Use proper flags for 0.9. ([GH-3356])
  - synced\_folders/rsync: Set chmod flag by default on Windows. ([GH-3256])
  - synced\_folders/smb: IDs of synced folders are hashed to work better
      with VMware. ([GH-3219])
  - synced\_folders/smb: Properly remove existing folders with the
      same name. ([GH-3354])
  - synced\_folders/smb: Passwords with symbols now work. ([GH-3242])
  - synced\_folders/smb: Exporting works for non-english locale Windows
      machines. ([GH-3251])

## 1.5.1 (March 13, 2014)

IMPROVEMENTS:

  - guests/tinycore: Will now auto-install rsync.
  - synced\_folders/rsync: rsync-auto will not watch filesystem for
    excluded paths. ([GH-3159])

BUG FIXES:

  - core: V1 Vagrantfiles can upgrade provisioners properly. ([GH-3092])
  - core: Rare EINVAL errors on box adding are gone. ([GH-3094])
  - core: Upgrading the home directory for Vagrant 1.5 uses the Vagrant
    temp dir. ([GH-3095])
  - core: Assume a box isn't metadata if it exceeds 20 MB. ([GH-3107])
  - core: Asking for input works even in consoles that don't support
    hiding input. ([GH-3119])
  - core: Adding a box by path in Cygwin on Windows works. ([GH-3132])
  - core: PowerShell scripts work when they're in a directory with
    spaces. ([GH-3100])
  - core: If you add a box path that doesn't exist, error earlier. ([GH-3091])
  - core: Validation on forwarded ports to make sure they're between
    0 and 65535. ([GH-3187])
  - core: Downloads with user/password use the curl `-u` flag. ([GH-3183])
  - core: `vagrant help` no longer loads the Vagrantfile. ([GH-3180])
  - guests/darwin: Fix an exception when configuring networks. ([GH-3143])
  - guests/linux: Only chown folders/files in rsync if they don't
    have the proper owner. ([GH-3186])
  - hosts/linux: Unusual sed delimiter to avoid conflicts. ([GH-3167])
  - providers/virtualbox: Make more internal interactions with VBoxManage
    retryable to avoid spurious VirtualBox errors. ([GH-2831])
  - providers/virtualbox: Import progress works again on Windows.
  - provisioners/ansible: Request SSH info within the provision method,
    when we know its available. ([GH-3111])
  - synced\_folders/rsync: owner/group settings work. ([GH-3163])

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
    provider overrides. See documentation for more info. ([GH-1113])
  - providers/virtualbox: Provider-specific configuration `cpus` can be used
    to set the number of CPUs on the VM ([GH-2800])
  - provisioners/docker: Can now build images using `docker build`. ([GH-2615])

IMPROVEMENTS:

  - core: Added "error-exit" type to machine-readable output which contains
    error information that caused a non-zero exit status. ([GH-2999])
  - command/destroy: confirmation will re-ask question if bad input. ([GH-3027])
  - guests/solaris: More accurate Solaris >= 11, < 11 detection. ([GH-2824])
  - provisioners/ansible: Generates a single inventory file, rather than
    one per machine. See docs for more info. ([GH-2991])
  - provisioners/ansible: SSH forwarding support. ([GH-2952])
  - provisioners/ansible: Multiple SSH keys can now be attempted ([GH-2952])
  - provisioners/ansible: Disable SSH host key checking by default,
    which improves the experience. We believe this is a sane default
    for ephemeral dev machines.
  - provisioners/chef-solo: New config `synced_folder_type` replaces the
    `nfs` option. This can be used to set the synced folders the provisioner
    needs to any type. ([GH-2709])
  - provisioners/chef-solo: `roles_paths` can now be an array of paths in
    Chef 11.8.0 and newer. ([GH-2975])
  - provisioners/docker: Can start a container without daemonization.
  - provisioners/docker: Started containers are given names. ([GH-3051])
  - provisioners/puppet: New config `synced_folder_type` replaces the
    `nfs` option. This can be used to set the synced folders the provisioner
    needs to any type. ([GH-2709])
  - commands/plugin: `vagrant plugin update` will now update all installed
    plugins, respecting any constraints set.
  - commands/plugin: `vagrant plugin uninstall` can now uninstall multiple
    plugins.
  - commands/plugin: `vagrant plugin install` can now install multiple
    plugins.
  - hosts/redhat: Recognize Korora OS. ([GH-2869])
  - synced\_folders/nfs: If the guest supports it, NFS clients will be
    automatically installed in the guest.

BUG FIXES:

  - core: If an exception was raised while attempting to connect to SSH
    for the first time, it would get swallowed. It is properly raised now.
  - core: Plugin installation does not fail if your local gemrc file has
    syntax errors.
  - core: Plugins that fork within certain actions will no longer hang
    indefinitely. ([GH-2756])
  - core: Windows checks home directory permissions more correctly to
    warn of potential issues.
  - core: Synced folders set to the default synced folder explicitly won't
    be deleted. ([GH-2873])
  - core: Static IPs can end in ".1". A warning is now shown. ([GH-2914])
  - core: Adding boxes that have directories in them works on Windows.
  - core: Vagrant will not think provisioning is already done if
    the VM is manually deleted outside of Vagrant.
  - core: Box file checksums of large files works properly on Windows.
    ([GH-3045])
  - commands/box: Box add `--force` works with `--provider` flag. ([GH-2757])
  - commands/box: Listing boxes with machine-readable output crash is gone.
  - commands/plugin: Plugin installation will fail if dependencies conflict,
    rather than at runtime.
  - commands/ssh: When using `-c` on Windows, no more TTY errors.
  - commands/ssh-config: ProxyCommand is included in output if it is
    set. ([GH-2950])
  - guests/coreos: Restart etcd after configuring networks. ([GH-2852])
  - guests/linux: Don't chown VirtualBox synced folders if mounting
    as readonly. ([GH-2442])
  - guests/redhat: Set hostname to FQDN, per the documentation for RedHat.
    ([GH-2792])
  - hosts/bsd: Don't invoke shell for NFS sudo calls. ([GH-2808])
  - hosts/bsd: Sort NFS exports to avoid false validation errors. ([GH-2927])
  - hosts/bsd: No more checkexports NFS errors if you're sharing the
    same directory. ([GH-3023])
  - hosts/gentoo: Look for systemctl in `/usr/bin` ([GH-2858])
  - hosts/linux: Properly escape regular expression to prune NFS exports,
    allowing VMware to work properly. ([GH-2934])
  - hosts/opensuse: Start NFS server properly. ([GH-2923])
  - providers/virtualbox: Enabling internal networks by just setting "true"
    works properly. ([GH-2751])
  - providers/virtualbox: Make more internal interactions with VBoxManage
    retryable to avoid spurious VirtualBox errors. ([GH-2831])
  - providers/virtualbox: Config validation catches invalid keys. ([GH-2843])
  - providers/virtualbox: Fix network adapter configuration issue if using
    provider-specific config. ([GH-2854])
  - providers/virtualbox: Bridge network adapters always have their
    "cable connected" properly. ([GH-2906])
  - provisioners/chef: When chowning folders, don't follow symlinks.
  - provisioners/chef: Encrypted data bag secrets also in Chef solo are
    now uploaded to the provisioning path to avoid perm issues. ([GH-2845])
  - provisioners/chef: Encrypted data bag secret is removed from the
    machine before and after provisioning also with Chef client. ([GH-2845])
  - provisioners/chef: Set `encrypted_data_bag_secret` on the VM to `nil`
    if the secret is not specified. ([GH-2984])
  - provisioners/chef: Fix loading of the custom configure file. ([GH-876])
  - provisioners/docker: Only add SSH user to docker group if the user
    isn't already in it. ([GH-2838])
  - provisioners/docker: Configuring autostart works properly with
    the newest versions of Docker. ([GH-2874])
  - provisioners/puppet: Append default module path to the module paths
    always. ([GH-2677])
  - provisioners/salt: Setting pillar data doesn't require `deep_merge`
    plugin anymore. ([GH-2348])
  - provisioners/salt: Options can now set install type and install args.
    ([GH-2766])
  - provisioners/salt: Fix case when salt would say "options only allowed
    before install arguments" ([GH-3005])
  - provisioners/shell: Error if script is encoded incorrectly. ([GH-3000])
  - synced\_folders/nfs: NFS entries are pruned on every `vagrant up`,
    if there are any to prune. ([GH-2738])

## 1.4.3 (January 2, 2014)

BUG FIXES:

  - providers/virtualbox: `vagrant package` works properly again. ([GH-2739])

## 1.4.2 (December 31, 2013)

IMPROVEMENTS:

  - guests/linux: emit upstart event when NFS folders are mounted. ([GH-2705])
  - provisioners/chef-solo: Encrypted data bag secret is removed from the
    machine after provisioning. ([GH-2712])

BUG FIXES:

  - core: Ctrl-C no longer raises "trap context" exception.
  - core: The version for `Vagrant.configure` can now be an int. ([GH-2689])
  - core: `Vagrant.has_plugin?` tries to use plugin's gem name before
    registered plugin name ([GH-2617])
  - core: Fix exception if an EOFError was somehow raised by Ruby while
    checking a box checksum. ([GH-2716])
  - core: Better error message if your plugin state file becomes corrupt
    somehow. ([GH-2694])
  - core: Box add will fail early if the box already exists. ([GH-2621])
  - hosts/bsd: Only run `nfsd checkexports` if there is an exports file.
    ([GH-2714])
  - commands/plugin: Fix exception that could happen rarely when installing
    a plugin.
  - providers/virtualbox: Error when packaging if the package already exists
    _before_ the export is done. ([GH-2380])
  - providers/virtualbox: NFS with static IP works even if VirtualBox
    guest additions aren't installed (regression). ([GH-2674])
  - synced\_folders/nfs: sudo will only ask for password one at a time
    when using a parallel provider ([GH-2680])

## 1.4.1 (December 18, 2013)

IMPROVEMENTS:

  - hosts/bsd: check NFS exports file for issues prior to exporting
  - provisioners/ansible: Add ability to use Ansible groups in generated
    inventory ([GH-2606])
  - provisioners/docker: Add support for using the provisioner with RedHat
    based guests ([GH-2649])
  - provisioners/docker: Remove "Docker" prefix from Client and Installer
    classes ([GH-2641])

BUG FIXES:

  - core: box removal of a V1 box works
  - core: `vagrant ssh -c` commands are now executed in the context of
    a login shell (regression). ([GH-2636])
  - core: specifying `-t` or `-T` to `vagrant ssh -c` as extra args
    will properly enable/disable a TTY for OpenSSH. ([GH-2618])
  - commands/init: Error if can't write Vagrantfile to directory. ([GH-2660])
  - guests/debian: fix `use_dhcp_assigned_default_route` to work properly.
    ([GH-2648])
  - guests/debian,ubuntu: fix change\_host\_name for FQDNs with trailing
    dots ([GH-2610])
  - guests/freebsd: configuring networks in the guest works properly
    ([GH-2620])
  - guests/redhat: fix configure networks bringing down interfaces that
    don't exist. ([GH-2614])
  - providers/virtualbox: Don't override NFS exports for all VMs when
    coming up. ([GH-2645])
  - provisioners/ansible: Array arguments work for raw options ([GH-2667])
  - provisioners/chef-client: Fix node/client deletion when node\_name is not
    set. ([GH-2345])
  - provisioners/chef-solo: Force remove files to avoid cases where
    a prompt would be shown to users. ([GH-2669])
  - provisioners/puppet: Don't prepend default module path for Puppet
    in case Puppet is managing its own paths. ([GH-2677])

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
  - VirtualBox internal networks are now supported. ([GH-2020])

IMPROVEMENTS:

  - core: Support resumable downloads ([GH-57])
  - core: owner/group of shared folders can be specified by integers. ([GH-2390])
  - core: the VAGRANT\_NO\_COLOR environmental variable may be used to enable
    `--no-color` mode globally. ([GH-2261])
  - core: box URL and add date is tracked and shown if `-i` flag is
    specified for `vagrant box list` ([GH-2327])
  - core: Multiple SSH keys can be specified with `config.ssh.private_key_path`
    ([GH-907])
  - core: `config.vm.box_url` can be an array of URLs. ([GH-1958])
  - commands/box/add: Can now specify a custom CA cert for verifying
    certs from a custom CA. ([GH-2337])
  - commands/box/add: Can now specify a client cert when downloading a
    box. ([GH-1889])
  - commands/init: Add `--output` option for specifying output path, or
    "-" for stdin. ([GH-1364])
  - commands/provision: Add `--no-parallel` option to disable provider
    parallelization if the provider supports it. ([GH-2404])
  - commands/ssh: SSH compression is enabled by default. ([GH-2456])
  - commands/ssh: Inline commands specified with "-c" are now executed
    using OpenSSH rather than pure-Ruby SSH. It is MUCH faster, and
    stdin works!
  - communicators/ssh: new configuration `config.ssh.pty` is a boolean for
    whether you want ot use a PTY for provisioning.
  - guests/linux: emit upstart event `vagrant-mounted` if upstart is
    available. ([GH-2502])
  - guests/pld: support changing hostname ([GH-2543])
  - providers/virtualbox: Enable symlinks for VirtualBox 4.1. ([GH-2414])
  - providers/virtualbox: default VM name now includes milliseconds with
    a random number to try to avoid conflicts in CI environments. ([GH-2482])
  - providers/virtualbox: customizations via VBoxManage are retried, avoiding
    VirtualBox flakiness ([GH-2483])
  - providers/virtualbox: NFS works with DHCP host-only networks now. ([GH-2560])
  - provisioners/ansible: allow files for extra vars ([GH-2366])
  - provisioners/puppet: client cert and private key can now be specified
    for the puppet server provisioner. ([GH-902])
  - provisioners/puppet: the manifests path can be in the VM. ([GH-1805])
  - provisioners/shell: Added `keep_color` option to not automatically color
    output based on stdout/stderr. ([GH-2505])
  - provisioners/shell: Arguments can now be an array of args. ([GH-1949])
  - synced\_folders/nfs: Specify `nfs_udp` to false to disable UDP based
    NFS folders. ([GH-2304])

BUG FIXES:

  - core: Make sure machine IDs are always strings. ([GH-2434])
  - core: 100% CPU spike when waiting for SSH is fixed. ([GH-2401])
  - core: Command lookup works on systems where PATH is not valid UTF-8 ([GH-2514])
  - core: Human-friendly error if box metadata.json becomes corrupted. ([GH-2305])
  - core: Don't load Vagrantfile on `vagrant plugin` commands, allowing
    Vagrantfiles that use plugins to work. ([GH-2388])
  - core: global flags are ignored past the "--" on the CLI. ([GH-2491])
  - core: provisioning will properly happen if `up` failed. ([GH-2488])
  - guests/freebsd: Mounting NFS folders works. ([GH-2400])
  - guests/freebsd: Uses `sh` by default for shell. ([GH-2485])
  - guests/linux: upstart events listening for `vagrant-mounted` won't
    wait for jobs to complete, fixing issues with blocking during
    vagrant up ([GH-2564])
  - guests/redhat: `DHCP_HOSTNAME` is set to the hostname, not the FQDN. ([GH-2441])
  - guests/redhat: Down interface before messing up configuration file
    for networking. ([GH-1577])
  - guests/ubuntu: "localhost" is preserved when changing hostnames.
    ([GH-2383])
  - hosts/bsd: Don't set mapall if maproot is set in NFS. ([GH-2448])
  - hosts/gentoo: Support systemd for NFS startup. ([GH-2382])
  - providers/virtualbox: Don't start new VM if VirtualBox has transient
    failure during `up` from suspended. ([GH-2479])
  - provisioners/chef: Chef client encrypted data bag secrets are now
    uploaded to the provisioning path to avoid perm issues. ([GH-1246])
  - provisioners/chef: Create/chown the cache and backup folders. ([GH-2281])
  - provisioners/chef: Verify environment paths exist in config
    validation step. ([GH-2381])
  - provisioners/puppet: Multiple puppet definitions in a Vagrantfile
    work correctly.
  - provisioners/salt: Bootstrap on FreeBSD systems work. ([GH-2525])
  - provisioners/salt: Extra args for bootstrap are put in the proper
    location. ([GH-2558])

## 1.3.5 (October 15, 2013)

FEATURES:

  - VirtualBox 4.3 is now supported. ([GH-2374])
  - ESXi is now a supported guest OS. ([GH-2347])

IMPROVEMENTS:

  - guests/redhat: Oracle Linux is now supported. ([GH-2329])
  - provisioners/salt: Support running overstate. ([GH-2313])

BUG FIXES:

  - core: Fix some places where "no error message" errors were being
    reported when in fact there were errors. ([GH-2328])
  - core: Disallow hyphens or periods for starting hostnames. ([GH-2358])
  - guests/ubuntu: Setting hostname works properly. ([GH-2334])
  - providers/virtualbox: Retryable VBoxManage commands are properly
    retried. ([GH-2365])
  - provisioners/ansible: Verbosity won't be blank by default. ([GH-2320])
  - provisioners/chef: Fix exception raised during Chef client node
    cleanup. ([GH-2345])
  - provisioners/salt: Correct master seed file name. ([GH-2359])

## 1.3.4 (October 2, 2013)

FEATURES:

  - provisioners/shell: Specify the `binary` option as true and Vagrant won't
    automatically replace Windows line endings with Unix ones.  ([GH-2235])

IMPROVEMENTS:

  - guests/suse: Support installing CFEngine. ([GH-2273])

BUG FIXES:

  - core: Don't output `\e[0K` anymore on Windows. ([GH-2246])
  - core: Only modify `DYLD_LIBRARY_PATH` on Mac when executing commands
    in the installer context. ([GH-2231])
  - core: Clear `DYLD_LIBRARY_PATH` on Mac if the subprocess is executing
    a setuid or setgid script. ([GH-2243])
  - core: Defined action hook names can be strings now. They are converted
    to symbols internally.
  - guests/debian: FQDN is properly set when setting the hostname. ([GH-2254])
  - guests/linux: Fix poor chown command for mounting VirtualBox folders.
  - guests/linux: Don't raise exception right away if mounting fails, allow
    retries. ([GH-2234])
  - guests/redhat: Changing hostname changes DHCP_HOSTNAME. ([GH-2267])
  - hosts/arch: Vagrant won't crash on Arch anymore. ([GH-2233])
  - provisioners/ansible: Extra vars are converted to strings. ([GH-2244])
  - provisioners/ansible: Output will show up on a task-by-task basis. ([GH-2194])
  - provisioners/chef: Propagate disabling color if Vagrant has no color
    enabled. ([GH-2246])
  - provisioners/chef: Delete from chef server exception fixed. ([GH-2300])
  - provisioners/puppet: Work with restrictive umask. ([GH-2241])
  - provisioners/salt: Remove bootstrap definition file on each run in
    order to avoid permissions issues. ([GH-2290])

## 1.3.3 (September 18, 2013)

BUG FIXES:

  - core: Fix issues with dynamic linker not finding symbols on OS X. ([GH-2219])
  - core: Properly clean up machine directories on destroy. ([GH-2223])
  - core: Add a timeout to waiting for SSH connection and server headers
    on SSH. ([GH-2226])

## 1.3.2 (September 17, 2013)

IMPROVEMENTS:

  - provisioners/ansible: Support more verbosity levels, better documentation.
    ([GH-2153])
  - provisioners/ansible: Add `host_key_checking` configuration. ([GH-2203])

BUG FIXES:

  - core: Report the proper invalid state when waiting for the guest machine
    to be ready
  - core: `Guest#capability?` now works with strings as well
  - core: Fix NoMethodError in the new `Vagrant.has_plugin?` method ([GH-2189])
  - core: Convert forwarded port parameters to integers. ([GH-2173])
  - core: Don't spike CPU to 100% while waiting for machine to boot. ([GH-2163])
  - core: Increase timeout for individual SSH connection to 60 seconds. ([GH-2163])
  - core: Call realpath after creating directory so NFS directory creation
    works. ([GH-2196])
  - core: Don't try to be clever about deleting the machine state
    directory anymore. Manually done in destroy actions. ([GH-2201])
  - core: Find the root Vagrantfile only if Vagrantfile is a file, not
    a directory. ([GH-2216])
  - guests/linux: Try `id -g` in addition to `getent` for mounting
    VirtualBox shared folders ([GH-2197])
  - hosts/arch: NFS exporting works properly, no exceptions. ([GH-2161])
  - hosts/bsd: Use only `sudo` for writing NFS exports. This lets NFS
    exports work if you have sudo privs but not `su`. ([GH-2191])
  - hosts/fedora: Fix host detection encoding issues. ([GH-1977])
  - hosts/linux: Fix NFS export problems with `no_subtree_check`. ([GH-2156])
  - installer/mac: Vagrant works properly when a library conflicts from
    homebrew. ([GH-2188])
  - installer/mac: deb/rpm packages now have an epoch of 1 so that new
    installers don't appear older. ([GH-2179])
  - provisioners/ansible: Default output level is now verbose again. ([GH-2194])
  - providers/virtualbox: Fix an issue where destroy middlewares weren't
    being properly called. ([GH-2200])

## 1.3.1 (September 6, 2013)

BUG FIXES:

  - core: Fix various issues where using the same options hash in a
    Vagrantfile can cause errors.
  - core: `VAGRANT_VAGRANTFILE` env var only applies to the project
    Vagrantfile name. ([GH-2130])
  - core: Fix an issue where the data directory would be deleted too
    quickly in a multi-VM environment.
  - core: Handle the case where we get an EACCES cleaning up the .vagrant
    directory.
  - core: Fix exception on upgrade warnings from V1 to V2. ([GH-2142])
  - guests/coreos: Proper IP detection. ([GH-2146])
  - hosts/linux: NFS exporting works properly again. ([GH-2137])
  - provisioners/chef: Work even with restrictive umask on user. ([GH-2121])
  - provisioners/chef: Fix environment validation to be less restrictive.
  - provisioners/puppet: No more "shared folders cannot be found" error.
    ([GH-2134])
  - provisioners/puppet: Work with restrictive umask on user by testing
    for folders with sudo. ([GH-2121])

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
   the `--provision` flag to provision. ([GH-1776])

FEATURES:

  - New command: `vagrant plugin update` to update specific installed plugins.
  - New provisioner: File provisioner. ([GH-2112])
  - New provisioner: Salt provisioner. ([GH-1626])
  - New guest: Mac OS X guest support. ([GH-1914])
  - New guest: CoreOS guest support. Change host names and configure networks on
    CoreOS. ([GH-2022])
  - New guest: Solaris 11 guest support. ([GH-2052])
  - Support for environments in the Chef-solo provisioner. ([GH-1915])
  - Provisioners can now define "cleanup" tasks that are executed on
    `vagrant destroy`. ([GH-1302])
  - Chef Client provisioner will now clean up the node/client using
    `knife` if configured to do so.
  - `vagrant up` has a `--no-destroy-on-error` flag that will not destroy
    the VM if a fatal error occurs. ([GH-2011])
  - NFS: Arbitrary mount options can be specified using the
   `mount_options` option on synced folders. ([GH-1029])
  - NFS: Arbitrary export options can be specified using
   `bsd__nfs_options` and `linux__nfs_options`. ([GH-1029])
  - Static IP can now be set on public networks. ([GH-1745])
  - Add `Vagrant.has_plugin?` method for use in Vagrantfile to check
    if a plugin is installed. ([GH-1736])
  - Support for remote shell provisioning scripts ([GH-1787])

IMPROVEMENTS:

  - core: add `--color` to any Vagrant command to FORCE color output. ([GH-2027])
  - core: "config.vm.host_name" works again, just an alias to hostname.
  - core: Reboots via SSH are now handled gracefully (without exception).
  - core: Mark `disabled` as true on forwarded port to disable. ([GH-1922])
  - core: NFS exports are now namespaced by user ID, so pruning NFS won't
    remove exports from other users. ([GH-1511])
  - core: "vagrant -v" no longer loads the Vagrantfile
  - commands/box/remove: Fix stack trace that happens if no provider
    is specified. ([GH-2100])
  - commands/plugin/install: Post install message of a plugin will be
    shown if available. ([GH-1986])
  - commands/status: cosmetic improvement to better align names and
    statuses ([GH-2016])
  - communicators/ssh: Support a proxy_command. ([GH-1537])
  - guests/openbsd: support configuring networks, changing host name,
    and mounting NFS. ([GH-2086])
  - guests/suse: Supports private/public networks. ([GH-1689])
  - hosts/fedora: Support RHEL as a host. ([GH-2088])
  - providers/virtualbox: "post-boot" customizations will run directly
    after boot, and before waiting for SSH. ([GH-2048])
  - provisioners/ansible: Many more configuration options. ([GH-1697])
  - provisioners/ansible: Ansible `inventory_path` can be a directory now. ([GH-2035])
  - provisioners/ansible: Extra verbose option by setting `config.verbose`
    to `extra`. ([GH-1979])
  - provisioners/ansible: `inventory_path` will be auto-generated if not
    specified. ([GH-1907])
  - provisioners/puppet: Add `nfs` option to puppet provisioner. ([GH-1308])
  - provisioners/shell: Set the `privileged` option to false to run
    without sudo. ([GH-1370])

BUG FIXES:

  - core: Clean up ".vagrant" folder more effectively.
  - core: strip newlines off of ID file values ([GH-2024])
  - core: Multiple forwarded ports with different protocols but the same
    host port can be specified. ([GH-2059])
  - core: `:nic_type` option for private networks is respected. ([GH-1704])
  - commands/up: provision-with validates the provisioners given. ([GH-1957])
  - guests/arch: use systemd way of setting host names. ([GH-2041])
  - guests/debian: Force bring up eth0. Fixes hangs on setting hostname.
   ([GH-2026])
  - guests/ubuntu: upstart events are properly emitted again. ([GH-1717])
  - hosts/bsd: Nicer error if can't read NFS exports. ([GH-2038])
  - hosts/fedora: properly detect later CentOS versions. ([GH-2008])
  - providers/virtualbox: VirtualBox 4.2 now supports up to 36
    network adapters. ([GH-1886])
  - provisioners/ansible: Execute ansible with a cwd equal to the
    path where the Vagrantfile is. ([GH-2051])
  - provisioners/all: invalid config keys will be properly reported. ([GH-2117])
  - provisioners/ansible: No longer report failure on every run. ([GH-2007])
  - provisioners/ansible: Properly handle extra vars with spaces. ([GH-1984])
  - provisioners/chef: Formatter option works properly. ([GH-2058])
  - provisioners/chef: Create/chown the provisioning folder before
    reading contents. ([GH-2121])
  - provisioners/puppet: mount synced folders as root to avoid weirdness
  - provisioners/puppet: Run from the correct working directory. ([GH-1967])
    with Puppet. ([GH-2015])
  - providers/virtualbox: Use `getent` to get the group ID instead of
    `id` in case the name doesn't have a user. ([GH-1801])
  - providers/virtualbox: Will only set the default name of the VM on
    initial `up`. ([GH-1817])

## 1.2.7 (July 28, 2013)

BUG FIXES:

  - On Windows, properly convert synced folder host path to a string
    so that separator replacement works properly.
  - Use `--color=false` for no color in Puppet to support older
    versions properly. ([GH-2000])
  - Make sure the hostname configuration is a string. ([GH-1999])
  - cURL downloads now contain a user agent which fixes some
    issues with downloading Vagrant through proxies. ([GH-2003])
  - `vagrant plugin install` will now always properly show the actual
    installed gem name. ([GH-1834])

## 1.2.6 (July 26, 2013)

BUG FIXES:

  - Box collections with multiple formats work properly by converting
    the supported formats to symbols. ([GH-1990])

## 1.2.5 (July 26, 2013)

FEATURES:

  - `vagrant help <command>` now works. ([GH-1578])
  - Added `config.vm.box_download_insecure` to allow the box_url setting
    to point to an https site that won't be validated. ([GH-1712])
  - VirtualBox VBoxManage customizations can now be specified to run
    pre-boot (the default and existing functionality, pre-import,
    or post-boot. ([GH-1247])
  - VirtualBox no longer destroys unused network interfaces by default.
    This didn't work across multi-user systems and required admin privileges
    on Windows, so it has been disabled by default. It can be enabled using
    the VirtualBox provider-specific `destroy_unused_network_interfaces`
    configuration by setting it to true. ([GH-1324])

IMPROVEMENTS:

  - Remote commands that fail will now show the stdout/stderr of the
    command that failed. ([GH-1203])
  - Puppet will run without color if the UI is not colored. ([GH-1344])
  - Chef supports the "formatter" configuration for setting the
    formatter. ([GH-1250])
  - VAGRANT_DOTFILE_PATH environmental variable reintroduces the
    functionality removed in 1.1 from "config.dotfile_name" ([GH-1524])
  - Vagrant will show an error if VirtualBox 4.2.14 is running.
  - Added provider to BoxNotFound error message. ([GH-1692])
  - If Ansible fails to run properly, show an error message. ([GH-1699])
  - Adding a box with the `--provider` flag will now allow a box for
    any of that provider's supported formats.
  - NFS mounts enable UDP by default, resulting in higher performance.
    (Because mount is over local network, packet loss is not an issue)
   ([GH-1706])

BUG FIXES:

  - `box_url` now handles the case where the provider doesn't perfectly
    match the provider in use, but the provider supports it. ([GH-1752])
  - Fix uninitialized constant error when configuring Arch Linux network. ([GH-1734])
  - Debian/Ubuntu change hostname works properly if eth0 is configured
    with hot-plugging. ([GH-1929])
  - NFS exports with improper casing on Mac OS X work properly. ([GH-1202])
  - Shared folders overriding '/vagrant' in multi-VM environments no
    longer all just use the last value. ([GH-1935])
  - NFS export fsid's are now 32-bit integers, rather than UUIDs. This
    lets NFS exports work with Linux kernels older than 2.6.20. ([GH-1127])
  - NFS export allows access from all private networks on the VM. ([GH-1204])
  - Default VirtualBox VM name now contains the machine name as defined
    in the Vagrantfile, helping differentiate multi-VM. ([GH-1281])
  - NFS works properly on CentOS hosts. ([GH-1394])
  - Solaris guests actually shut down properly. ([GH-1506])
  - All provisioners only output newlines when the provisioner sends a
    newline. This results in the output looking a lot nicer.
  - Sharing folders works properly if ".profile" contains an echo. ([GH-1677])
  - `vagrant ssh-config` IdentityFile is only wrapped in quotes if it
    contains a space. ([GH-1682])
  - Shared folder target path can be a Windows path. ([GH-1688])
  - Forwarded ports don't auto-correct by default, and will raise an
    error properly if they collide. ([GH-1701])
  - Retry SSH on ENETUNREACH error. ([GH-1732])
  - NFS is silently ignored on Windows. ([GH-1748])
  - Validation so that private network static IP does not end in ".1" ([GH-1750])
  - With forward agent enabled and sudo being used, Vagrant will automatically
    discover and set `SSH_AUTH_SOCK` remotely so that forward agent
    works properly despite misconfigured sudoers. ([GH-1307])
  - Synced folder paths on Windows containing '\' are replaced with
    '/' internally so that they work properly.
  - Unused config objects are finalized properly. ([GH-1877])
  - Private networks work with Fedora guests once again. ([GH-1738])
  - Default internal encoding of strings in Vagrant is now UTF-8, allowing
    detection of Fedora to work again (which contained a UTF-8 string). ([GH-1977])

## 1.2.4 (July 16, 2013)

FEATURES:

  - Chef solo and client provisioning now support a `custom_config_path`
    setting that accepts a path to a Ruby file to load as part of Chef
    configuration, allowing you to override any setting available. ([GH-876])
  - CFEngine provisioner: you can now specify the package name to install,
    so CFEngine enterprise is supported. ([GH-1920])

IMPROVEMENTS:

  - `vagrant box remove` works with only the name of the box if that
    box exists only backed by one provider. ([GH-1032])
  - `vagrant destroy` returns exit status 1 if any of the confirmations
    are declined. ([GH-923])
  - Forwarded ports can specify a host IP and guest IP to bind to. ([GH-1121])
  - You can now set the "ip" of a private network that uses DHCP. This will
    change the subnet and such that the DHCP server uses.
  - Add `file_cache_path` support for chef_solo. ([GH-1897])

BUG FIXES:

  - VBoxManage or any other executable missing from PATH properly
    reported. Regression from 1.2.2. ([GH-1928])
  - Boxes downloaded as part of `vagrant up` are now done so _prior_ to
    config validation. This allows Vagrantfiles to references files that
    may be in the box itself. ([GH-1061])
  - Chef removes dna.json and encrypted data bag secret file prior to
    uploading. ([GH-1111])
  - NFS synced folders exporting sub-directories of other exported folders now
    works properly. ([GH-785])
  - NFS shared folders properly dereference symlinks so that the real path
    is used, avoiding mount errors ([GH-1101])
  - SSH channel is closed after the exit status is received, potentially
    eliminating any SSH hangs. ([GH-603])
  - Fix regression where VirtualBox detection wasn't working anymore. ([GH-1918])
  - NFS shared folders with single quotes in their name now work properly. ([GH-1166])
  - Debian/Ubuntu request DHCP renewal when hostname changes, which will
    fix issues with FQDN detecting. ([GH-1929])
  - SSH adds the "DSAAuthentication=yes" option in case that is disabled
    on the user's system. ([GH-1900])

## 1.2.3 (July 9, 2013)

FEATURES:

  - Puppet provisioner now supports Hiera by specifying a `hiera_config_path`.
  - Added a `working_directory` configuration option to the Puppet apply
    provisioner so you can specify the working directory when `puppet` is
    called, making it friendly to Hiera data and such. ([GH-1670])
  - Ability to specify the host IP to bind forwarded ports to. ([GH-1785])

IMPROVEMENTS:

  - Setting hostnames works properly on OmniOS. ([GH-1672])
  - Better VBoxManage error detection on Windows systems. This avoids
    some major issues where Vagrant would sometimes "lose" your VM. ([GH-1669])
  - Better detection of missing VirtualBox kernel drivers on Linux
    systems. ([GH-1671])
  - More precise detection of Ubuntu/Debian guests so that running Vagrant
    within an LXC container works properly now.
  - Allow strings in addition to symbols to more places in V1 configuration
    as well as V2 configuration.
  - Add `ARPCHECK=0` to RedHat OS family network configuration. ([GH-1815])
  - Add SSH agent forwarding sample to initial Vagrantfile. ([GH-1808])
  - VirtualBox: Only configure networks if there are any to configure.
    This allows linux's that don't implement this capability to work with
    Vagrant. ([GH-1796])
  - Default SSH forwarded port now binds to 127.0.0.1 so only local
    connections are allowed. ([GH-1785])
  - Use `netctl` for Arch Linux network configuration. ([GH-1760])
  - Improve fedora host detection regular expression. ([GH-1913])
  - SSH shows a proper error on EHOSTUNREACH. ([GH-1911])

BUG FIXES:

  - Ignore "guest not ready" errors when attempting to graceful halt and
    carry on checks whether the halt succeeded. ([GH-1679])
  - Handle the case where a roles path for Chef solo isn't properly
    defined. ([GH-1665])
  - Finding V1 boxes now works properly again to avoid "box not found"
    errors. ([GH-1691])
  - Setting hostname on SLES 11 works again. ([GH-1781])
  - `config.vm.guest` properly forces guests again. ([GH-1800])
  - The `read_ip_address` capability for linux properly reads the IP
    of only the first network interface. ([GH-1799])
  - Validate that an IP is given for a private network. ([GH-1788])
  - Fix uninitialized constant error for Gentoo plugin. ([GH-1698])

## 1.2.2 (April 23, 2013)

FEATURES:

  - New `DestroyConfirm` built-in middleware for providers so they can
    more easily conform to the `destroy` action.

IMPROVEMENTS:

  - No longer an error if the Chef run list is empty. It is now
    a warning. ([GH-1620])
  - Better locking around handling the `box_url` parameter for
    parallel providers.
  - Solaris guest is now properly detected on SmartOS, OmniOS, etc. ([GH-1639])
  - Guest addition version detection is more robust, attempting other
    routes to get the version, and also retrying a few times. ([GH-1575])

BUG FIXES:

  - `vagrant package --base` works again. ([GH-1615])
  - Box overrides specified in provider config overrides no longer
    fail to detect the box. ([GH-1617])
  - In a multi-machine environment, a box not found won't be downloaded
    multiple times. ([GH-1467])
  - `vagrant box add` with a file path now works correctly on Windows
    when a drive letter is specified.
  - DOS line endings are converted to Unix line endings for the
    shell provisioner automatically. ([GH-1495])

## 1.2.1 (April 17, 2013)

FEATURES:

  - Add a `--[no-]parallel` flag to `vagrant up` to enable/disable
    parallelism. Vagrant will parallelize by default.

IMPROVEMENTS:

  - Get rid of arbitrary 4 second sleep when connecting via SSH. The
    issue it was attempting to work around may be gone now.

BUG FIXES:

  - Chef solo run list properly set. ([GH-1608])
  - Follow 30x redirects when downloading boxes. ([GH-1607])
  - Chef client config defaults are done properly. ([GH-1609])
  - VirtualBox mounts shared folders with the proper owner/group. ([GH-1611])
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
  - Ansible provisioner support. ([GH-1465])
  - Providers can now support multiple box formats by specifying the
    `box_format:` option.
  - CFEngine provisioner support.
  - `config.ssh.default` settings introduced to set SSH defaults that
    providers can still override. ([GH-1479])

IMPROVEMENTS:

  - Full Windows support in cmd.exe, PowerShell, Cygwin, and MingW based
    environments.
  - By adding the "disabled" boolean flag to synced folders you can disable
    them altogether. ([GH-1004])
  - Specify the default provider with the `VAGRANT_DEFAULT_PROVIDER`
    environmental variable. ([GH-1478])
  - Invalid settings are now caught and shown in a user-friendly way. ([GH-1484])
  - Detect PuTTY Link SSH client on Windows and show an error. ([GH-1518])
  - `vagrant ssh` in Cygwin won't output DOS path file warnings.
  - Add `--rtcuseutc on` as a sane default for VirtualBox. ([GH-912])
  - SSH will send keep-alive packets every 5 seconds by default to
    keep connections alive. Can be disabled with `config.ssh.keep_alive`. ([GH-516])
  - Show a message on `vagrant up` if the machine is already running. ([GH-1558])
  - "Running provisioner" output now shoes the provisioner shortcut name,
    rather than the less-than-helpful class name.
  - Shared folders with the same guest path will overwrite each other. No
    more shared folder IDs.
  - Shell provisioner outputs script it is running. ([GH-1568])
  - Automatically merge forwarded ports that share the same host
    port.

BUG FIXES:

  - The `:mac` option for host-only networks is respected. ([GH-1536])
  - Don't preserve modified time when untarring boxes. ([GH-1539])
  - Forwarded port auto-correct will not auto-correct to a port
    that is also in use.
  - Cygwin will always output color by default. Specify `--no-color` to
    override this.
  - Assume Cygwin has a TTY for asking for input. ([GH-1430])
  - Expand Cygwin paths to Windows paths for calls to VBoxManage and
    for VirtualBox shared folders.
  - Output the proper clear line text for shells in Cygwin when
    reporting dynamic progress.
  - When using `Builder` instances for hooks, the builders will be
    merged for the proper before/after chain. ([GH-1555])
  - Use the Vagrant temporary directory again for temporary files
    since they can be quite large and were messing with tmpfs. ([GH-1442])
  - Fix issue parsing extra SSH args in `vagrant ssh` in multi-machine
    environments. ([GH-1545])
  - Networks come back up properly on RedHat systems after reboot. ([GH-921])
  - `config.ssh` settings override all detected SSH settings (regression). ([GH-1479])
  - `ssh-config` won't raise an exception if the VirtualBox machine
    is not created. ([GH-1562])
  - Multiple machines defined in the same Vagrantfile with the same
    name will properly merge.
  - More robust hostname checking for RedHat. ([GH-1566])
  - Cookbook path existence for Chef is no longer an error, so that
    things like librarian and berkshelf plugins work properly. ([GH-1570])
  - Chef solo provisioner uses proper SSH username instead of hardcoded
    config. ([GH-1576])
  - Shell provisioner takes ownership of uploaded files properly so
    that they can also be manually executed later. ([GH-1576])

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

  - Proper error message if invalid provisioner is used. ([GH-1515])
  - Don't error on graceful halt if machine just shut down very
    quickly. ([GH-1505])
  - Error message if private key for SSH isn't owned by the proper
    user. ([GH-1503])
  - Don't error too early when `config.vm.box` is not properly set.
  - Show a human-friendly error if VBoxManage is not found (exit
    status 126). ([GH-934])
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
    even while specifying custom module paths. ([GH-1207])
  - Re-added DHCP support for host-only networks. ([GH-1466])
  - Ability to specify a plugin version, plugin sources, and
    pre-release versions using `--plugin-version`, `--plugin-source`,
    and `--plugin-prerelease`. ([GH-1461])
  - Move VirtualBox guest addition checks to after the machine
    boots. ([GH-1179])
  - Removed `Vagrant::TestHelpers` because it doesn't really work anymore.
  - Add PLX linux guest support. ([GH-1490])

BUG FIXES:

  - Attempt to re-establish SSH connection on `Net::SSH::Disconnect`
  - Allow any value that can convert to a string for `Vagrant.plugin`
  - Chef solo `recipe_url` works properly again. ([GH-1467])
  - Port collision detection works properly in VirtualBox with
    auto-corrected ports. ([GH-1472])
  - Fix obscure error when temp directory is world writable when
    adding boxes.
  - Improved error handling around network interface detection for
    VirtualBox ([GH-1480])

## 1.1.2 (March 18, 2013)

BUG FIXES:

  - When not specifying a cookbooks_path for chef-solo, an error won't
    be shown if "cookbooks" folder is missing.
  - Fix typo for exception when no host-only network with NFS. ([GH-1448])
  - Use UNSET_VALUE/nil with args on shell provisioner by default since
    `[]` was too truthy. ([GH-1447])

## 1.1.1 (March 18, 2013)

IMPROVEMENTS:

  - Don't load plugins on any `vagrant plugin` command, so that errors
    are avoided. ([GH-1418])
  - An error will be shown if you forward a port to the same host port
    multiple times.
  - Automatically convert network, provider, and provisioner names to
    symbols internally in case people define them as strings.
  - Using newer versions of net-ssh and net-scp. ([GH-1436])

BUG FIXES:

  - Quote keys to StringBlockEditor so keys with spaces, parens, and
    so on work properly.
  - When there is no route to host for SSH, re-establish a new connection.
  - `vagrant package` once again works, no more nil error. ([GH-1423])
  - Human friendly error when "metadata.json" is missing in a box.
  - Don't use the full path to the manifest file with the Puppet provisioner
    because it exposes a bug with Puppet path lookup on VMware.
  - Fix bug in VirtualBox provider where port forwarding just didn't work if
    you attempted to forward to a port under 1024. ([GH-1421])
  - Fix cross-device box adds for Windows. ([GH-1424])
  - Fix minor issues with defaults of configuration of the shell
    provisioner.
  - Fix Puppet server using "host_name" instead of "hostname" ([GH-1444])
  - Raise a proper error if no hostonly network is found for NFS with
    VirtualBox. ([GH-1437])

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
  - Allow "file://" URLs for box URLs. ([GH-1087])
  - Emit "vagrant-mount" upstart event when NFS shares are mounted. ([GH-1118])
  - Add a VirtualBox provider config `auto_nat_dns_proxy` which when set to
    false will not attempt to automatically manage NAT DNS proxy settings
    with VirtualBox. ([GH-1313])
  - `vagrant provision` accepts the `--provision-with` flag ([GH-1167])
  - Set the name of VirtualBox machines with `virtualbox.name` in the
    VirtualBox provider config. ([GH-1126])
  - `vagrant ssh` will execute an `ssh` binary on Windows if it is on
    your PATH. ([GH-933])
  - The environmental variable `VAGRANT_VAGRANTFILE` can be used to
    specify an alternate Vagrantfile filename.

IMPROVEMENTS / BUG FIXES:

  - Vagrant works much better in Cygwin environments on Windows by
    properly resolving Cygwin paths. ([GH-1366])
  - Improve the SSH "ready?" check by more gracefully handling timeouts. ([GH-841])
  - Human friendly error if connection times out for HTTP downloads. ([GH-849])
  - Detect when the VirtualBox installation is incomplete and error. ([GH-846])
  - Detect when kernel modules for VirtualBox need to be installed on Gentoo
    systems and report a user-friendly error. ([GH-710])
  - All `vagrant` commands that can take a target VM name can take one even
    if you're not in a multi-VM environment. ([GH-894])
  - Hostname is set before networks are setup to avoid very slow `sudo`
    speeds on CentOS. ([GH-922])
  - `config.ssh.shell` now includes the flags to pass to it, such as `-l` ([GH-917])
  - The check for whether a port is open or not is more complete by
    catching ENETUNREACH errors. ([GH-948])
  - SSH uses LogLevel FATAL so that errors are still shown.
  - Sending a SIGINT (Ctrl-C) very early on when executing `vagrant` no
    longer results in an ugly stack trace.
  - Chef JSON configuration output is now pretty-printed to be
    human readable. ([GH-1146])
    that SSHing succeeds when booting a machine.
  - VMs in the "guru meditation" state can be destroyed now using
    `vagrant destroy`.
  - Fix issue where changing SSH key permissions didn't properly work. ([GH-911])
  - Fix issue where Vagrant didn't properly detect VBoxManage on Windows
    if VBOX_INSTALL_PATH contained multiple paths. ([GH-885])
  - Fix typo in setting host name for Gentoo guests. ([GH-931])
  - Files that are included with `vagrant package --include` now properly
    preserve file attributes on earlier versions of Ruby. ([GH-951])
  - Multiple interfaces now work with Arch linux guests. ([GH-957])
  - Fix issue where subprocess execution would always spin CPU of Ruby
    process to 100%. ([GH-832])
  - Fix issue where shell provisioner would sometimes never end. ([GH-968])
  - Fix issue where puppet would reorder module paths. ([GH-964])
  - When console input is asked for (destroying a VM, bridged interfaces, etc.),
    keystrokes such as ctrl-D and ctrl-C are more gracefully handled. ([GH-1017])
  - Fixed bug where port check would use "localhost" on systems where
    "localhost" is not available. ([GH-1057])
  - Add missing translation for "saving" state on VirtualBox. ([GH-1110])
  - Proper error message if the remote end unexpectedly resets the connection
    while downloading a box over HTTP. ([GH-1090])
  - Human-friendly error is raised if there are permission issues when
    using SCP to upload files. ([GH-924])
  - Box adding doesn't use `/tmp` anymore which can avoid some cross-device
    copy issues. ([GH-1199])
  - Vagrant works properly in folders with strange characters. ([GH-1223])
  - Vagrant properly handles "paused" VirtualBox machines. ([GH-1184])
  - Better behavior around permissions issues when copying insecure
    private key. ([GH-580])

## 1.0.7 (March 13, 2013)

  - Detect if a newer version of Vagrant ran and error if it did,
    because we're not forward-compatible.
  - Check for guest additions version AFTER booting. ([GH-1179])
  - Quote IdentityFile in `ssh-config` so private keys with spaces in
    the path work. ([GH-1322])
  - Fix issue where multiple Puppet module paths can be re-ordered ([GH-964])
  - Shell provisioner won't hang on Windows anymore due to unclosed
    tempfile. ([GH-1040])
  - Retry setting default VM name, since it sometimes fails first time. ([GH-1368])
  - Support setting hostname on Suse ([GH-1063])

## 1.0.6 (December 21, 2012)

  - Shell provisioner outputs proper line endings on Windows ([GH-1164])
  - SSH upload opens file to stream which fixes strange upload issues.
  - Check for proper exit codes for Puppet, since multiple exit codes
    can mean success. ([GH-1180])
  - Fix issue where DNS doesn't resolve properly for 12.10. ([GH-1176])
  - Allow hostname to be a substring of the box name for Ubuntu ([GH-1163])
  - Use `puppet agent` instead of `puppetd` to be Puppet 3.x
    compatible. ([GH-1169])
  - Work around bug in VirtualBox exposed by bug in OS X 10.8 where
    VirtualBox executables couldn't handle garbage being injected into
    stdout by OS X.

## 1.0.5 (September 18, 2012)

  - Work around a critical bug in VirtualBox 4.2.0 on Windows that
    causes Vagrant to not work. ([GH-1130])
  - Plugin loading works better on Windows by using the proper
    file path separator.
  - NFS works on Fedora 16+. ([GH-1140])
  - NFS works with newer versions of Arch hosts that use systemd. ([GH-1142])

## 1.0.4 (September 13, 2012)

  - VirtualBox 4.2 driver. ([GH-1120])
  - Correct `ssh-config` help to use `--host`, not `-h`.
  - Use "127.0.0.1" instead of "localhost" for port checking to fix problem
    where "localhost" is not properly setup. ([GH-1057])
  - Disable read timeout on Net::HTTP to avoid `rbuf_fill` error. ([GH-1072])
  - Retry SSH on `EHOSTUNREACH` errors.
  - Add missing translation for "saving" state. ([GH-1110])

## 1.0.3 (May 1, 2012)

  - Don't enable NAT DNS proxy on machines where resolv.conf already points
    to localhost. This allows Vagrant to work once again with Ubuntu
    12.04. ([GH-909])

## 1.0.2 (March 25, 2012)

  - Provisioners will still mount folders and such if `--no-provision` is
    used, so that `vagrant provision` works. ([GH-803])
  - Nicer error message if an unsupported SSH key type is used. ([GH-805])
  - Gentoo guests can now have their host names changed. ([GH-796])
  - Relative paths can be used for the `config.ssh.private_key_path`
    setting. ([GH-808])
  - `vagrant ssh` now works on Solaris, where `IdentitiesOnly` was not
    an available option. ([GH-820])
  - Output works properly in the face of broken pipes. ([GH-819])
  - Enable Host IO Cache on the SATA controller by default.
  - Chef-solo provisioner now supports encrypted data bags. ([GH-816])
  - Enable the NAT DNS proxy by default, allowing your DNS to continue
    working when you switch networks. ([GH-834])
  - Checking for port forwarding collisions also checks for other applications
    that are potentially listening on that port as well. ([GH-821])
  - Multiple VM names can be specified for the various commands now. For
    example: `vagrant up web db service`. ([GH-795])
  - More robust error handling if a VM fails to boot. The error message
    is much clearer now. ([GH-825])

## 1.0.1 (March 11, 2012)

  - Installers are now bundled with Ruby 1.9.3p125. Previously they were
    bundled with 1.9.3p0. This actually fixes some IO issues with Windows.
  - Windows installer now outputs a `vagrant` binary that will work in msys
    or Cygwin environments.
  - Fix crashing issue which manifested itself in multi-VM environments.
  - Add missing `rubygems` require in `environment.rb` to avoid
    possible load errors. ([GH-781])
  - `vagrant destroy` shows a nice error when called without a
    TTY (and hence can't confirm). ([GH-779])
  - Fix an issue with the `:vagrantfile_name` option to `Vagrant::Environment`
    not working properly. ([GH-778])
  - `VAGRANT_CWD` environmental variable can be used to set the CWD to
    something other than the current directory.
  - Downloading boxes from servers that don't send a content-length
    now works properly. ([GH-788])
  - The `:facter` option now works for puppet server. ([GH-790])
  - The `--no-provision` and `--provision-with` flags are available to
    `vagrant reload` now.
  - `:openbsd` guest which supports only halting at the moment. ([GH-773])
  - `ssh-config -h` now shows help, instead of assuming a host is being
    specified. For host, you can still use `--host`. ([GH-793])

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
    overridden with the `--force` flag. ([GH-699])
  - Fix issue with Puppet config inheritance. ([GH-722])
  - Fix issue where starting a VM on some systems was incorrectly treated
    as failing. ([GH-720])
  - It is now an error to specify the packaging `output` as a directory. ([GH-730])
  - Unix-style line endings are used properly for guest OS. ([GH-727])
  - Retry certain VirtualBox operations, since they intermittently fail.
    ([GH-726])
  - Fix issue where Vagrant would sometimes "lose" a VM if an exception
    occurred. ([GH-725])
  - `vagrant destroy` destroys virtual machines in reverse order. ([GH-739])
  - Add an `fsid` option to Linux NFS exports. ([GH-736])
  - Fix edge case where an exception could be raised in networking code. ([GH-742])
  - Add missing translation for the "guru meditation" state. ([GH-745])
  - Check that VirtualBox exists before certain commands. ([GH-746])
  - NIC type can be defined for host-only network adapters. ([GH-750])
  - Fix issue where re-running chef-client would sometimes cause
    problems due to file permissions. ([GH-748])
  - FreeBSD guests can now have their hostnames changed. ([GH-757])
  - FreeBSD guests now support host only networking and bridged networking. ([GH-762])
  - `VM#run_action` is now public so plugin-devs can hook into it.
  - Fix crashing bug when attempting to run commands on the "primary"
    VM in a multi-VM environment. ([GH-761])
  - With puppet you can now specify `:facter` as a dictionary of facts to
    override what is generated by Puppet. ([GH-753])
  - Automatically convert all arguments to `customize` to strings.
  - openSUSE host system. ([GH-766])
  - Fix subprocess IO deadlock which would occur on Windows. ([GH-765])
  - Fedora 16 guest support. ([GH-772])

## 0.9.7 (February 9, 2012)

  - Fix regression where all subprocess IO simply didn't work with
    Windows. ([GH-721])

## 0.9.6 (February 7, 2012)

  - Fix strange issue with inconsistent childprocess reads on JRuby. ([GH-711])
  - `vagrant ssh` does a direct `exec()` syscall now instead of going through
    the shell. This makes it so things like shell expansion oddities no longer
    cause problems. ([GH-715])
  - Fix crashing case if there are no ports to forward.
  - Fix issue surrounding improper configuration of host only networks on
    RedHat guests. ([GH-719])
  - NFS should work properly on Gentoo. ([GH-706])

## 0.9.5 (February 5, 2012)

  - Fix crashing case when all network options are `:auto_config false`.
    ([GH-689])
  - Type of network adapter can be specified with `:nic_type`. ([GH-690])
  - The NFS version can be specified with the `:nfs_version` option
    on shared folders. ([GH-557])
  - Greatly improved FreeBSD guest and host support. ([GH-695])
  - Fix instability with RedHat guests and host only and bridged networks.
    ([GH-698])
  - When using bridged networking, only list the network interfaces
    that are up as choices. ([GH-701])
  - More intelligent handling of the `certname` option for puppet
    server. ([GH-702])
  - You may now explicitly set the network to bridge to in the Vagrantfile
    using the `:bridge` parameter. ([GH-655])

## 0.9.4 (January 28, 2012)

  - Important internal changes to middlewares that make plugin developer's
    lives much easier. ([GH-684])
  - Match VM names that have parens, brackets, etc.
  - Detect when the VirtualBox kernel module is not loaded and error. ([GH-677])
  - Set `:auto_config` to false on any networking option to not automatically
    configure it on the guest. ([GH-663])
  - NFS shared folder guest paths can now contain shell expansion characters
    such as `~`.
  - NFS shared folders with a `:create` flag will have their host folders
    properly created if they don't exist. ([GH-667])
  - Fix the precedence for Arch, Ubuntu, and FreeBSD host classes so
    they are properly detected. ([GH-683])
  - Fix issue where VM import sometimes made strange VirtualBox folder
    layouts. ([GH-669])
  - Call proper `id` command on Solaris. ([GH-679])
  - More accurate VBoxManage error detection.
  - Shared folders can now be marked as transient using the `:transient`
    flag. ([GH-688])

## 0.9.3 (January 24, 2012)

  - Proper error handling for not enough arguments to `box` commands.
  - Fix issue causing crashes with bridged networking. ([GH-673])
  - Ignore host only network interfaces that are "down." ([GH-675])
  - Use "printf" instead of "echo" to determine shell expanded files paths
    which is more generally POSIX compliant. ([GH-676])

## 0.9.2 (January 20, 2012)

  - Support shell expansions in shared folder guest paths again. ([GH-656])
  - Fix issue where Chef solo always expected the host to have a
    "cookbooks" folder in their directory. ([GH-638])
  - Fix `forward_agent` not working when outside of blocks. ([GH-651])
  - Fix issue causing custom guest implementations to not load properly.
  - Filter clear screen character out of output on SSH.
  - Log output now goes on `stderr`, since it is utility information.
  - Get rid of case where a `NoMethodError` could be raised while
    determining VirtualBox version. ([GH-658])
  - Debian/Ubuntu uses `ifdown` again, instead of `ifconfig xxx down`, since
    the behavior seems different/wrong.
  - Give a nice error if `:vagrant` is used as a JSON key, since Vagrant
    uses this. ([GH-661])
  - If there is only one bridgeable interface, use that without asking
    the user. ([GH-655])
  - The shell will have color output if ANSICON is installed on Windows. ([GH-666])

## 0.9.1 (January 18, 2012)

  - Use `ifconfig device down` instead of `ifdown`. ([GH-649])
  - Clearer invalid log level error. ([GH-645])
  - Fix exception raised with NFS `recover` method.
  - Fix `ui` `NoMethodError` exception in puppet server.
  - Fix `vagrant box help` on Ruby 1.8.7. ([GH-647])

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
    then it is assumed to be a regular expression. ([GH-573])
  - Added a "--plain" flag to `vagrant ssh` which will cause Vagrant to not
    perform any authentication. It will simply `ssh` into the proper IP and
    port of the virtual machine.
  - If a shared folder now has a `:create` flag set to `true`, the path on the
    host will be created if it doesn't exist.
  - Added `--force` flag to `box add`, which will overwrite any existing boxes
    if they exist. ([GH-631])
  - Added `--provision-with` to `up` which configures what provisioners run,
    by shortcut. ([GH-367])
  - Arbitrary mount options can be passed with `:extra` to any shared
    folders. ([GH-551])
  - Options passed after a `--` to `vagrant ssh` are now passed directly to
    `ssh`. ([GH-554])
  - Ubuntu guests will now emit a `vagrant-mounted` upstart event after shared
    folders are mounted.
  - `attempts` is a new option on chef client and chef solo provisioners. This
    will run the provisioner multiple times until erroring about failing
    convergence. ([GH-282])
  - Removed Thor as a dependency for the command line interfaces. This resulted
    in general speed increases across all command line commands.
  - Linux uses `shutdown -h` instead of `halt` to hopefully more consistently
    power off the system. ([GH-575])
  - Tweaks to SSH to hopefully be more reliable in coming up.
  - Helpful error message when SCP is unavailable in the guest. ([GH-568])
  - Error message for improperly packaged box files. ([GH-198])
  - Copy insecure private key to user-owned directory so even
    `sudo` installed Vagrant installations work. ([GH-580])
  - Provisioner stdout/stderr is now color coded based on stdout/stderr.
    stdout is green, stderr is red. ([GH-595])
  - Chef solo now prompts users to run a `reload` if shared folders
    are not found on the VM. ([GH-253])
  - "--no-provision" once again works for certain commands. ([GH-591])
  - Resuming a VM from a saved state will show an error message if there
    would be port collisions. ([GH-602])
  - `vagrant ssh -c` will now exit with the same exit code as the command
    run. ([GH-598])
  - `vagrant ssh -c` will now send stderr to stderr and stdout to stdout
    on the host machine, instead of all output to stdout.
  - `vagrant box add` path now accepts unexpanded shell paths such as
    `~/foo` and will properly expand them. ([GH-633])
  - Vagrant can now be interrupted during the "importing" step.
  - NFS exports will no longer be cleared when an expected error occurs. ([GH-577])

## 0.8.10 (December 10, 2011)

  - Revert the SSH tweaks made in 0.8.8. It affected stability

## 0.8.8 (December 1, 2011)

  - Mount shared folders shortest to longest to avoid mounting
    subfolders first. ([GH-525])
  - Support for basic HTTP auth in the URL for boxes.
  - Solaris support for host only networks. ([GH-533])
  - `vagrant init` respects `Vagrant::Environment` cwd. ([GH-528])
  - `vagrant` commands will not output color when stdout is
    not a TTY.
  - Fix issue where `box_url` set with multiple VMs could cause issues. ([GH-564])
  - Chef provisioners no longer depend on a "v-root" share being
    available. ([GH-556])
  - NFS should work for FreeBSD hosts now. ([GH-510])
  - SSH executed methods respect `config.ssh.max_tries`. ([GH-508])
  - `vagrant box add` now respects the "no_proxy" environmental variable.
    ([GH-502])
  - Tweaks that should make "Waiting for VM to boot" slightly more
    reliable.
  - Add comments to Vagrantfile to make it detected as Ruby file for
    `vi` and `emacs`. ([GH-515])
  - More correct guest addition version checking. ([GH-514])
  - Chef solo support on Windows is improved. ([GH-542])
  - Put encrypted data bag secret into `/tmp` by default so that
    permissions are almost certainly guaranteed. ([GH-512])

## 0.8.7 (September 13, 2011)

  - Fix regression with remote paths from chef-solo. ([GH-431])
  - Fix issue where Vagrant crashes if `.vagrant` file becomes invalid. ([GH-496])
  - Issue a warning instead of an error for attempting to forward a port
    <= 1024. ([GH-487])

## 0.8.6 (August 28, 2011)

  - Fix issue with download progress not properly clearing the line. ([GH-476])
  - NFS should work properly on Fedora. ([GH-450])
  - Arguments can be specified to the `shell` provisioner via the `args` option. ([GH-475])
  - Vagrant behaves much better when there are "inaccessible" VMs. ([GH-453])

## 0.8.5 (August 15, 2011)

Note: 0.8.3 and 0.8.4 was yanked due to RubyGems encoding issue.

 - Fix SSH `exec!` to inherit proper `$PATH`. ([GH-426])
 - Chef client now accepts an empty (`nil`) run list again. ([GH-429])
 - Fix incorrect error message when running `provision` on halted VM. ([GH-447])
 - Checking guest addition versions now ignores OSE. ([GH-438])
 - Chef solo from a remote URL fixed. ([GH-431])
 - Arch linux support: host only networks and changing the host name. ([GH-439]) ([GH-448])
 - Chef solo `roles_path` and `data_bags_path` can only be single paths. ([GH-446])
 - Fix `virtualbox_not_detected` error message to require 4.1.x. ([GH-458])
 - Add shortname (`hostname -s`) for hostname setting on RHEL systems. ([GH-456])
 - `vagrant ssh -c` output no longer has a prefix and respects newlines
   from the output. ([GH-462])

## 0.8.2 (July 22, 2011)

  - Fix issue with SSH disconnects not reconnecting.
  - Fix chef solo simply not working with roles/data bags. ([GH-425])
  - Multiple chef solo provisioners now work together.
  - Update Puppet provisioner so no deprecation warning is shown. ([GH-421])
  - Removed error on "provisioner=" in config, as this has not existed
    for some time now.
  - Add better validation for networking.

## 0.8.1 (July 20, 2011)

  - Repush of 0.8.0 to fix a Ruby 1.9.2 RubyGems issue.

## 0.8.0 (July 20, 2011)

  - VirtualBox 4.1 support _only_. Previous versions of VirtualBox
    are supported by earlier versions of Vagrant.
  - Performance optimizations in `virtualbox` gem. Huge speed gains.
  - `:chef_server` provisioner is now `:chef_client`. ([GH-359])
  - SSH connection is now cached after first access internally,
    speeding up `vagrant up`, `reload`, etc. quite a bit.
  - Actions which modify the VM now occur much more quickly,
    greatly speeding up `vagrant up`, `reload`, etc.
  - SUSE host only networking support. ([GH-369])
  - Show nice error message for invalid HTTP responses for HTTP
    downloader. ([GH-403])
  - New `:inline` option for shell provisioner to provide inline
    scripts as a string. ([GH-395])
  - Host only network now properly works on multiple adapters. ([GH-365])
  - Can now specify owner/group for regular shared folders. ([GH-350])
  - `ssh_config` host name will use VM name if given. ([GH-332])
  - `ssh` `-e` flag changed to `-c` to align with `ssh` standard
    behavior. ([GH-323])
  - Forward agent and forward X11 settings properly appear in
    `ssh_config` output. ([GH-105])
  - Chef JSON can now be set with `chef.json =` instead of the old
    `merge` technique. ([GH-314])
  - Provisioner configuration is no longer cleared when the box
    needs to be downloaded during an `up`. ([GH-308])
  - Multiple Chef provisioners no longer overwrite cookbook folders. ([GH-407])
  - `package` won't delete previously existing file. ([GH-408])
  - Vagrantfile can be lowercase now. ([GH-399])
  - Only one copy of Vagrant may be running at any given time. ([GH-364])
  - Default home directory for Vagrant moved to `~/.vagrant.d` ([GH-333])
  - Specify a `forwarded_port_destination` for SSH configuration and
    SSH port searching will fall back to that if it can't find any
    other port. ([GH-375])

## 0.7.8 (July 19, 2011)

  - Make sure VirtualBox version check verifies that it is 4.0.x.

## 0.7.7 (July 12, 2011)

  - Fix crashing bug with Psych and Ruby 1.9.2. ([GH-411])

## 0.7.6 (July 2, 2011)

  - Run Chef commands in a single command. ([GH-390])
  - Add `nfs` option for Chef to mount Chef folders via NFS. ([GH-378])
  - Add translation for `aborted` state in VM. ([GH-371])
  - Use full paths with the Chef provisioner so that restart cookbook will
    work. ([GH-374])
  - Add "--no-color" as an argument and no colorized output will be used. ([GH-379])
  - Added DEVICE option to the RedHat host only networking entry, which allows
    host only networking to work even if the VM has multiple NICs. ([GH-382])
  - Touch the network configuration file for RedHat so that the `sed` works
    with host only networking. ([GH-381])
  - Load prerelease versions of plugins if available.
  - Do not load a plugin if it depends on an invalid version of Vagrant.
  - Encrypted data bag support in Chef server provisioner. ([GH-398])
  - Use the `-H` flag to set the proper home directory for `sudo`. ([GH-370])

## 0.7.5 (May 16, 2011)

  - `config.ssh.port` can be specified and takes highest precedence if specified.
    Otherwise, Vagrant will still attempt to auto-detect the port. ([GH-363])
  - Get rid of RubyGems deprecations introduced with RubyGems 1.8.x
  - Search in pre-release gems for plugins as well as release gems.
  - Support for Chef-solo `data_bags_path` ([GH-362])
  - Can specify path to Chef binary using `binary_path` ([GH-342])
  - Can specify additional environment data for Chef using `binary_env` ([GH-342])

## 0.7.4 (May 12, 2011)

  - Chef environments support (for Chef 0.10) ([GH-358])
  - Suppress the "added to known hosts" message for SSH ([GH-354])
  - Ruby 1.8.6 support ([GH-352])
  - Chef proxy settings now work for chef server ([GH-335])

## 0.7.3 (April 19, 2011)

  - Retry all SSH on Net::SSH::Disconnect in case SSH is just restarting. ([GH-313])
  - Add NFS shared folder support for Arch linux. ([GH-346])
  - Fix issue with unknown terminal type output for sudo commands.
  - Forwarded port protocol can now be set as UDP. ([GH-311])
  - Chef server file cache path and file backup path can be configured. ([GH-310])
  - Setting hostname should work on Debian now. ([GH-307])

## 0.7.2 (February 8, 2011)

  - Update JSON dependency to 1.5.1, which works with Ruby 1.9 on
    Windows.
  - Fix sudo issues on sudo < 1.7.0 (again).
  - Fix race condition in SSH, which specifically manifested itself in
    the chef server provisioner. ([GH-295])
  - Change sudo shell to use `bash` (configurable). ([GH-301])
  - Can now set mac address of host only network. ([GH-294])
  - NFS shared folders with spaces now work properly. ([GH-293])
  - Failed SSH commands now show output in error message. ([GH-285])

## 0.7.1 (January 28, 2011)

  - Change error output with references to VirtualBox 3.2 to 4.0.
  - Internal SSH through net-ssh now uses `IdentitiesOnly` thanks to
    upstream net-ssh fix.
  - Fix issue causing warnings to show with `forwardx11` enabled for SSH. ([GH-279])
  - FreeBSD support for host only networks, NFS, halting, etc. ([GH-275])
  - Make SSH commands which use sudo compatible with sudo < 1.7.0. ([GH-278])
  - Fix broken puppet server provisioner which called a nonexistent
    method.
  - Default SSH host changed from `localhost` to `127.0.0.1` since
    `localhost` is not always loopback.
  - New `shell` provisioner which simply uploads and executes a script as
    root on the VM.
  - Gentoo host only networking no longer fails if already setup. ([GH-286])
  - Set the host name of your guest OS with `config.vm.host_name` ([GH-273])
  - `vagrant ssh-config` now outputs the configured `config.ssh.host`

## 0.7.0 (January 19, 2011)

  - VirtualBox 4.0 support. Support for VirtualBox 3.2 is _dropped_, since
    the API is so different. Stay with the 0.6.x series if you have VirtualBox
    3.2.x.
  - Puppet server provisioner. ([GH-262])
  - Use numeric uid/gid in mounting shared folders to increase portability. ([GH-252])
  - HTTP downloading follows redirects. ([GH-163])
  - Downloaders have clearer output to note what they're doing.
  - Shared folders with no guest path are not automounted. ([GH-184])
  - Boxes downloaded during `vagrant up` reload the Vagrantfile config, which
    fixes a problem with box settings not being properly loaded. ([GH-231])
  - `config.ssh.forward_x11` to enable the ForwardX11 SSH option. ([GH-255])
  - Vagrant source now has a `contrib` directory where contributions of miscellaneous
    addons for Vagrant will be added.
  - Vagrantfiles are now loaded only once (instead of 4+ times) ([GH-238])
  - Ability to move home vagrant dir (~/.vagrant) by setting VAGRANT_HOME
    environmental variable.
  - Removed check and error for the "OSE" version of VirtualBox, since with
    VirtualBox 4 this distinction no longer exists.
  - Ability to specify proxy settings for chef. ([GH-169])
  - Helpful error message shown if NFS mounting fails. ([GH-135])
  - Gentoo guests now support host only networks. ([GH-240])
  - RedHat (CentOS included) guests now support host only networks. ([GH-260])
  - New Vagrantfile syntax for enabling and configuring provisioners. This
    change is not backwards compatible. ([GH-265])
  - Provisioners are now RVM-friendly, meaning if you installed chef or puppet
    with an RVM managed Ruby, Vagrant now finds then. ([GH-254])
  - Changed the unused host only network destroy mechanism to check for
    uselessness after the VM is destroyed. This should result in more accurate
    checks.
  - Networks are no longer disabled upon halt/destroy. With the above
    change, its unnecessary.
  - Puppet supports `module_path` configuration to mount local modules directory
    as a shared folder and configure puppet with it. ([GH-270])
  - `ssh-config` now outputs `127.0.0.1` as the host instead of `localhost`.

## 0.6.9 (December 21, 2010)

  - Puppet provisioner. ([GH-223])
  - Solaris system configurable to use `sudo`.
  - Solaris system registered, so it can be set with `:solaris`.
  - `vagrant package` include can be a directory name, which will cause the
    contents to be recursively copied into the package. ([GH-241])
  - Arbitrary options to puppet binary can be set with `config.puppet.options`. ([GH-242])
  - BSD hosts use proper GNU sed syntax for clearing NFS shares. ([GH-243])
  - Enumerate VMs in a multi-VM environment in order they were defined. ([GH-244])
  - Check for VM boot changed to use `timeout` library, which works better with Windows.
  - Show special error if VirtualBox not detected on 64-bit Windows.
  - Show error to Windows users attempting to use host only networking since
    it doesn't work yet.

## 0.6.8 (November 30, 2010)

  - Network interfaces are now up/down in distinct commands instead of just
    restarting "networking." ([GH-192])
  - Add missing translation for chef binary missing. ([GH-203])
  - Fix default settings for Opscode platform and comments. ([GH-213])
  - Blank client name for chef server now uses FQDN by default, instead of "client" ([GH-214])
  - Run list can now be nil, which will cause it to sync with chef server (when
    chef server is enabled). ([GH-214])
  - Multiple NFS folders now work on linux. ([GH-215])
  - Add translation for state "stuck" which is very rare. ([GH-218])
  - virtualbox gem dependency minimum raised to 0.7.6 to verify FFI < 1.0.0 is used.
  - Fix issue where box downloading from `vagrant up` didn't reload the box collection. ([GH-229])

## 0.6.7 (November 3, 2010)

  - Added validation to verify that a box is specified.
  - Proper error message when box is not found for `config.vm.box`. ([GH-195])
  - Fix output of `vagrant status` with multi-vm to be correct. ([GH-196])

## 0.6.6 (October 14, 2010)

  - `vagrant status NAME` works once again. ([GH-191])
  - Conditional validation of Vagrantfile so that some commands don't validate. ([GH-188])
  - Fix "junk" output for ssh-config. ([GH-189])
  - Fix port collision handling with greater than two VMs. ([GH-185])
  - Fix potential infinite loop with root path if bad CWD is given to environment.

## 0.6.5 (October 8, 2010)

  - Validations on base MAC address to avoid situation described in GH-166, GH-181
    from ever happening again.
  - Properly load sub-VM configuration on first-pass of config loading. Solves
    a LOT of problems with multi-VM. ([GH-166]) ([GH-181])
  - Configuration now only validates on final Vagrantfile proc, so multi-VM
    validates correctly.
  - A nice error message is given if ".vagrant" is a directory and therefore
    can't be accessed. ([GH-172])
  - Fix plugin loading in a Rails 2.3.x project. ([GH-176])

## 0.6.4 (October 4, 2010)

  - Default VM name is now properly the parent folder of the working directory
    of the environment.
  - Added method to `TestHelpers` to assist with testing new downloaders.
  - `up --no-provision` works again. This disables provisioning during the
    boot process.
  - Action warden doesn't do recovery process on `SystemExit` exceptions,
    allowing the double ctrl-C to work properly again. [related to GH-166]
  - Initial Vagrantfile is now heavily commented with various available
    options. ([GH-171])
  - Box add checks if a box already exists before the download. ([GH-170])
  - NFS no longer attempts to clean exports file if VM is not created,
    which was causing a stack trace during recovery. [related to GH-166]
  - Basic validation added for Chef configuration (both solo and server).
  - Top config class is now available in all `Vagrant::Config::Base`
    subclasses, which is useful for config validation.
  - Subcommand help shows proper full command in task listing. ([GH-168])
  - SSH gives error message if `ssh` binary is not found. ([GH-161])
  - SSH gives proper error message if VM is not running. ([GH-167])
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
    in any Vagrantfile. ([GH-154])
  - The format of the ".vagrant" file which stores persisted VMs has
    changed. This is **backwards incompatible**. Will provide an upgrade
    utility prior to 0.6 launch.
  - Every [expected] Vagrant error now exits with a clean error message
    and a unique exit status, and raises a unique exception (if you're
    scripting Vagrant).
  - Added I18n gem dependency for pulling strings into clean YML files.
    Vagrant is now localizable as a side effect! Translations welcome.
  - Fixed issue with "Waiting for cleanup" message appearing twice in
    some cases. ([GH-145])
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
  - Fixed poorly formatted Vagrantfile after `vagrant init`. ([GH-142])
  - Fixed NFS not working properly with multiple NFS folders.
  - Fixed chef solo provision to work on Windows. It was expanding a linux
    path which prepended a drive letter onto it.

## 0.5.2 (August 3, 2010)

  - `vagrant up` can be used as a way to resume the VM as well (same as
    `vagrant resume`). ([GH-134])
  - Sudo uses "-E" flag to preserve environment for chef provisioners.
    This fixes issues with CentOS. ([GH-133])
  - Added "IdentitiesOnly yes" to options when `vagrant ssh` is run to
    avoid "Too Many Authentication Failures" error. ([GH-131])
  - Fix regression with `package` not working. ([GH-132])
  - Added ability to specify box url in `init`, which populates the
    Vagrantfile with the proper `config.vm.box_url`.

## 0.5.1 (July 31, 2010)

  - Allow specifying cookbook paths which exist only on the VM in `config.chef.cookbooks_path`.
    This is used for specifying cookbook paths when `config.chef.recipe_url` is used. ([GH-130])
    See updated chef solo documentation for more information on this.
  - No longer show "Disabling host only networks..." if no host only networks
    are destroyed. Quiets `destroy`, `halt`, etc output a bit.
  - Updated getting started guide to be more up to date and generic. ([GH-125])
  - Fixed error with doing a `vagrant up` when no Vagrantfile existed. ([GH-128])
  - Fixed NFS erroring when NFS wasn't even enabled if `/etc/exports` doesn't
    exist. ([GH-126])
  - Fixed `vagrant resume` to properly resume a suspended VM. ([GH-122])
  - Fixed `halt`, `destroy`, `reload` to where they failed if the VM was
    in a saved state. ([GH-123])
  - Added `config.chef.recipe_url` which allows you to specify a URL to
    a gzipped tar file for chef solo to download cookbooks. See the
    [chef-solo docs](https://docs.chef.io/chef_solo.html) for more information.
    ([GH-121])
  - Added `vagrant box repackage` which repackages boxes which have
    been added. This is useful in case you want to redistribute a base
    box you have but may have lost the actual "box" file. ([GH-120])

## Previous

The changelog began with version 0.5.1 so any changes prior to that
can be seen by checking the tagged releases and reading git commit
messages.

[GH-57]: https://github.com/hashicorp/vagrant/issues/57
[GH-105]: https://github.com/hashicorp/vagrant/issues/105
[GH-120]: https://github.com/hashicorp/vagrant/issues/120
[GH-121]: https://github.com/hashicorp/vagrant/issues/121
[GH-122]: https://github.com/hashicorp/vagrant/issues/122
[GH-123]: https://github.com/hashicorp/vagrant/issues/123
[GH-125]: https://github.com/hashicorp/vagrant/issues/125
[GH-126]: https://github.com/hashicorp/vagrant/issues/126
[GH-128]: https://github.com/hashicorp/vagrant/issues/128
[GH-130]: https://github.com/hashicorp/vagrant/issues/130
[GH-131]: https://github.com/hashicorp/vagrant/issues/131
[GH-132]: https://github.com/hashicorp/vagrant/issues/132
[GH-133]: https://github.com/hashicorp/vagrant/issues/133
[GH-134]: https://github.com/hashicorp/vagrant/issues/134
[GH-135]: https://github.com/hashicorp/vagrant/issues/135
[GH-142]: https://github.com/hashicorp/vagrant/issues/142
[GH-145]: https://github.com/hashicorp/vagrant/issues/145
[GH-154]: https://github.com/hashicorp/vagrant/issues/154
[GH-161]: https://github.com/hashicorp/vagrant/issues/161
[GH-163]: https://github.com/hashicorp/vagrant/issues/163
[GH-166]: https://github.com/hashicorp/vagrant/issues/166
[GH-167]: https://github.com/hashicorp/vagrant/issues/167
[GH-168]: https://github.com/hashicorp/vagrant/issues/168
[GH-169]: https://github.com/hashicorp/vagrant/issues/169
[GH-170]: https://github.com/hashicorp/vagrant/issues/170
[GH-171]: https://github.com/hashicorp/vagrant/issues/171
[GH-172]: https://github.com/hashicorp/vagrant/issues/172
[GH-176]: https://github.com/hashicorp/vagrant/issues/176
[GH-181]: https://github.com/hashicorp/vagrant/issues/181
[GH-184]: https://github.com/hashicorp/vagrant/issues/184
[GH-185]: https://github.com/hashicorp/vagrant/issues/185
[GH-188]: https://github.com/hashicorp/vagrant/issues/188
[GH-189]: https://github.com/hashicorp/vagrant/issues/189
[GH-191]: https://github.com/hashicorp/vagrant/issues/191
[GH-192]: https://github.com/hashicorp/vagrant/issues/192
[GH-195]: https://github.com/hashicorp/vagrant/issues/195
[GH-196]: https://github.com/hashicorp/vagrant/issues/196
[GH-198]: https://github.com/hashicorp/vagrant/issues/198
[GH-203]: https://github.com/hashicorp/vagrant/issues/203
[GH-213]: https://github.com/hashicorp/vagrant/issues/213
[GH-215]: https://github.com/hashicorp/vagrant/issues/215
[GH-218]: https://github.com/hashicorp/vagrant/issues/218
[GH-223]: https://github.com/hashicorp/vagrant/issues/223
[GH-229]: https://github.com/hashicorp/vagrant/issues/229
[GH-231]: https://github.com/hashicorp/vagrant/issues/231
[GH-238]: https://github.com/hashicorp/vagrant/issues/238
[GH-240]: https://github.com/hashicorp/vagrant/issues/240
[GH-241]: https://github.com/hashicorp/vagrant/issues/241
[GH-242]: https://github.com/hashicorp/vagrant/issues/242
[GH-243]: https://github.com/hashicorp/vagrant/issues/243
[GH-244]: https://github.com/hashicorp/vagrant/issues/244
[GH-252]: https://github.com/hashicorp/vagrant/issues/252
[GH-253]: https://github.com/hashicorp/vagrant/issues/253
[GH-254]: https://github.com/hashicorp/vagrant/issues/254
[GH-255]: https://github.com/hashicorp/vagrant/issues/255
[GH-260]: https://github.com/hashicorp/vagrant/issues/260
[GH-262]: https://github.com/hashicorp/vagrant/issues/262
[GH-265]: https://github.com/hashicorp/vagrant/issues/265
[GH-270]: https://github.com/hashicorp/vagrant/issues/270
[GH-273]: https://github.com/hashicorp/vagrant/issues/273
[GH-275]: https://github.com/hashicorp/vagrant/issues/275
[GH-278]: https://github.com/hashicorp/vagrant/issues/278
[GH-279]: https://github.com/hashicorp/vagrant/issues/279
[GH-282]: https://github.com/hashicorp/vagrant/issues/282
[GH-285]: https://github.com/hashicorp/vagrant/issues/285
[GH-286]: https://github.com/hashicorp/vagrant/issues/286
[GH-293]: https://github.com/hashicorp/vagrant/issues/293
[GH-294]: https://github.com/hashicorp/vagrant/issues/294
[GH-295]: https://github.com/hashicorp/vagrant/issues/295
[GH-301]: https://github.com/hashicorp/vagrant/issues/301
[GH-307]: https://github.com/hashicorp/vagrant/issues/307
[GH-308]: https://github.com/hashicorp/vagrant/issues/308
[GH-310]: https://github.com/hashicorp/vagrant/issues/310
[GH-311]: https://github.com/hashicorp/vagrant/issues/311
[GH-313]: https://github.com/hashicorp/vagrant/issues/313
[GH-314]: https://github.com/hashicorp/vagrant/issues/314
[GH-323]: https://github.com/hashicorp/vagrant/issues/323
[GH-332]: https://github.com/hashicorp/vagrant/issues/332
[GH-333]: https://github.com/hashicorp/vagrant/issues/333
[GH-335]: https://github.com/hashicorp/vagrant/issues/335
[GH-346]: https://github.com/hashicorp/vagrant/issues/346
[GH-350]: https://github.com/hashicorp/vagrant/issues/350
[GH-352]: https://github.com/hashicorp/vagrant/issues/352
[GH-354]: https://github.com/hashicorp/vagrant/issues/354
[GH-358]: https://github.com/hashicorp/vagrant/issues/358
[GH-359]: https://github.com/hashicorp/vagrant/issues/359
[GH-362]: https://github.com/hashicorp/vagrant/issues/362
[GH-363]: https://github.com/hashicorp/vagrant/issues/363
[GH-364]: https://github.com/hashicorp/vagrant/issues/364
[GH-365]: https://github.com/hashicorp/vagrant/issues/365
[GH-367]: https://github.com/hashicorp/vagrant/issues/367
[GH-369]: https://github.com/hashicorp/vagrant/issues/369
[GH-370]: https://github.com/hashicorp/vagrant/issues/370
[GH-371]: https://github.com/hashicorp/vagrant/issues/371
[GH-374]: https://github.com/hashicorp/vagrant/issues/374
[GH-375]: https://github.com/hashicorp/vagrant/issues/375
[GH-378]: https://github.com/hashicorp/vagrant/issues/378
[GH-379]: https://github.com/hashicorp/vagrant/issues/379
[GH-381]: https://github.com/hashicorp/vagrant/issues/381
[GH-382]: https://github.com/hashicorp/vagrant/issues/382
[GH-390]: https://github.com/hashicorp/vagrant/issues/390
[GH-395]: https://github.com/hashicorp/vagrant/issues/395
[GH-398]: https://github.com/hashicorp/vagrant/issues/398
[GH-399]: https://github.com/hashicorp/vagrant/issues/399
[GH-403]: https://github.com/hashicorp/vagrant/issues/403
[GH-407]: https://github.com/hashicorp/vagrant/issues/407
[GH-408]: https://github.com/hashicorp/vagrant/issues/408
[GH-411]: https://github.com/hashicorp/vagrant/issues/411
[GH-421]: https://github.com/hashicorp/vagrant/issues/421
[GH-425]: https://github.com/hashicorp/vagrant/issues/425
[GH-426]: https://github.com/hashicorp/vagrant/issues/426
[GH-429]: https://github.com/hashicorp/vagrant/issues/429
[GH-438]: https://github.com/hashicorp/vagrant/issues/438
[GH-439]: https://github.com/hashicorp/vagrant/issues/439
[GH-446]: https://github.com/hashicorp/vagrant/issues/446
[GH-447]: https://github.com/hashicorp/vagrant/issues/447
[GH-448]: https://github.com/hashicorp/vagrant/issues/448
[GH-450]: https://github.com/hashicorp/vagrant/issues/450
[GH-453]: https://github.com/hashicorp/vagrant/issues/453
[GH-456]: https://github.com/hashicorp/vagrant/issues/456
[GH-458]: https://github.com/hashicorp/vagrant/issues/458
[GH-462]: https://github.com/hashicorp/vagrant/issues/462
[GH-475]: https://github.com/hashicorp/vagrant/issues/475
[GH-476]: https://github.com/hashicorp/vagrant/issues/476
[GH-487]: https://github.com/hashicorp/vagrant/issues/487
[GH-496]: https://github.com/hashicorp/vagrant/issues/496
[GH-502]: https://github.com/hashicorp/vagrant/issues/502
[GH-508]: https://github.com/hashicorp/vagrant/issues/508
[GH-510]: https://github.com/hashicorp/vagrant/issues/510
[GH-512]: https://github.com/hashicorp/vagrant/issues/512
[GH-514]: https://github.com/hashicorp/vagrant/issues/514
[GH-515]: https://github.com/hashicorp/vagrant/issues/515
[GH-516]: https://github.com/hashicorp/vagrant/issues/516
[GH-525]: https://github.com/hashicorp/vagrant/issues/525
[GH-528]: https://github.com/hashicorp/vagrant/issues/528
[GH-533]: https://github.com/hashicorp/vagrant/issues/533
[GH-542]: https://github.com/hashicorp/vagrant/issues/542
[GH-551]: https://github.com/hashicorp/vagrant/issues/551
[GH-554]: https://github.com/hashicorp/vagrant/issues/554
[GH-556]: https://github.com/hashicorp/vagrant/issues/556
[GH-557]: https://github.com/hashicorp/vagrant/issues/557
[GH-564]: https://github.com/hashicorp/vagrant/issues/564
[GH-568]: https://github.com/hashicorp/vagrant/issues/568
[GH-573]: https://github.com/hashicorp/vagrant/issues/573
[GH-575]: https://github.com/hashicorp/vagrant/issues/575
[GH-577]: https://github.com/hashicorp/vagrant/issues/577
[GH-591]: https://github.com/hashicorp/vagrant/issues/591
[GH-595]: https://github.com/hashicorp/vagrant/issues/595
[GH-598]: https://github.com/hashicorp/vagrant/issues/598
[GH-602]: https://github.com/hashicorp/vagrant/issues/602
[GH-603]: https://github.com/hashicorp/vagrant/issues/603
[GH-631]: https://github.com/hashicorp/vagrant/issues/631
[GH-633]: https://github.com/hashicorp/vagrant/issues/633
[GH-638]: https://github.com/hashicorp/vagrant/issues/638
[GH-645]: https://github.com/hashicorp/vagrant/issues/645
[GH-647]: https://github.com/hashicorp/vagrant/issues/647
[GH-649]: https://github.com/hashicorp/vagrant/issues/649
[GH-651]: https://github.com/hashicorp/vagrant/issues/651
[GH-656]: https://github.com/hashicorp/vagrant/issues/656
[GH-658]: https://github.com/hashicorp/vagrant/issues/658
[GH-661]: https://github.com/hashicorp/vagrant/issues/661
[GH-663]: https://github.com/hashicorp/vagrant/issues/663
[GH-666]: https://github.com/hashicorp/vagrant/issues/666
[GH-667]: https://github.com/hashicorp/vagrant/issues/667
[GH-669]: https://github.com/hashicorp/vagrant/issues/669
[GH-673]: https://github.com/hashicorp/vagrant/issues/673
[GH-675]: https://github.com/hashicorp/vagrant/issues/675
[GH-676]: https://github.com/hashicorp/vagrant/issues/676
[GH-677]: https://github.com/hashicorp/vagrant/issues/677
[GH-679]: https://github.com/hashicorp/vagrant/issues/679
[GH-683]: https://github.com/hashicorp/vagrant/issues/683
[GH-684]: https://github.com/hashicorp/vagrant/issues/684
[GH-688]: https://github.com/hashicorp/vagrant/issues/688
[GH-689]: https://github.com/hashicorp/vagrant/issues/689
[GH-690]: https://github.com/hashicorp/vagrant/issues/690
[GH-695]: https://github.com/hashicorp/vagrant/issues/695
[GH-698]: https://github.com/hashicorp/vagrant/issues/698
[GH-699]: https://github.com/hashicorp/vagrant/issues/699
[GH-701]: https://github.com/hashicorp/vagrant/issues/701
[GH-702]: https://github.com/hashicorp/vagrant/issues/702
[GH-706]: https://github.com/hashicorp/vagrant/issues/706
[GH-710]: https://github.com/hashicorp/vagrant/issues/710
[GH-711]: https://github.com/hashicorp/vagrant/issues/711
[GH-715]: https://github.com/hashicorp/vagrant/issues/715
[GH-719]: https://github.com/hashicorp/vagrant/issues/719
[GH-720]: https://github.com/hashicorp/vagrant/issues/720
[GH-721]: https://github.com/hashicorp/vagrant/issues/721
[GH-722]: https://github.com/hashicorp/vagrant/issues/722
[GH-725]: https://github.com/hashicorp/vagrant/issues/725
[GH-726]: https://github.com/hashicorp/vagrant/issues/726
[GH-727]: https://github.com/hashicorp/vagrant/issues/727
[GH-730]: https://github.com/hashicorp/vagrant/issues/730
[GH-736]: https://github.com/hashicorp/vagrant/issues/736
[GH-739]: https://github.com/hashicorp/vagrant/issues/739
[GH-742]: https://github.com/hashicorp/vagrant/issues/742
[GH-745]: https://github.com/hashicorp/vagrant/issues/745
[GH-746]: https://github.com/hashicorp/vagrant/issues/746
[GH-748]: https://github.com/hashicorp/vagrant/issues/748
[GH-750]: https://github.com/hashicorp/vagrant/issues/750
[GH-753]: https://github.com/hashicorp/vagrant/issues/753
[GH-757]: https://github.com/hashicorp/vagrant/issues/757
[GH-761]: https://github.com/hashicorp/vagrant/issues/761
[GH-762]: https://github.com/hashicorp/vagrant/issues/762
[GH-765]: https://github.com/hashicorp/vagrant/issues/765
[GH-766]: https://github.com/hashicorp/vagrant/issues/766
[GH-772]: https://github.com/hashicorp/vagrant/issues/772
[GH-773]: https://github.com/hashicorp/vagrant/issues/773
[GH-778]: https://github.com/hashicorp/vagrant/issues/778
[GH-779]: https://github.com/hashicorp/vagrant/issues/779
[GH-781]: https://github.com/hashicorp/vagrant/issues/781
[GH-785]: https://github.com/hashicorp/vagrant/issues/785
[GH-788]: https://github.com/hashicorp/vagrant/issues/788
[GH-790]: https://github.com/hashicorp/vagrant/issues/790
[GH-793]: https://github.com/hashicorp/vagrant/issues/793
[GH-795]: https://github.com/hashicorp/vagrant/issues/795
[GH-796]: https://github.com/hashicorp/vagrant/issues/796
[GH-803]: https://github.com/hashicorp/vagrant/issues/803
[GH-805]: https://github.com/hashicorp/vagrant/issues/805
[GH-808]: https://github.com/hashicorp/vagrant/issues/808
[GH-811]: https://github.com/hashicorp/vagrant/issues/811
[GH-816]: https://github.com/hashicorp/vagrant/issues/816
[GH-819]: https://github.com/hashicorp/vagrant/issues/819
[GH-820]: https://github.com/hashicorp/vagrant/issues/820
[GH-821]: https://github.com/hashicorp/vagrant/issues/821
[GH-825]: https://github.com/hashicorp/vagrant/issues/825
[GH-832]: https://github.com/hashicorp/vagrant/issues/832
[GH-834]: https://github.com/hashicorp/vagrant/issues/834
[GH-841]: https://github.com/hashicorp/vagrant/issues/841
[GH-846]: https://github.com/hashicorp/vagrant/issues/846
[GH-849]: https://github.com/hashicorp/vagrant/issues/849
[GH-885]: https://github.com/hashicorp/vagrant/issues/885
[GH-894]: https://github.com/hashicorp/vagrant/issues/894
[GH-902]: https://github.com/hashicorp/vagrant/issues/902
[GH-907]: https://github.com/hashicorp/vagrant/issues/907
[GH-909]: https://github.com/hashicorp/vagrant/issues/909
[GH-911]: https://github.com/hashicorp/vagrant/issues/911
[GH-912]: https://github.com/hashicorp/vagrant/issues/912
[GH-917]: https://github.com/hashicorp/vagrant/issues/917
[GH-921]: https://github.com/hashicorp/vagrant/issues/921
[GH-922]: https://github.com/hashicorp/vagrant/issues/922
[GH-923]: https://github.com/hashicorp/vagrant/issues/923
[GH-924]: https://github.com/hashicorp/vagrant/issues/924
[GH-931]: https://github.com/hashicorp/vagrant/issues/931
[GH-933]: https://github.com/hashicorp/vagrant/issues/933
[GH-934]: https://github.com/hashicorp/vagrant/issues/934
[GH-948]: https://github.com/hashicorp/vagrant/issues/948
[GH-951]: https://github.com/hashicorp/vagrant/issues/951
[GH-957]: https://github.com/hashicorp/vagrant/issues/957
[GH-968]: https://github.com/hashicorp/vagrant/issues/968
[GH-1004]: https://github.com/hashicorp/vagrant/issues/1004
[GH-1017]: https://github.com/hashicorp/vagrant/issues/1017
[GH-1032]: https://github.com/hashicorp/vagrant/issues/1032
[GH-1040]: https://github.com/hashicorp/vagrant/issues/1040
[GH-1061]: https://github.com/hashicorp/vagrant/issues/1061
[GH-1063]: https://github.com/hashicorp/vagrant/issues/1063
[GH-1072]: https://github.com/hashicorp/vagrant/issues/1072
[GH-1087]: https://github.com/hashicorp/vagrant/issues/1087
[GH-1090]: https://github.com/hashicorp/vagrant/issues/1090
[GH-1101]: https://github.com/hashicorp/vagrant/issues/1101
[GH-1111]: https://github.com/hashicorp/vagrant/issues/1111
[GH-1113]: https://github.com/hashicorp/vagrant/issues/1113
[GH-1118]: https://github.com/hashicorp/vagrant/issues/1118
[GH-1120]: https://github.com/hashicorp/vagrant/issues/1120
[GH-1121]: https://github.com/hashicorp/vagrant/issues/1121
[GH-1126]: https://github.com/hashicorp/vagrant/issues/1126
[GH-1127]: https://github.com/hashicorp/vagrant/issues/1127
[GH-1130]: https://github.com/hashicorp/vagrant/issues/1130
[GH-1140]: https://github.com/hashicorp/vagrant/issues/1140
[GH-1142]: https://github.com/hashicorp/vagrant/issues/1142
[GH-1146]: https://github.com/hashicorp/vagrant/issues/1146
[GH-1163]: https://github.com/hashicorp/vagrant/issues/1163
[GH-1164]: https://github.com/hashicorp/vagrant/issues/1164
[GH-1166]: https://github.com/hashicorp/vagrant/issues/1166
[GH-1167]: https://github.com/hashicorp/vagrant/issues/1167
[GH-1169]: https://github.com/hashicorp/vagrant/issues/1169
[GH-1176]: https://github.com/hashicorp/vagrant/issues/1176
[GH-1180]: https://github.com/hashicorp/vagrant/issues/1180
[GH-1184]: https://github.com/hashicorp/vagrant/issues/1184
[GH-1199]: https://github.com/hashicorp/vagrant/issues/1199
[GH-1202]: https://github.com/hashicorp/vagrant/issues/1202
[GH-1203]: https://github.com/hashicorp/vagrant/issues/1203
[GH-1204]: https://github.com/hashicorp/vagrant/issues/1204
[GH-1207]: https://github.com/hashicorp/vagrant/issues/1207
[GH-1223]: https://github.com/hashicorp/vagrant/issues/1223
[GH-1246]: https://github.com/hashicorp/vagrant/issues/1246
[GH-1247]: https://github.com/hashicorp/vagrant/issues/1247
[GH-1250]: https://github.com/hashicorp/vagrant/issues/1250
[GH-1281]: https://github.com/hashicorp/vagrant/issues/1281
[GH-1302]: https://github.com/hashicorp/vagrant/issues/1302
[GH-1307]: https://github.com/hashicorp/vagrant/issues/1307
[GH-1308]: https://github.com/hashicorp/vagrant/issues/1308
[GH-1313]: https://github.com/hashicorp/vagrant/issues/1313
[GH-1322]: https://github.com/hashicorp/vagrant/issues/1322
[GH-1324]: https://github.com/hashicorp/vagrant/issues/1324
[GH-1344]: https://github.com/hashicorp/vagrant/issues/1344
[GH-1364]: https://github.com/hashicorp/vagrant/issues/1364
[GH-1366]: https://github.com/hashicorp/vagrant/issues/1366
[GH-1368]: https://github.com/hashicorp/vagrant/issues/1368
[GH-1370]: https://github.com/hashicorp/vagrant/issues/1370
[GH-1394]: https://github.com/hashicorp/vagrant/issues/1394
[GH-1418]: https://github.com/hashicorp/vagrant/issues/1418
[GH-1421]: https://github.com/hashicorp/vagrant/issues/1421
[GH-1423]: https://github.com/hashicorp/vagrant/issues/1423
[GH-1424]: https://github.com/hashicorp/vagrant/issues/1424
[GH-1430]: https://github.com/hashicorp/vagrant/issues/1430
[GH-1436]: https://github.com/hashicorp/vagrant/issues/1436
[GH-1437]: https://github.com/hashicorp/vagrant/issues/1437
[GH-1442]: https://github.com/hashicorp/vagrant/issues/1442
[GH-1444]: https://github.com/hashicorp/vagrant/issues/1444
[GH-1447]: https://github.com/hashicorp/vagrant/issues/1447
[GH-1448]: https://github.com/hashicorp/vagrant/issues/1448
[GH-1461]: https://github.com/hashicorp/vagrant/issues/1461
[GH-1465]: https://github.com/hashicorp/vagrant/issues/1465
[GH-1466]: https://github.com/hashicorp/vagrant/issues/1466
[GH-1472]: https://github.com/hashicorp/vagrant/issues/1472
[GH-1478]: https://github.com/hashicorp/vagrant/issues/1478
[GH-1480]: https://github.com/hashicorp/vagrant/issues/1480
[GH-1483]: https://github.com/hashicorp/vagrant/issues/1483
[GH-1484]: https://github.com/hashicorp/vagrant/issues/1484
[GH-1490]: https://github.com/hashicorp/vagrant/issues/1490
[GH-1495]: https://github.com/hashicorp/vagrant/issues/1495
[GH-1503]: https://github.com/hashicorp/vagrant/issues/1503
[GH-1505]: https://github.com/hashicorp/vagrant/issues/1505
[GH-1506]: https://github.com/hashicorp/vagrant/issues/1506
[GH-1511]: https://github.com/hashicorp/vagrant/issues/1511
[GH-1515]: https://github.com/hashicorp/vagrant/issues/1515
[GH-1518]: https://github.com/hashicorp/vagrant/issues/1518
[GH-1524]: https://github.com/hashicorp/vagrant/issues/1524
[GH-1536]: https://github.com/hashicorp/vagrant/issues/1536
[GH-1537]: https://github.com/hashicorp/vagrant/issues/1537
[GH-1539]: https://github.com/hashicorp/vagrant/issues/1539
[GH-1545]: https://github.com/hashicorp/vagrant/issues/1545
[GH-1555]: https://github.com/hashicorp/vagrant/issues/1555
[GH-1558]: https://github.com/hashicorp/vagrant/issues/1558
[GH-1562]: https://github.com/hashicorp/vagrant/issues/1562
[GH-1566]: https://github.com/hashicorp/vagrant/issues/1566
[GH-1568]: https://github.com/hashicorp/vagrant/issues/1568
[GH-1570]: https://github.com/hashicorp/vagrant/issues/1570
[GH-1575]: https://github.com/hashicorp/vagrant/issues/1575
[GH-1577]: https://github.com/hashicorp/vagrant/issues/1577
[GH-1578]: https://github.com/hashicorp/vagrant/issues/1578
[GH-1607]: https://github.com/hashicorp/vagrant/issues/1607
[GH-1608]: https://github.com/hashicorp/vagrant/issues/1608
[GH-1609]: https://github.com/hashicorp/vagrant/issues/1609
[GH-1611]: https://github.com/hashicorp/vagrant/issues/1611
[GH-1615]: https://github.com/hashicorp/vagrant/issues/1615
[GH-1617]: https://github.com/hashicorp/vagrant/issues/1617
[GH-1620]: https://github.com/hashicorp/vagrant/issues/1620
[GH-1626]: https://github.com/hashicorp/vagrant/issues/1626
[GH-1629]: https://github.com/hashicorp/vagrant/issues/1629
[GH-1639]: https://github.com/hashicorp/vagrant/issues/1639
[GH-1665]: https://github.com/hashicorp/vagrant/issues/1665
[GH-1669]: https://github.com/hashicorp/vagrant/issues/1669
[GH-1670]: https://github.com/hashicorp/vagrant/issues/1670
[GH-1671]: https://github.com/hashicorp/vagrant/issues/1671
[GH-1672]: https://github.com/hashicorp/vagrant/issues/1672
[GH-1677]: https://github.com/hashicorp/vagrant/issues/1677
[GH-1679]: https://github.com/hashicorp/vagrant/issues/1679
[GH-1682]: https://github.com/hashicorp/vagrant/issues/1682
[GH-1688]: https://github.com/hashicorp/vagrant/issues/1688
[GH-1689]: https://github.com/hashicorp/vagrant/issues/1689
[GH-1691]: https://github.com/hashicorp/vagrant/issues/1691
[GH-1692]: https://github.com/hashicorp/vagrant/issues/1692
[GH-1697]: https://github.com/hashicorp/vagrant/issues/1697
[GH-1698]: https://github.com/hashicorp/vagrant/issues/1698
[GH-1699]: https://github.com/hashicorp/vagrant/issues/1699
[GH-1701]: https://github.com/hashicorp/vagrant/issues/1701
[GH-1704]: https://github.com/hashicorp/vagrant/issues/1704
[GH-1706]: https://github.com/hashicorp/vagrant/issues/1706
[GH-1712]: https://github.com/hashicorp/vagrant/issues/1712
[GH-1717]: https://github.com/hashicorp/vagrant/issues/1717
[GH-1732]: https://github.com/hashicorp/vagrant/issues/1732
[GH-1734]: https://github.com/hashicorp/vagrant/issues/1734
[GH-1736]: https://github.com/hashicorp/vagrant/issues/1736
[GH-1738]: https://github.com/hashicorp/vagrant/issues/1738
[GH-1745]: https://github.com/hashicorp/vagrant/issues/1745
[GH-1748]: https://github.com/hashicorp/vagrant/issues/1748
[GH-1750]: https://github.com/hashicorp/vagrant/issues/1750
[GH-1752]: https://github.com/hashicorp/vagrant/issues/1752
[GH-1760]: https://github.com/hashicorp/vagrant/issues/1760
[GH-1776]: https://github.com/hashicorp/vagrant/issues/1776
[GH-1781]: https://github.com/hashicorp/vagrant/issues/1781
[GH-1787]: https://github.com/hashicorp/vagrant/issues/1787
[GH-1788]: https://github.com/hashicorp/vagrant/issues/1788
[GH-1796]: https://github.com/hashicorp/vagrant/issues/1796
[GH-1799]: https://github.com/hashicorp/vagrant/issues/1799
[GH-1800]: https://github.com/hashicorp/vagrant/issues/1800
[GH-1801]: https://github.com/hashicorp/vagrant/issues/1801
[GH-1805]: https://github.com/hashicorp/vagrant/issues/1805
[GH-1808]: https://github.com/hashicorp/vagrant/issues/1808
[GH-1815]: https://github.com/hashicorp/vagrant/issues/1815
[GH-1817]: https://github.com/hashicorp/vagrant/issues/1817
[GH-1834]: https://github.com/hashicorp/vagrant/issues/1834
[GH-1877]: https://github.com/hashicorp/vagrant/issues/1877
[GH-1886]: https://github.com/hashicorp/vagrant/issues/1886
[GH-1889]: https://github.com/hashicorp/vagrant/issues/1889
[GH-1897]: https://github.com/hashicorp/vagrant/issues/1897
[GH-1900]: https://github.com/hashicorp/vagrant/issues/1900
[GH-1907]: https://github.com/hashicorp/vagrant/issues/1907
[GH-1911]: https://github.com/hashicorp/vagrant/issues/1911
[GH-1913]: https://github.com/hashicorp/vagrant/issues/1913
[GH-1914]: https://github.com/hashicorp/vagrant/issues/1914
[GH-1915]: https://github.com/hashicorp/vagrant/issues/1915
[GH-1918]: https://github.com/hashicorp/vagrant/issues/1918
[GH-1920]: https://github.com/hashicorp/vagrant/issues/1920
[GH-1922]: https://github.com/hashicorp/vagrant/issues/1922
[GH-1928]: https://github.com/hashicorp/vagrant/issues/1928
[GH-1935]: https://github.com/hashicorp/vagrant/issues/1935
[GH-1949]: https://github.com/hashicorp/vagrant/issues/1949
[GH-1957]: https://github.com/hashicorp/vagrant/issues/1957
[GH-1958]: https://github.com/hashicorp/vagrant/issues/1958
[GH-1967]: https://github.com/hashicorp/vagrant/issues/1967
[GH-1979]: https://github.com/hashicorp/vagrant/issues/1979
[GH-1984]: https://github.com/hashicorp/vagrant/issues/1984
[GH-1986]: https://github.com/hashicorp/vagrant/issues/1986
[GH-1990]: https://github.com/hashicorp/vagrant/issues/1990
[GH-1999]: https://github.com/hashicorp/vagrant/issues/1999
[GH-2000]: https://github.com/hashicorp/vagrant/issues/2000
[GH-2003]: https://github.com/hashicorp/vagrant/issues/2003
[GH-2007]: https://github.com/hashicorp/vagrant/issues/2007
[GH-2008]: https://github.com/hashicorp/vagrant/issues/2008
[GH-2011]: https://github.com/hashicorp/vagrant/issues/2011
[GH-2015]: https://github.com/hashicorp/vagrant/issues/2015
[GH-2016]: https://github.com/hashicorp/vagrant/issues/2016
[GH-2020]: https://github.com/hashicorp/vagrant/issues/2020
[GH-2022]: https://github.com/hashicorp/vagrant/issues/2022
[GH-2024]: https://github.com/hashicorp/vagrant/issues/2024
[GH-2026]: https://github.com/hashicorp/vagrant/issues/2026
[GH-2027]: https://github.com/hashicorp/vagrant/issues/2027
[GH-2035]: https://github.com/hashicorp/vagrant/issues/2035
[GH-2038]: https://github.com/hashicorp/vagrant/issues/2038
[GH-2041]: https://github.com/hashicorp/vagrant/issues/2041
[GH-2048]: https://github.com/hashicorp/vagrant/issues/2048
[GH-2051]: https://github.com/hashicorp/vagrant/issues/2051
[GH-2052]: https://github.com/hashicorp/vagrant/issues/2052
[GH-2058]: https://github.com/hashicorp/vagrant/issues/2058
[GH-2059]: https://github.com/hashicorp/vagrant/issues/2059
[GH-2086]: https://github.com/hashicorp/vagrant/issues/2086
[GH-2088]: https://github.com/hashicorp/vagrant/issues/2088
[GH-2100]: https://github.com/hashicorp/vagrant/issues/2100
[GH-2103]: https://github.com/hashicorp/vagrant/issues/2103
[GH-2112]: https://github.com/hashicorp/vagrant/issues/2112
[GH-2117]: https://github.com/hashicorp/vagrant/issues/2117
[GH-2130]: https://github.com/hashicorp/vagrant/issues/2130
[GH-2134]: https://github.com/hashicorp/vagrant/issues/2134
[GH-2137]: https://github.com/hashicorp/vagrant/issues/2137
[GH-2142]: https://github.com/hashicorp/vagrant/issues/2142
[GH-2146]: https://github.com/hashicorp/vagrant/issues/2146
[GH-2153]: https://github.com/hashicorp/vagrant/issues/2153
[GH-2156]: https://github.com/hashicorp/vagrant/issues/2156
[GH-2161]: https://github.com/hashicorp/vagrant/issues/2161
[GH-2173]: https://github.com/hashicorp/vagrant/issues/2173
[GH-2179]: https://github.com/hashicorp/vagrant/issues/2179
[GH-2188]: https://github.com/hashicorp/vagrant/issues/2188
[GH-2189]: https://github.com/hashicorp/vagrant/issues/2189
[GH-2191]: https://github.com/hashicorp/vagrant/issues/2191
[GH-2196]: https://github.com/hashicorp/vagrant/issues/2196
[GH-2197]: https://github.com/hashicorp/vagrant/issues/2197
[GH-2200]: https://github.com/hashicorp/vagrant/issues/2200
[GH-2201]: https://github.com/hashicorp/vagrant/issues/2201
[GH-2203]: https://github.com/hashicorp/vagrant/issues/2203
[GH-2216]: https://github.com/hashicorp/vagrant/issues/2216
[GH-2219]: https://github.com/hashicorp/vagrant/issues/2219
[GH-2223]: https://github.com/hashicorp/vagrant/issues/2223
[GH-2226]: https://github.com/hashicorp/vagrant/issues/2226
[GH-2231]: https://github.com/hashicorp/vagrant/issues/2231
[GH-2233]: https://github.com/hashicorp/vagrant/issues/2233
[GH-2234]: https://github.com/hashicorp/vagrant/issues/2234
[GH-2235]: https://github.com/hashicorp/vagrant/issues/2235
[GH-2241]: https://github.com/hashicorp/vagrant/issues/2241
[GH-2243]: https://github.com/hashicorp/vagrant/issues/2243
[GH-2244]: https://github.com/hashicorp/vagrant/issues/2244
[GH-2254]: https://github.com/hashicorp/vagrant/issues/2254
[GH-2261]: https://github.com/hashicorp/vagrant/issues/2261
[GH-2267]: https://github.com/hashicorp/vagrant/issues/2267
[GH-2270]: https://github.com/hashicorp/vagrant/issues/2270
[GH-2273]: https://github.com/hashicorp/vagrant/issues/2273
[GH-2281]: https://github.com/hashicorp/vagrant/issues/2281
[GH-2290]: https://github.com/hashicorp/vagrant/issues/2290
[GH-2300]: https://github.com/hashicorp/vagrant/issues/2300
[GH-2304]: https://github.com/hashicorp/vagrant/issues/2304
[GH-2305]: https://github.com/hashicorp/vagrant/issues/2305
[GH-2313]: https://github.com/hashicorp/vagrant/issues/2313
[GH-2320]: https://github.com/hashicorp/vagrant/issues/2320
[GH-2327]: https://github.com/hashicorp/vagrant/issues/2327
[GH-2328]: https://github.com/hashicorp/vagrant/issues/2328
[GH-2329]: https://github.com/hashicorp/vagrant/issues/2329
[GH-2334]: https://github.com/hashicorp/vagrant/issues/2334
[GH-2337]: https://github.com/hashicorp/vagrant/issues/2337
[GH-2347]: https://github.com/hashicorp/vagrant/issues/2347
[GH-2348]: https://github.com/hashicorp/vagrant/issues/2348
[GH-2358]: https://github.com/hashicorp/vagrant/issues/2358
[GH-2359]: https://github.com/hashicorp/vagrant/issues/2359
[GH-2365]: https://github.com/hashicorp/vagrant/issues/2365
[GH-2366]: https://github.com/hashicorp/vagrant/issues/2366
[GH-2374]: https://github.com/hashicorp/vagrant/issues/2374
[GH-2380]: https://github.com/hashicorp/vagrant/issues/2380
[GH-2381]: https://github.com/hashicorp/vagrant/issues/2381
[GH-2382]: https://github.com/hashicorp/vagrant/issues/2382
[GH-2383]: https://github.com/hashicorp/vagrant/issues/2383
[GH-2388]: https://github.com/hashicorp/vagrant/issues/2388
[GH-2390]: https://github.com/hashicorp/vagrant/issues/2390
[GH-2400]: https://github.com/hashicorp/vagrant/issues/2400
[GH-2401]: https://github.com/hashicorp/vagrant/issues/2401
[GH-2404]: https://github.com/hashicorp/vagrant/issues/2404
[GH-2414]: https://github.com/hashicorp/vagrant/issues/2414
[GH-2421]: https://github.com/hashicorp/vagrant/issues/2421
[GH-2434]: https://github.com/hashicorp/vagrant/issues/2434
[GH-2441]: https://github.com/hashicorp/vagrant/issues/2441
[GH-2442]: https://github.com/hashicorp/vagrant/issues/2442
[GH-2448]: https://github.com/hashicorp/vagrant/issues/2448
[GH-2456]: https://github.com/hashicorp/vagrant/issues/2456
[GH-2479]: https://github.com/hashicorp/vagrant/issues/2479
[GH-2482]: https://github.com/hashicorp/vagrant/issues/2482
[GH-2483]: https://github.com/hashicorp/vagrant/issues/2483
[GH-2485]: https://github.com/hashicorp/vagrant/issues/2485
[GH-2488]: https://github.com/hashicorp/vagrant/issues/2488
[GH-2491]: https://github.com/hashicorp/vagrant/issues/2491
[GH-2502]: https://github.com/hashicorp/vagrant/issues/2502
[GH-2505]: https://github.com/hashicorp/vagrant/issues/2505
[GH-2514]: https://github.com/hashicorp/vagrant/issues/2514
[GH-2525]: https://github.com/hashicorp/vagrant/issues/2525
[GH-2543]: https://github.com/hashicorp/vagrant/issues/2543
[GH-2558]: https://github.com/hashicorp/vagrant/issues/2558
[GH-2560]: https://github.com/hashicorp/vagrant/issues/2560
[GH-2564]: https://github.com/hashicorp/vagrant/issues/2564
[GH-2606]: https://github.com/hashicorp/vagrant/issues/2606
[GH-2608]: https://github.com/hashicorp/vagrant/issues/2608
[GH-2610]: https://github.com/hashicorp/vagrant/issues/2610
[GH-2614]: https://github.com/hashicorp/vagrant/issues/2614
[GH-2615]: https://github.com/hashicorp/vagrant/issues/2615
[GH-2617]: https://github.com/hashicorp/vagrant/issues/2617
[GH-2618]: https://github.com/hashicorp/vagrant/issues/2618
[GH-2620]: https://github.com/hashicorp/vagrant/issues/2620
[GH-2621]: https://github.com/hashicorp/vagrant/issues/2621
[GH-2636]: https://github.com/hashicorp/vagrant/issues/2636
[GH-2641]: https://github.com/hashicorp/vagrant/issues/2641
[GH-2643]: https://github.com/hashicorp/vagrant/issues/2643
[GH-2645]: https://github.com/hashicorp/vagrant/issues/2645
[GH-2648]: https://github.com/hashicorp/vagrant/issues/2648
[GH-2649]: https://github.com/hashicorp/vagrant/issues/2649
[GH-2660]: https://github.com/hashicorp/vagrant/issues/2660
[GH-2667]: https://github.com/hashicorp/vagrant/issues/2667
[GH-2669]: https://github.com/hashicorp/vagrant/issues/2669
[GH-2674]: https://github.com/hashicorp/vagrant/issues/2674
[GH-2680]: https://github.com/hashicorp/vagrant/issues/2680
[GH-2689]: https://github.com/hashicorp/vagrant/issues/2689
[GH-2694]: https://github.com/hashicorp/vagrant/issues/2694
[GH-2705]: https://github.com/hashicorp/vagrant/issues/2705
[GH-2712]: https://github.com/hashicorp/vagrant/issues/2712
[GH-2714]: https://github.com/hashicorp/vagrant/issues/2714
[GH-2716]: https://github.com/hashicorp/vagrant/issues/2716
[GH-2718]: https://github.com/hashicorp/vagrant/issues/2718
[GH-2738]: https://github.com/hashicorp/vagrant/issues/2738
[GH-2739]: https://github.com/hashicorp/vagrant/issues/2739
[GH-2751]: https://github.com/hashicorp/vagrant/issues/2751
[GH-2756]: https://github.com/hashicorp/vagrant/issues/2756
[GH-2757]: https://github.com/hashicorp/vagrant/issues/2757
[GH-2766]: https://github.com/hashicorp/vagrant/issues/2766
[GH-2775]: https://github.com/hashicorp/vagrant/issues/2775
[GH-2792]: https://github.com/hashicorp/vagrant/issues/2792
[GH-2800]: https://github.com/hashicorp/vagrant/issues/2800
[GH-2808]: https://github.com/hashicorp/vagrant/issues/2808
[GH-2824]: https://github.com/hashicorp/vagrant/issues/2824
[GH-2838]: https://github.com/hashicorp/vagrant/issues/2838
[GH-2843]: https://github.com/hashicorp/vagrant/issues/2843
[GH-2844]: https://github.com/hashicorp/vagrant/issues/2844
[GH-2852]: https://github.com/hashicorp/vagrant/issues/2852
[GH-2854]: https://github.com/hashicorp/vagrant/issues/2854
[GH-2858]: https://github.com/hashicorp/vagrant/issues/2858
[GH-2869]: https://github.com/hashicorp/vagrant/issues/2869
[GH-2873]: https://github.com/hashicorp/vagrant/issues/2873
[GH-2874]: https://github.com/hashicorp/vagrant/issues/2874
[GH-2906]: https://github.com/hashicorp/vagrant/issues/2906
[GH-2914]: https://github.com/hashicorp/vagrant/issues/2914
[GH-2923]: https://github.com/hashicorp/vagrant/issues/2923
[GH-2927]: https://github.com/hashicorp/vagrant/issues/2927
[GH-2934]: https://github.com/hashicorp/vagrant/issues/2934
[GH-2950]: https://github.com/hashicorp/vagrant/issues/2950
[GH-2966]: https://github.com/hashicorp/vagrant/issues/2966
[GH-2975]: https://github.com/hashicorp/vagrant/issues/2975
[GH-2984]: https://github.com/hashicorp/vagrant/issues/2984
[GH-2991]: https://github.com/hashicorp/vagrant/issues/2991
[GH-2999]: https://github.com/hashicorp/vagrant/issues/2999
[GH-3000]: https://github.com/hashicorp/vagrant/issues/3000
[GH-3005]: https://github.com/hashicorp/vagrant/issues/3005
[GH-3023]: https://github.com/hashicorp/vagrant/issues/3023
[GH-3027]: https://github.com/hashicorp/vagrant/issues/3027
[GH-3029]: https://github.com/hashicorp/vagrant/issues/3029
[GH-3040]: https://github.com/hashicorp/vagrant/issues/3040
[GH-3045]: https://github.com/hashicorp/vagrant/issues/3045
[GH-3051]: https://github.com/hashicorp/vagrant/issues/3051
[GH-3055]: https://github.com/hashicorp/vagrant/issues/3055
[GH-3091]: https://github.com/hashicorp/vagrant/issues/3091
[GH-3092]: https://github.com/hashicorp/vagrant/issues/3092
[GH-3094]: https://github.com/hashicorp/vagrant/issues/3094
[GH-3095]: https://github.com/hashicorp/vagrant/issues/3095
[GH-3100]: https://github.com/hashicorp/vagrant/issues/3100
[GH-3107]: https://github.com/hashicorp/vagrant/issues/3107
[GH-3111]: https://github.com/hashicorp/vagrant/issues/3111
[GH-3119]: https://github.com/hashicorp/vagrant/issues/3119
[GH-3132]: https://github.com/hashicorp/vagrant/issues/3132
[GH-3138]: https://github.com/hashicorp/vagrant/issues/3138
[GH-3143]: https://github.com/hashicorp/vagrant/issues/3143
[GH-3159]: https://github.com/hashicorp/vagrant/issues/3159
[GH-3163]: https://github.com/hashicorp/vagrant/issues/3163
[GH-3167]: https://github.com/hashicorp/vagrant/issues/3167
[GH-3180]: https://github.com/hashicorp/vagrant/issues/3180
[GH-3183]: https://github.com/hashicorp/vagrant/issues/3183
[GH-3186]: https://github.com/hashicorp/vagrant/issues/3186
[GH-3187]: https://github.com/hashicorp/vagrant/issues/3187
[GH-3193]: https://github.com/hashicorp/vagrant/issues/3193
[GH-3200]: https://github.com/hashicorp/vagrant/issues/3200
[GH-3202]: https://github.com/hashicorp/vagrant/issues/3202
[GH-3203]: https://github.com/hashicorp/vagrant/issues/3203
[GH-3207]: https://github.com/hashicorp/vagrant/issues/3207
[GH-3212]: https://github.com/hashicorp/vagrant/issues/3212
[GH-3216]: https://github.com/hashicorp/vagrant/issues/3216
[GH-3218]: https://github.com/hashicorp/vagrant/issues/3218
[GH-3219]: https://github.com/hashicorp/vagrant/issues/3219
[GH-3223]: https://github.com/hashicorp/vagrant/issues/3223
[GH-3235]: https://github.com/hashicorp/vagrant/issues/3235
[GH-3242]: https://github.com/hashicorp/vagrant/issues/3242
[GH-3251]: https://github.com/hashicorp/vagrant/issues/3251
[GH-3256]: https://github.com/hashicorp/vagrant/issues/3256
[GH-3257]: https://github.com/hashicorp/vagrant/issues/3257
[GH-3260]: https://github.com/hashicorp/vagrant/issues/3260
[GH-3271]: https://github.com/hashicorp/vagrant/issues/3271
[GH-3272]: https://github.com/hashicorp/vagrant/issues/3272
[GH-3282]: https://github.com/hashicorp/vagrant/issues/3282
[GH-3283]: https://github.com/hashicorp/vagrant/issues/3283
[GH-3292]: https://github.com/hashicorp/vagrant/issues/3292
[GH-3293]: https://github.com/hashicorp/vagrant/issues/3293
[GH-3301]: https://github.com/hashicorp/vagrant/issues/3301
[GH-3304]: https://github.com/hashicorp/vagrant/issues/3304
[GH-3306]: https://github.com/hashicorp/vagrant/issues/3306
[GH-3316]: https://github.com/hashicorp/vagrant/issues/3316
[GH-3321]: https://github.com/hashicorp/vagrant/issues/3321
[GH-3322]: https://github.com/hashicorp/vagrant/issues/3322
[GH-3326]: https://github.com/hashicorp/vagrant/issues/3326
[GH-3327]: https://github.com/hashicorp/vagrant/issues/3327
[GH-3332]: https://github.com/hashicorp/vagrant/issues/3332
[GH-3336]: https://github.com/hashicorp/vagrant/issues/3336
[GH-3338]: https://github.com/hashicorp/vagrant/issues/3338
[GH-3349]: https://github.com/hashicorp/vagrant/issues/3349
[GH-3354]: https://github.com/hashicorp/vagrant/issues/3354
[GH-3356]: https://github.com/hashicorp/vagrant/issues/3356
[GH-3364]: https://github.com/hashicorp/vagrant/issues/3364
[GH-3365]: https://github.com/hashicorp/vagrant/issues/3365
[GH-3368]: https://github.com/hashicorp/vagrant/issues/3368
[GH-3372]: https://github.com/hashicorp/vagrant/issues/3372
[GH-3382]: https://github.com/hashicorp/vagrant/issues/3382
[GH-3386]: https://github.com/hashicorp/vagrant/issues/3386
[GH-3391]: https://github.com/hashicorp/vagrant/issues/3391
[GH-3394]: https://github.com/hashicorp/vagrant/issues/3394
[GH-3396]: https://github.com/hashicorp/vagrant/issues/3396
[GH-3398]: https://github.com/hashicorp/vagrant/issues/3398
[GH-3405]: https://github.com/hashicorp/vagrant/issues/3405
[GH-3419]: https://github.com/hashicorp/vagrant/issues/3419
[GH-3420]: https://github.com/hashicorp/vagrant/issues/3420
[GH-3423]: https://github.com/hashicorp/vagrant/issues/3423
[GH-3424]: https://github.com/hashicorp/vagrant/issues/3424
[GH-3425]: https://github.com/hashicorp/vagrant/issues/3425
[GH-3436]: https://github.com/hashicorp/vagrant/issues/3436
[GH-3442]: https://github.com/hashicorp/vagrant/issues/3442
[GH-3444]: https://github.com/hashicorp/vagrant/issues/3444
[GH-3446]: https://github.com/hashicorp/vagrant/issues/3446
[GH-3452]: https://github.com/hashicorp/vagrant/issues/3452
[GH-3462]: https://github.com/hashicorp/vagrant/issues/3462
[GH-3467]: https://github.com/hashicorp/vagrant/issues/3467
[GH-3469]: https://github.com/hashicorp/vagrant/issues/3469
[GH-3470]: https://github.com/hashicorp/vagrant/issues/3470
[GH-3474]: https://github.com/hashicorp/vagrant/issues/3474
[GH-3482]: https://github.com/hashicorp/vagrant/issues/3482
[GH-3485]: https://github.com/hashicorp/vagrant/issues/3485
[GH-3494]: https://github.com/hashicorp/vagrant/issues/3494
[GH-3502]: https://github.com/hashicorp/vagrant/issues/3502
[GH-3505]: https://github.com/hashicorp/vagrant/issues/3505
[GH-3511]: https://github.com/hashicorp/vagrant/issues/3511
[GH-3536]: https://github.com/hashicorp/vagrant/issues/3536
[GH-3539]: https://github.com/hashicorp/vagrant/issues/3539
[GH-3544]: https://github.com/hashicorp/vagrant/issues/3544
[GH-3547]: https://github.com/hashicorp/vagrant/issues/3547
[GH-3549]: https://github.com/hashicorp/vagrant/issues/3549
[GH-3552]: https://github.com/hashicorp/vagrant/issues/3552
[GH-3553]: https://github.com/hashicorp/vagrant/issues/3553
[GH-3564]: https://github.com/hashicorp/vagrant/issues/3564
[GH-3570]: https://github.com/hashicorp/vagrant/issues/3570
[GH-3575]: https://github.com/hashicorp/vagrant/issues/3575
[GH-3583]: https://github.com/hashicorp/vagrant/issues/3583
[GH-3588]: https://github.com/hashicorp/vagrant/issues/3588
[GH-3604]: https://github.com/hashicorp/vagrant/issues/3604
[GH-3610]: https://github.com/hashicorp/vagrant/issues/3610
[GH-3611]: https://github.com/hashicorp/vagrant/issues/3611
[GH-3615]: https://github.com/hashicorp/vagrant/issues/3615
[GH-3620]: https://github.com/hashicorp/vagrant/issues/3620
[GH-3625]: https://github.com/hashicorp/vagrant/issues/3625
[GH-3628]: https://github.com/hashicorp/vagrant/issues/3628
[GH-3636]: https://github.com/hashicorp/vagrant/issues/3636
[GH-3637]: https://github.com/hashicorp/vagrant/issues/3637
[GH-3638]: https://github.com/hashicorp/vagrant/issues/3638
[GH-3642]: https://github.com/hashicorp/vagrant/issues/3642
[GH-3643]: https://github.com/hashicorp/vagrant/issues/3643
[GH-3648]: https://github.com/hashicorp/vagrant/issues/3648
[GH-3649]: https://github.com/hashicorp/vagrant/issues/3649
[GH-3651]: https://github.com/hashicorp/vagrant/issues/3651
[GH-3654]: https://github.com/hashicorp/vagrant/issues/3654
[GH-3657]: https://github.com/hashicorp/vagrant/issues/3657
[GH-3662]: https://github.com/hashicorp/vagrant/issues/3662
[GH-3664]: https://github.com/hashicorp/vagrant/issues/3664
[GH-3670]: https://github.com/hashicorp/vagrant/issues/3670
[GH-3677]: https://github.com/hashicorp/vagrant/issues/3677
[GH-3680]: https://github.com/hashicorp/vagrant/issues/3680
[GH-3684]: https://github.com/hashicorp/vagrant/issues/3684
[GH-3685]: https://github.com/hashicorp/vagrant/issues/3685
[GH-3686]: https://github.com/hashicorp/vagrant/issues/3686
[GH-3687]: https://github.com/hashicorp/vagrant/issues/3687
[GH-3698]: https://github.com/hashicorp/vagrant/issues/3698
[GH-3712]: https://github.com/hashicorp/vagrant/issues/3712
[GH-3713]: https://github.com/hashicorp/vagrant/issues/3713
[GH-3719]: https://github.com/hashicorp/vagrant/issues/3719
[GH-3723]: https://github.com/hashicorp/vagrant/issues/3723
[GH-3727]: https://github.com/hashicorp/vagrant/issues/3727
[GH-3729]: https://github.com/hashicorp/vagrant/issues/3729
[GH-3731]: https://github.com/hashicorp/vagrant/issues/3731
[GH-3732]: https://github.com/hashicorp/vagrant/issues/3732
[GH-3734]: https://github.com/hashicorp/vagrant/issues/3734
[GH-3735]: https://github.com/hashicorp/vagrant/issues/3735
[GH-3739]: https://github.com/hashicorp/vagrant/issues/3739
[GH-3743]: https://github.com/hashicorp/vagrant/issues/3743
[GH-3744]: https://github.com/hashicorp/vagrant/issues/3744
[GH-3763]: https://github.com/hashicorp/vagrant/issues/3763
[GH-3775]: https://github.com/hashicorp/vagrant/issues/3775
[GH-3776]: https://github.com/hashicorp/vagrant/issues/3776
[GH-3783]: https://github.com/hashicorp/vagrant/issues/3783
[GH-3790]: https://github.com/hashicorp/vagrant/issues/3790
[GH-3791]: https://github.com/hashicorp/vagrant/issues/3791
[GH-3798]: https://github.com/hashicorp/vagrant/issues/3798
[GH-3799]: https://github.com/hashicorp/vagrant/issues/3799
[GH-3804]: https://github.com/hashicorp/vagrant/issues/3804
[GH-3808]: https://github.com/hashicorp/vagrant/issues/3808
[GH-3810]: https://github.com/hashicorp/vagrant/issues/3810
[GH-3812]: https://github.com/hashicorp/vagrant/issues/3812
[GH-3815]: https://github.com/hashicorp/vagrant/issues/3815
[GH-3816]: https://github.com/hashicorp/vagrant/issues/3816
[GH-3818]: https://github.com/hashicorp/vagrant/issues/3818
[GH-3825]: https://github.com/hashicorp/vagrant/issues/3825
[GH-3827]: https://github.com/hashicorp/vagrant/issues/3827
[GH-3830]: https://github.com/hashicorp/vagrant/issues/3830
[GH-3837]: https://github.com/hashicorp/vagrant/issues/3837
[GH-3838]: https://github.com/hashicorp/vagrant/issues/3838
[GH-3845]: https://github.com/hashicorp/vagrant/issues/3845
[GH-3852]: https://github.com/hashicorp/vagrant/issues/3852
[GH-3857]: https://github.com/hashicorp/vagrant/issues/3857
[GH-3859]: https://github.com/hashicorp/vagrant/issues/3859
[GH-3861]: https://github.com/hashicorp/vagrant/issues/3861
[GH-3864]: https://github.com/hashicorp/vagrant/issues/3864
[GH-3873]: https://github.com/hashicorp/vagrant/issues/3873
[GH-3874]: https://github.com/hashicorp/vagrant/issues/3874
[GH-3875]: https://github.com/hashicorp/vagrant/issues/3875
[GH-3886]: https://github.com/hashicorp/vagrant/issues/3886
[GH-3900]: https://github.com/hashicorp/vagrant/issues/3900
[GH-3903]: https://github.com/hashicorp/vagrant/issues/3903
[GH-3921]: https://github.com/hashicorp/vagrant/issues/3921
[GH-3922]: https://github.com/hashicorp/vagrant/issues/3922
[GH-3924]: https://github.com/hashicorp/vagrant/issues/3924
[GH-3932]: https://github.com/hashicorp/vagrant/issues/3932
[GH-3934]: https://github.com/hashicorp/vagrant/issues/3934
[GH-3959]: https://github.com/hashicorp/vagrant/issues/3959
[GH-3962]: https://github.com/hashicorp/vagrant/issues/3962
[GH-3963]: https://github.com/hashicorp/vagrant/issues/3963
[GH-3966]: https://github.com/hashicorp/vagrant/issues/3966
[GH-3983]: https://github.com/hashicorp/vagrant/issues/3983
[GH-3987]: https://github.com/hashicorp/vagrant/issues/3987
[GH-3990]: https://github.com/hashicorp/vagrant/issues/3990
[GH-3991]: https://github.com/hashicorp/vagrant/issues/3991
[GH-4000]: https://github.com/hashicorp/vagrant/issues/4000
[GH-4008]: https://github.com/hashicorp/vagrant/issues/4008
[GH-4017]: https://github.com/hashicorp/vagrant/issues/4017
[GH-4031]: https://github.com/hashicorp/vagrant/issues/4031
[GH-4038]: https://github.com/hashicorp/vagrant/issues/4038
[GH-4042]: https://github.com/hashicorp/vagrant/issues/4042
[GH-4044]: https://github.com/hashicorp/vagrant/issues/4044
[GH-4047]: https://github.com/hashicorp/vagrant/issues/4047
[GH-4057]: https://github.com/hashicorp/vagrant/issues/4057
[GH-4065]: https://github.com/hashicorp/vagrant/issues/4065
[GH-4066]: https://github.com/hashicorp/vagrant/issues/4066
[GH-4071]: https://github.com/hashicorp/vagrant/issues/4071
[GH-4087]: https://github.com/hashicorp/vagrant/issues/4087
[GH-4088]: https://github.com/hashicorp/vagrant/issues/4088
[GH-4090]: https://github.com/hashicorp/vagrant/issues/4090
[GH-4094]: https://github.com/hashicorp/vagrant/issues/4094
[GH-4099]: https://github.com/hashicorp/vagrant/issues/4099
[GH-4100]: https://github.com/hashicorp/vagrant/issues/4100
[GH-4103]: https://github.com/hashicorp/vagrant/issues/4103
[GH-4104]: https://github.com/hashicorp/vagrant/issues/4104
[GH-4132]: https://github.com/hashicorp/vagrant/issues/4132
[GH-4143]: https://github.com/hashicorp/vagrant/issues/4143
[GH-4152]: https://github.com/hashicorp/vagrant/issues/4152
[GH-4159]: https://github.com/hashicorp/vagrant/issues/4159
[GH-4168]: https://github.com/hashicorp/vagrant/issues/4168
[GH-4169]: https://github.com/hashicorp/vagrant/issues/4169
[GH-4179]: https://github.com/hashicorp/vagrant/issues/4179
[GH-4195]: https://github.com/hashicorp/vagrant/issues/4195
[GH-4206]: https://github.com/hashicorp/vagrant/issues/4206
[GH-4208]: https://github.com/hashicorp/vagrant/issues/4208
[GH-4224]: https://github.com/hashicorp/vagrant/issues/4224
[GH-4228]: https://github.com/hashicorp/vagrant/issues/4228
[GH-4230]: https://github.com/hashicorp/vagrant/issues/4230
[GH-4234]: https://github.com/hashicorp/vagrant/issues/4234
[GH-4262]: https://github.com/hashicorp/vagrant/issues/4262
[GH-4271]: https://github.com/hashicorp/vagrant/issues/4271
[GH-4274]: https://github.com/hashicorp/vagrant/issues/4274
[GH-4281]: https://github.com/hashicorp/vagrant/issues/4281
[GH-4282]: https://github.com/hashicorp/vagrant/issues/4282
[GH-4294]: https://github.com/hashicorp/vagrant/issues/4294
[GH-4301]: https://github.com/hashicorp/vagrant/issues/4301
[GH-4302]: https://github.com/hashicorp/vagrant/issues/4302
[GH-4303]: https://github.com/hashicorp/vagrant/issues/4303
[GH-4304]: https://github.com/hashicorp/vagrant/issues/4304
[GH-4307]: https://github.com/hashicorp/vagrant/issues/4307
[GH-4309]: https://github.com/hashicorp/vagrant/issues/4309
[GH-4319]: https://github.com/hashicorp/vagrant/issues/4319
[GH-4324]: https://github.com/hashicorp/vagrant/issues/4324
[GH-4328]: https://github.com/hashicorp/vagrant/issues/4328
[GH-4335]: https://github.com/hashicorp/vagrant/issues/4335
[GH-4342]: https://github.com/hashicorp/vagrant/issues/4342
[GH-4344]: https://github.com/hashicorp/vagrant/issues/4344
[GH-4346]: https://github.com/hashicorp/vagrant/issues/4346
[GH-4352]: https://github.com/hashicorp/vagrant/issues/4352
[GH-4369]: https://github.com/hashicorp/vagrant/issues/4369
[GH-4371]: https://github.com/hashicorp/vagrant/issues/4371
[GH-4377]: https://github.com/hashicorp/vagrant/issues/4377
[GH-4378]: https://github.com/hashicorp/vagrant/issues/4378
[GH-4383]: https://github.com/hashicorp/vagrant/issues/4383
[GH-4387]: https://github.com/hashicorp/vagrant/issues/4387
[GH-4392]: https://github.com/hashicorp/vagrant/issues/4392
[GH-4393]: https://github.com/hashicorp/vagrant/issues/4393
[GH-4402]: https://github.com/hashicorp/vagrant/issues/4402
[GH-4403]: https://github.com/hashicorp/vagrant/issues/4403
[GH-4408]: https://github.com/hashicorp/vagrant/issues/4408
[GH-4410]: https://github.com/hashicorp/vagrant/issues/4410
[GH-4418]: https://github.com/hashicorp/vagrant/issues/4418
[GH-4421]: https://github.com/hashicorp/vagrant/issues/4421
[GH-4422]: https://github.com/hashicorp/vagrant/issues/4422
[GH-4433]: https://github.com/hashicorp/vagrant/issues/4433
[GH-4437]: https://github.com/hashicorp/vagrant/issues/4437
[GH-4438]: https://github.com/hashicorp/vagrant/issues/4438
[GH-4443]: https://github.com/hashicorp/vagrant/issues/4443
[GH-4452]: https://github.com/hashicorp/vagrant/issues/4452
[GH-4462]: https://github.com/hashicorp/vagrant/issues/4462
[GH-4467]: https://github.com/hashicorp/vagrant/issues/4467
[GH-4468]: https://github.com/hashicorp/vagrant/issues/4468
[GH-4469]: https://github.com/hashicorp/vagrant/issues/4469
[GH-4471]: https://github.com/hashicorp/vagrant/issues/4471
[GH-4473]: https://github.com/hashicorp/vagrant/issues/4473
[GH-4477]: https://github.com/hashicorp/vagrant/issues/4477
[GH-4484]: https://github.com/hashicorp/vagrant/issues/4484
[GH-4492]: https://github.com/hashicorp/vagrant/issues/4492
[GH-4499]: https://github.com/hashicorp/vagrant/issues/4499
[GH-4504]: https://github.com/hashicorp/vagrant/issues/4504
[GH-4505]: https://github.com/hashicorp/vagrant/issues/4505
[GH-4506]: https://github.com/hashicorp/vagrant/issues/4506
[GH-4513]: https://github.com/hashicorp/vagrant/issues/4513
[GH-4518]: https://github.com/hashicorp/vagrant/issues/4518
[GH-4525]: https://github.com/hashicorp/vagrant/issues/4525
[GH-4526]: https://github.com/hashicorp/vagrant/issues/4526
[GH-4527]: https://github.com/hashicorp/vagrant/issues/4527
[GH-4534]: https://github.com/hashicorp/vagrant/issues/4534
[GH-4535]: https://github.com/hashicorp/vagrant/issues/4535
[GH-4548]: https://github.com/hashicorp/vagrant/issues/4548
[GH-4552]: https://github.com/hashicorp/vagrant/issues/4552
[GH-4565]: https://github.com/hashicorp/vagrant/issues/4565
[GH-4571]: https://github.com/hashicorp/vagrant/issues/4571
[GH-4580]: https://github.com/hashicorp/vagrant/issues/4580
[GH-4595]: https://github.com/hashicorp/vagrant/issues/4595
[GH-4597]: https://github.com/hashicorp/vagrant/issues/4597
[GH-4598]: https://github.com/hashicorp/vagrant/issues/4598
[GH-4614]: https://github.com/hashicorp/vagrant/issues/4614
[GH-4619]: https://github.com/hashicorp/vagrant/issues/4619
[GH-4621]: https://github.com/hashicorp/vagrant/issues/4621
[GH-4641]: https://github.com/hashicorp/vagrant/issues/4641
[GH-4650]: https://github.com/hashicorp/vagrant/issues/4650
[GH-4657]: https://github.com/hashicorp/vagrant/issues/4657
[GH-4665]: https://github.com/hashicorp/vagrant/issues/4665
[GH-4670]: https://github.com/hashicorp/vagrant/issues/4670
[GH-4671]: https://github.com/hashicorp/vagrant/issues/4671
[GH-4681]: https://github.com/hashicorp/vagrant/issues/4681
[GH-4684]: https://github.com/hashicorp/vagrant/issues/4684
[GH-4687]: https://github.com/hashicorp/vagrant/issues/4687
[GH-4691]: https://github.com/hashicorp/vagrant/issues/4691
[GH-4710]: https://github.com/hashicorp/vagrant/issues/4710
[GH-4711]: https://github.com/hashicorp/vagrant/issues/4711
[GH-4726]: https://github.com/hashicorp/vagrant/issues/4726
[GH-4738]: https://github.com/hashicorp/vagrant/issues/4738
[GH-4812]: https://github.com/hashicorp/vagrant/issues/4812
[GH-4815]: https://github.com/hashicorp/vagrant/issues/4815
[GH-4847]: https://github.com/hashicorp/vagrant/issues/4847
[GH-4867]: https://github.com/hashicorp/vagrant/issues/4867
[GH-4895]: https://github.com/hashicorp/vagrant/issues/4895
[GH-4903]: https://github.com/hashicorp/vagrant/issues/4903
[GH-4904]: https://github.com/hashicorp/vagrant/issues/4904
[GH-4905]: https://github.com/hashicorp/vagrant/issues/4905
[GH-4906]: https://github.com/hashicorp/vagrant/issues/4906
[GH-4943]: https://github.com/hashicorp/vagrant/issues/4943
[GH-4964]: https://github.com/hashicorp/vagrant/issues/4964
[GH-4975]: https://github.com/hashicorp/vagrant/issues/4975
[GH-4986]: https://github.com/hashicorp/vagrant/issues/4986
[GH-4988]: https://github.com/hashicorp/vagrant/issues/4988
[GH-4991]: https://github.com/hashicorp/vagrant/issues/4991
[GH-5004]: https://github.com/hashicorp/vagrant/issues/5004
[GH-5017]: https://github.com/hashicorp/vagrant/issues/5017
[GH-5018]: https://github.com/hashicorp/vagrant/issues/5018
[GH-5021]: https://github.com/hashicorp/vagrant/issues/5021
[GH-5056]: https://github.com/hashicorp/vagrant/issues/5056
[GH-5070]: https://github.com/hashicorp/vagrant/issues/5070
[GH-5085]: https://github.com/hashicorp/vagrant/issues/5085
[GH-5086]: https://github.com/hashicorp/vagrant/issues/5086
[GH-5092]: https://github.com/hashicorp/vagrant/issues/5092
[GH-5093]: https://github.com/hashicorp/vagrant/issues/5093
[GH-5101]: https://github.com/hashicorp/vagrant/issues/5101
[GH-5130]: https://github.com/hashicorp/vagrant/issues/5130
[GH-5143]: https://github.com/hashicorp/vagrant/issues/5143
[GH-5145]: https://github.com/hashicorp/vagrant/issues/5145
[GH-5170]: https://github.com/hashicorp/vagrant/issues/5170
[GH-5175]: https://github.com/hashicorp/vagrant/issues/5175
[GH-5182]: https://github.com/hashicorp/vagrant/issues/5182
[GH-5183]: https://github.com/hashicorp/vagrant/issues/5183
[GH-5193]: https://github.com/hashicorp/vagrant/issues/5193
[GH-5199]: https://github.com/hashicorp/vagrant/issues/5199
[GH-5204]: https://github.com/hashicorp/vagrant/issues/5204
[GH-5207]: https://github.com/hashicorp/vagrant/issues/5207
[GH-5209]: https://github.com/hashicorp/vagrant/issues/5209
[GH-5216]: https://github.com/hashicorp/vagrant/issues/5216
[GH-5218]: https://github.com/hashicorp/vagrant/issues/5218
[GH-5220]: https://github.com/hashicorp/vagrant/issues/5220
[GH-5221]: https://github.com/hashicorp/vagrant/issues/5221
[GH-5222]: https://github.com/hashicorp/vagrant/issues/5222
[GH-5233]: https://github.com/hashicorp/vagrant/issues/5233
[GH-5245]: https://github.com/hashicorp/vagrant/issues/5245
[GH-5249]: https://github.com/hashicorp/vagrant/issues/5249
[GH-5252]: https://github.com/hashicorp/vagrant/issues/5252
[GH-5256]: https://github.com/hashicorp/vagrant/issues/5256
[GH-5261]: https://github.com/hashicorp/vagrant/issues/5261
[GH-5277]: https://github.com/hashicorp/vagrant/issues/5277
[GH-5282]: https://github.com/hashicorp/vagrant/issues/5282
[GH-5283]: https://github.com/hashicorp/vagrant/issues/5283
[GH-5290]: https://github.com/hashicorp/vagrant/issues/5290
[GH-5292]: https://github.com/hashicorp/vagrant/issues/5292
[GH-5302]: https://github.com/hashicorp/vagrant/issues/5302
[GH-5303]: https://github.com/hashicorp/vagrant/issues/5303
[GH-5307]: https://github.com/hashicorp/vagrant/issues/5307
[GH-5308]: https://github.com/hashicorp/vagrant/issues/5308
[GH-5315]: https://github.com/hashicorp/vagrant/issues/5315
[GH-5320]: https://github.com/hashicorp/vagrant/issues/5320
[GH-5325]: https://github.com/hashicorp/vagrant/issues/5325
[GH-5339]: https://github.com/hashicorp/vagrant/issues/5339
[GH-5349]: https://github.com/hashicorp/vagrant/issues/5349
[GH-5359]: https://github.com/hashicorp/vagrant/issues/5359
[GH-5369]: https://github.com/hashicorp/vagrant/issues/5369
[GH-5389]: https://github.com/hashicorp/vagrant/issues/5389
[GH-5395]: https://github.com/hashicorp/vagrant/issues/5395
[GH-5399]: https://github.com/hashicorp/vagrant/issues/5399
[GH-5418]: https://github.com/hashicorp/vagrant/issues/5418
[GH-5430]: https://github.com/hashicorp/vagrant/issues/5430
[GH-5433]: https://github.com/hashicorp/vagrant/issues/5433
[GH-5437]: https://github.com/hashicorp/vagrant/issues/5437
[GH-5478]: https://github.com/hashicorp/vagrant/issues/5478
[GH-5480]: https://github.com/hashicorp/vagrant/issues/5480
[GH-5512]: https://github.com/hashicorp/vagrant/issues/5512
[GH-5516]: https://github.com/hashicorp/vagrant/issues/5516
[GH-5517]: https://github.com/hashicorp/vagrant/issues/5517
[GH-5523]: https://github.com/hashicorp/vagrant/issues/5523
[GH-5527]: https://github.com/hashicorp/vagrant/issues/5527
[GH-5531]: https://github.com/hashicorp/vagrant/issues/5531
[GH-5532]: https://github.com/hashicorp/vagrant/issues/5532
[GH-5536]: https://github.com/hashicorp/vagrant/issues/5536
[GH-5538]: https://github.com/hashicorp/vagrant/issues/5538
[GH-5539]: https://github.com/hashicorp/vagrant/issues/5539
[GH-5549]: https://github.com/hashicorp/vagrant/issues/5549
[GH-5550]: https://github.com/hashicorp/vagrant/issues/5550
[GH-5551]: https://github.com/hashicorp/vagrant/issues/5551
[GH-5558]: https://github.com/hashicorp/vagrant/issues/5558
[GH-5573]: https://github.com/hashicorp/vagrant/issues/5573
[GH-5577]: https://github.com/hashicorp/vagrant/issues/5577
[GH-5601]: https://github.com/hashicorp/vagrant/issues/5601
[GH-5604]: https://github.com/hashicorp/vagrant/issues/5604
[GH-5607]: https://github.com/hashicorp/vagrant/issues/5607
[GH-5612]: https://github.com/hashicorp/vagrant/issues/5612
[GH-5616]: https://github.com/hashicorp/vagrant/issues/5616
[GH-5623]: https://github.com/hashicorp/vagrant/issues/5623
[GH-5632]: https://github.com/hashicorp/vagrant/issues/5632
[GH-5637]: https://github.com/hashicorp/vagrant/issues/5637
[GH-5647]: https://github.com/hashicorp/vagrant/issues/5647
[GH-5651]: https://github.com/hashicorp/vagrant/issues/5651
[GH-5657]: https://github.com/hashicorp/vagrant/issues/5657
[GH-5658]: https://github.com/hashicorp/vagrant/issues/5658
[GH-5669]: https://github.com/hashicorp/vagrant/issues/5669
[GH-5670]: https://github.com/hashicorp/vagrant/issues/5670
[GH-5677]: https://github.com/hashicorp/vagrant/issues/5677
[GH-5691]: https://github.com/hashicorp/vagrant/issues/5691
[GH-5695]: https://github.com/hashicorp/vagrant/issues/5695
[GH-5698]: https://github.com/hashicorp/vagrant/issues/5698
[GH-5707]: https://github.com/hashicorp/vagrant/issues/5707
[GH-5709]: https://github.com/hashicorp/vagrant/issues/5709
[GH-5721]: https://github.com/hashicorp/vagrant/issues/5721
[GH-5730]: https://github.com/hashicorp/vagrant/issues/5730
[GH-5737]: https://github.com/hashicorp/vagrant/issues/5737
[GH-5738]: https://github.com/hashicorp/vagrant/issues/5738
[GH-5747]: https://github.com/hashicorp/vagrant/issues/5747
[GH-5748]: https://github.com/hashicorp/vagrant/issues/5748
[GH-5749]: https://github.com/hashicorp/vagrant/issues/5749
[GH-5750]: https://github.com/hashicorp/vagrant/issues/5750
[GH-5753]: https://github.com/hashicorp/vagrant/issues/5753
[GH-5765]: https://github.com/hashicorp/vagrant/issues/5765
[GH-5769]: https://github.com/hashicorp/vagrant/issues/5769
[GH-5770]: https://github.com/hashicorp/vagrant/issues/5770
[GH-5771]: https://github.com/hashicorp/vagrant/issues/5771
[GH-5773]: https://github.com/hashicorp/vagrant/issues/5773
[GH-5780]: https://github.com/hashicorp/vagrant/issues/5780
[GH-5785]: https://github.com/hashicorp/vagrant/issues/5785
[GH-5798]: https://github.com/hashicorp/vagrant/issues/5798
[GH-5803]: https://github.com/hashicorp/vagrant/issues/5803
[GH-5805]: https://github.com/hashicorp/vagrant/issues/5805
[GH-5815]: https://github.com/hashicorp/vagrant/issues/5815
[GH-5818]: https://github.com/hashicorp/vagrant/issues/5818
[GH-5846]: https://github.com/hashicorp/vagrant/issues/5846
[GH-5852]: https://github.com/hashicorp/vagrant/issues/5852
[GH-5860]: https://github.com/hashicorp/vagrant/issues/5860
[GH-5881]: https://github.com/hashicorp/vagrant/issues/5881
[GH-5892]: https://github.com/hashicorp/vagrant/issues/5892
[GH-5895]: https://github.com/hashicorp/vagrant/issues/5895
[GH-5905]: https://github.com/hashicorp/vagrant/issues/5905
[GH-5910]: https://github.com/hashicorp/vagrant/issues/5910
[GH-5912]: https://github.com/hashicorp/vagrant/issues/5912
[GH-5913]: https://github.com/hashicorp/vagrant/issues/5913
[GH-5924]: https://github.com/hashicorp/vagrant/issues/5924
[GH-5928]: https://github.com/hashicorp/vagrant/issues/5928
[GH-5931]: https://github.com/hashicorp/vagrant/issues/5931
[GH-5932]: https://github.com/hashicorp/vagrant/issues/5932
[GH-5933]: https://github.com/hashicorp/vagrant/issues/5933
[GH-5936]: https://github.com/hashicorp/vagrant/issues/5936
[GH-5937]: https://github.com/hashicorp/vagrant/issues/5937
[GH-5948]: https://github.com/hashicorp/vagrant/issues/5948
[GH-5954]: https://github.com/hashicorp/vagrant/issues/5954
[GH-5957]: https://github.com/hashicorp/vagrant/issues/5957
[GH-5958]: https://github.com/hashicorp/vagrant/issues/5958
[GH-5967]: https://github.com/hashicorp/vagrant/issues/5967
[GH-5971]: https://github.com/hashicorp/vagrant/issues/5971
[GH-5978]: https://github.com/hashicorp/vagrant/issues/5978
[GH-5981]: https://github.com/hashicorp/vagrant/issues/5981
[GH-5986]: https://github.com/hashicorp/vagrant/issues/5986
[GH-5987]: https://github.com/hashicorp/vagrant/issues/5987
[GH-5988]: https://github.com/hashicorp/vagrant/issues/5988
[GH-5999]: https://github.com/hashicorp/vagrant/issues/5999
[GH-6005]: https://github.com/hashicorp/vagrant/issues/6005
[GH-6017]: https://github.com/hashicorp/vagrant/issues/6017
[GH-6025]: https://github.com/hashicorp/vagrant/issues/6025
[GH-6042]: https://github.com/hashicorp/vagrant/issues/6042
[GH-6049]: https://github.com/hashicorp/vagrant/issues/6049
[GH-6061]: https://github.com/hashicorp/vagrant/issues/6061
[GH-6064]: https://github.com/hashicorp/vagrant/issues/6064
[GH-6073]: https://github.com/hashicorp/vagrant/issues/6073
[GH-6085]: https://github.com/hashicorp/vagrant/issues/6085
[GH-6097]: https://github.com/hashicorp/vagrant/issues/6097
[GH-6102]: https://github.com/hashicorp/vagrant/issues/6102
[GH-6110]: https://github.com/hashicorp/vagrant/issues/6110
[GH-6139]: https://github.com/hashicorp/vagrant/issues/6139
[GH-6150]: https://github.com/hashicorp/vagrant/issues/6150
[GH-6160]: https://github.com/hashicorp/vagrant/issues/6160
[GH-6185]: https://github.com/hashicorp/vagrant/issues/6185
[GH-6195]: https://github.com/hashicorp/vagrant/issues/6195
[GH-6203]: https://github.com/hashicorp/vagrant/issues/6203
[GH-6209]: https://github.com/hashicorp/vagrant/issues/6209
[GH-6213]: https://github.com/hashicorp/vagrant/issues/6213
[GH-6220]: https://github.com/hashicorp/vagrant/issues/6220
[GH-6225]: https://github.com/hashicorp/vagrant/issues/6225
[GH-6229]: https://github.com/hashicorp/vagrant/issues/6229
[GH-6231]: https://github.com/hashicorp/vagrant/issues/6231
[GH-6259]: https://github.com/hashicorp/vagrant/issues/6259
[GH-6278]: https://github.com/hashicorp/vagrant/issues/6278
[GH-6288]: https://github.com/hashicorp/vagrant/issues/6288
[GH-6301]: https://github.com/hashicorp/vagrant/issues/6301
[GH-6309]: https://github.com/hashicorp/vagrant/issues/6309
[GH-6316]: https://github.com/hashicorp/vagrant/issues/6316
[GH-6323]: https://github.com/hashicorp/vagrant/issues/6323
[GH-6325]: https://github.com/hashicorp/vagrant/issues/6325
[GH-6327]: https://github.com/hashicorp/vagrant/issues/6327
[GH-6342]: https://github.com/hashicorp/vagrant/issues/6342
[GH-6348]: https://github.com/hashicorp/vagrant/issues/6348
[GH-6360]: https://github.com/hashicorp/vagrant/issues/6360
[GH-6367]: https://github.com/hashicorp/vagrant/issues/6367
[GH-6372]: https://github.com/hashicorp/vagrant/issues/6372
[GH-6386]: https://github.com/hashicorp/vagrant/issues/6386
[GH-6389]: https://github.com/hashicorp/vagrant/issues/6389
[GH-6395]: https://github.com/hashicorp/vagrant/issues/6395
[GH-6399]: https://github.com/hashicorp/vagrant/issues/6399
[GH-6404]: https://github.com/hashicorp/vagrant/issues/6404
[GH-6406]: https://github.com/hashicorp/vagrant/issues/6406
[GH-6422]: https://github.com/hashicorp/vagrant/issues/6422
[GH-6428]: https://github.com/hashicorp/vagrant/issues/6428
[GH-6445]: https://github.com/hashicorp/vagrant/issues/6445
[GH-6453]: https://github.com/hashicorp/vagrant/issues/6453
[GH-6474]: https://github.com/hashicorp/vagrant/issues/6474
[GH-6475]: https://github.com/hashicorp/vagrant/issues/6475
[GH-6502]: https://github.com/hashicorp/vagrant/issues/6502
[GH-6514]: https://github.com/hashicorp/vagrant/issues/6514
[GH-6516]: https://github.com/hashicorp/vagrant/issues/6516
[GH-6526]: https://github.com/hashicorp/vagrant/issues/6526
[GH-6534]: https://github.com/hashicorp/vagrant/issues/6534
[GH-6535]: https://github.com/hashicorp/vagrant/issues/6535
[GH-6540]: https://github.com/hashicorp/vagrant/issues/6540
[GH-6541]: https://github.com/hashicorp/vagrant/issues/6541
[GH-6542]: https://github.com/hashicorp/vagrant/issues/6542
[GH-6553]: https://github.com/hashicorp/vagrant/issues/6553
[GH-6554]: https://github.com/hashicorp/vagrant/issues/6554
[GH-6555]: https://github.com/hashicorp/vagrant/issues/6555
[GH-6556]: https://github.com/hashicorp/vagrant/issues/6556
[GH-6559]: https://github.com/hashicorp/vagrant/issues/6559
[GH-6561]: https://github.com/hashicorp/vagrant/issues/6561
[GH-6562]: https://github.com/hashicorp/vagrant/issues/6562
[GH-6563]: https://github.com/hashicorp/vagrant/issues/6563
[GH-6565]: https://github.com/hashicorp/vagrant/issues/6565
[GH-6566]: https://github.com/hashicorp/vagrant/issues/6566
[GH-6567]: https://github.com/hashicorp/vagrant/issues/6567
[GH-6568]: https://github.com/hashicorp/vagrant/issues/6568
[GH-6581]: https://github.com/hashicorp/vagrant/issues/6581
[GH-6583]: https://github.com/hashicorp/vagrant/issues/6583
[GH-6586]: https://github.com/hashicorp/vagrant/issues/6586
[GH-6588]: https://github.com/hashicorp/vagrant/issues/6588
[GH-6590]: https://github.com/hashicorp/vagrant/issues/6590
[GH-6602]: https://github.com/hashicorp/vagrant/issues/6602
[GH-6603]: https://github.com/hashicorp/vagrant/issues/6603
[GH-6608]: https://github.com/hashicorp/vagrant/issues/6608
[GH-6610]: https://github.com/hashicorp/vagrant/issues/6610
[GH-6619]: https://github.com/hashicorp/vagrant/issues/6619
[GH-6620]: https://github.com/hashicorp/vagrant/issues/6620
[GH-6624]: https://github.com/hashicorp/vagrant/issues/6624
[GH-6648]: https://github.com/hashicorp/vagrant/issues/6648
[GH-6650]: https://github.com/hashicorp/vagrant/issues/6650
[GH-6654]: https://github.com/hashicorp/vagrant/issues/6654
[GH-6660]: https://github.com/hashicorp/vagrant/issues/6660
[GH-6661]: https://github.com/hashicorp/vagrant/issues/6661
[GH-6662]: https://github.com/hashicorp/vagrant/issues/6662
[GH-6671]: https://github.com/hashicorp/vagrant/issues/6671
[GH-6690]: https://github.com/hashicorp/vagrant/issues/6690
[GH-6702]: https://github.com/hashicorp/vagrant/issues/6702
[GH-6709]: https://github.com/hashicorp/vagrant/issues/6709
[GH-6711]: https://github.com/hashicorp/vagrant/issues/6711
[GH-6713]: https://github.com/hashicorp/vagrant/issues/6713
[GH-6714]: https://github.com/hashicorp/vagrant/issues/6714
[GH-6717]: https://github.com/hashicorp/vagrant/issues/6717
[GH-6722]: https://github.com/hashicorp/vagrant/issues/6722
[GH-6726]: https://github.com/hashicorp/vagrant/issues/6726
[GH-6730]: https://github.com/hashicorp/vagrant/issues/6730
[GH-6731]: https://github.com/hashicorp/vagrant/issues/6731
[GH-6740]: https://github.com/hashicorp/vagrant/issues/6740
[GH-6742]: https://github.com/hashicorp/vagrant/issues/6742
[GH-6747]: https://github.com/hashicorp/vagrant/issues/6747
[GH-6749]: https://github.com/hashicorp/vagrant/issues/6749
[GH-6757]: https://github.com/hashicorp/vagrant/issues/6757
[GH-6760]: https://github.com/hashicorp/vagrant/issues/6760
[GH-6763]: https://github.com/hashicorp/vagrant/issues/6763
[GH-6766]: https://github.com/hashicorp/vagrant/issues/6766
[GH-6776]: https://github.com/hashicorp/vagrant/issues/6776
[GH-6787]: https://github.com/hashicorp/vagrant/issues/6787
[GH-6788]: https://github.com/hashicorp/vagrant/issues/6788
[GH-6793]: https://github.com/hashicorp/vagrant/issues/6793
[GH-6804]: https://github.com/hashicorp/vagrant/issues/6804
[GH-6805]: https://github.com/hashicorp/vagrant/issues/6805
[GH-6806]: https://github.com/hashicorp/vagrant/issues/6806
[GH-6825]: https://github.com/hashicorp/vagrant/issues/6825
[GH-6827]: https://github.com/hashicorp/vagrant/issues/6827
[GH-6836]: https://github.com/hashicorp/vagrant/issues/6836
[GH-6842]: https://github.com/hashicorp/vagrant/issues/6842
[GH-6843]: https://github.com/hashicorp/vagrant/issues/6843
[GH-6848]: https://github.com/hashicorp/vagrant/issues/6848
[GH-6867]: https://github.com/hashicorp/vagrant/issues/6867
[GH-6871]: https://github.com/hashicorp/vagrant/issues/6871
[GH-6876]: https://github.com/hashicorp/vagrant/issues/6876
[GH-6879]: https://github.com/hashicorp/vagrant/issues/6879
[GH-6892]: https://github.com/hashicorp/vagrant/issues/6892
[GH-6893]: https://github.com/hashicorp/vagrant/issues/6893
[GH-6898]: https://github.com/hashicorp/vagrant/issues/6898
[GH-6899]: https://github.com/hashicorp/vagrant/issues/6899
[GH-6906]: https://github.com/hashicorp/vagrant/issues/6906
[GH-6908]: https://github.com/hashicorp/vagrant/issues/6908
[GH-6909]: https://github.com/hashicorp/vagrant/issues/6909
[GH-6912]: https://github.com/hashicorp/vagrant/issues/6912
[GH-6915]: https://github.com/hashicorp/vagrant/issues/6915
[GH-6922]: https://github.com/hashicorp/vagrant/issues/6922
[Gh-6924]: https://github.com/hashicorp/vagrant/issues/6924
[GH-6929]: https://github.com/hashicorp/vagrant/issues/6929
[GH-6938]: https://github.com/hashicorp/vagrant/issues/6938
[GH-6960]: https://github.com/hashicorp/vagrant/issues/6960
[GH-6961]: https://github.com/hashicorp/vagrant/issues/6961
[GH-6962]: https://github.com/hashicorp/vagrant/issues/6962
[GH-6963]: https://github.com/hashicorp/vagrant/issues/6963
[GH-6968]: https://github.com/hashicorp/vagrant/issues/6968
[GH-6977]: https://github.com/hashicorp/vagrant/issues/6977
[GH-6979]: https://github.com/hashicorp/vagrant/issues/6979
[GH-6984]: https://github.com/hashicorp/vagrant/issues/6984
[GH-7001]: https://github.com/hashicorp/vagrant/issues/7001
[GH-7012]: https://github.com/hashicorp/vagrant/issues/7012
[GH-7035]: https://github.com/hashicorp/vagrant/issues/7035
[GH-7046]: https://github.com/hashicorp/vagrant/issues/7046
[GH-7050]: https://github.com/hashicorp/vagrant/issues/7050
[GH-7059]: https://github.com/hashicorp/vagrant/issues/7059
[GH-7063]: https://github.com/hashicorp/vagrant/issues/7063
[GH-7074]: https://github.com/hashicorp/vagrant/issues/7074
[GH-7085]: https://github.com/hashicorp/vagrant/issues/7085
[GH-7086]: https://github.com/hashicorp/vagrant/issues/7086
[GH-7090]: https://github.com/hashicorp/vagrant/issues/7090
[GH-7093]: https://github.com/hashicorp/vagrant/issues/7093
[GH-7098]: https://github.com/hashicorp/vagrant/issues/7098
[GH-7101]: https://github.com/hashicorp/vagrant/issues/7101
[GH-7108]: https://github.com/hashicorp/vagrant/issues/7108
[GH-7110]: https://github.com/hashicorp/vagrant/issues/7110
[GH-7118]: https://github.com/hashicorp/vagrant/issues/7118
[GH-7119]: https://github.com/hashicorp/vagrant/issues/7119
[GH-7120]: https://github.com/hashicorp/vagrant/issues/7120
[GH-7126]: https://github.com/hashicorp/vagrant/issues/7126
[GH-7153]: https://github.com/hashicorp/vagrant/issues/7153
[GH-7154]: https://github.com/hashicorp/vagrant/issues/7154
[GH-7155]: https://github.com/hashicorp/vagrant/issues/7155
[GH-7158]: https://github.com/hashicorp/vagrant/issues/7158
[GH-7159]: https://github.com/hashicorp/vagrant/issues/7159
[GH-7167]: https://github.com/hashicorp/vagrant/issues/7167
[GH-7181]: https://github.com/hashicorp/vagrant/issues/7181
[GH-7182]: https://github.com/hashicorp/vagrant/issues/7182
[GH-7184]: https://github.com/hashicorp/vagrant/issues/7184
[GH-7190]: https://github.com/hashicorp/vagrant/issues/7190
[GH-7195]: https://github.com/hashicorp/vagrant/issues/7195
[GH-7202]: https://github.com/hashicorp/vagrant/issues/7202
[GH-7206]: https://github.com/hashicorp/vagrant/issues/7206
[GH-7207]: https://github.com/hashicorp/vagrant/issues/7207
[GH-7219]: https://github.com/hashicorp/vagrant/issues/7219
[GH-7228]: https://github.com/hashicorp/vagrant/issues/7228
[GH-7234]: https://github.com/hashicorp/vagrant/issues/7234
[GH-7252]: https://github.com/hashicorp/vagrant/issues/7252
[GH-7254]: https://github.com/hashicorp/vagrant/issues/7254
[GH-7269]: https://github.com/hashicorp/vagrant/issues/7269
[GH-7270]: https://github.com/hashicorp/vagrant/issues/7270
[GH-7272]: https://github.com/hashicorp/vagrant/issues/7272
[GH-7275]: https://github.com/hashicorp/vagrant/issues/7275
[GH-7276]: https://github.com/hashicorp/vagrant/issues/7276
[GH-7277]: https://github.com/hashicorp/vagrant/issues/7277
[GH-7286]: https://github.com/hashicorp/vagrant/issues/7286
[GH-7287]: https://github.com/hashicorp/vagrant/issues/7287
[GH-7289]: https://github.com/hashicorp/vagrant/issues/7289
[GH-7290]: https://github.com/hashicorp/vagrant/issues/7290
[GH-7293]: https://github.com/hashicorp/vagrant/issues/7293
[GH-7295]: https://github.com/hashicorp/vagrant/issues/7295
[GH-7298]: https://github.com/hashicorp/vagrant/issues/7298
[GH-7327]: https://github.com/hashicorp/vagrant/issues/7327
[GH-7351]: https://github.com/hashicorp/vagrant/issues/7351
[GH-7352]: https://github.com/hashicorp/vagrant/issues/7352
[GH-7353]: https://github.com/hashicorp/vagrant/issues/7353
[GH-7354]: https://github.com/hashicorp/vagrant/issues/7354
[GH-7355]: https://github.com/hashicorp/vagrant/issues/7355
[GH-7356]: https://github.com/hashicorp/vagrant/issues/7356
[GH-7358]: https://github.com/hashicorp/vagrant/issues/7358
[GH-7363]: https://github.com/hashicorp/vagrant/issues/7363
[GH-7365]: https://github.com/hashicorp/vagrant/issues/7365
[GH-7369]: https://github.com/hashicorp/vagrant/issues/7369
[GH-7377]: https://github.com/hashicorp/vagrant/issues/7377
[GH-7379]: https://github.com/hashicorp/vagrant/issues/7379
[GH-7386]: https://github.com/hashicorp/vagrant/issues/7386
[GH-7387]: https://github.com/hashicorp/vagrant/issues/7387
[GH-7395]: https://github.com/hashicorp/vagrant/issues/7395
[GH-7398]: https://github.com/hashicorp/vagrant/issues/7398
[GH-7415]: https://github.com/hashicorp/vagrant/issues/7415
[GH-7417]: https://github.com/hashicorp/vagrant/issues/7417
[GH-7418]: https://github.com/hashicorp/vagrant/issues/7418
[GH-7419]: https://github.com/hashicorp/vagrant/issues/7419
[GH-7425]: https://github.com/hashicorp/vagrant/issues/7425
[GH-7427]: https://github.com/hashicorp/vagrant/issues/7427
[GH-7428]: https://github.com/hashicorp/vagrant/issues/7428
[GH-7441]: https://github.com/hashicorp/vagrant/issues/7441
[GH-7447]: https://github.com/hashicorp/vagrant/issues/7447
[GH-7453]: https://github.com/hashicorp/vagrant/issues/7453
[GH-7454]: https://github.com/hashicorp/vagrant/issues/7454
[GH-7456]: https://github.com/hashicorp/vagrant/issues/7456
[GH-7460]: https://github.com/hashicorp/vagrant/issues/7460
[GH-7465]: https://github.com/hashicorp/vagrant/issues/7465
[GH-7466]: https://github.com/hashicorp/vagrant/issues/7466
[GH-7467]: https://github.com/hashicorp/vagrant/issues/7467
[GH-7474]: https://github.com/hashicorp/vagrant/issues/7474
[GH-7480]: https://github.com/hashicorp/vagrant/issues/7480
[GH-7481]: https://github.com/hashicorp/vagrant/issues/7481
[GH-7482]: https://github.com/hashicorp/vagrant/issues/7482
[GH-7484]: https://github.com/hashicorp/vagrant/issues/7484
[GH-7487]: https://github.com/hashicorp/vagrant/issues/7487
[GH-7488]: https://github.com/hashicorp/vagrant/issues/7488
[GH-7491]: https://github.com/hashicorp/vagrant/issues/7491
[GH-7492]: https://github.com/hashicorp/vagrant/issues/7492
[GH-7493]: https://github.com/hashicorp/vagrant/issues/7493
[GH-7496]: https://github.com/hashicorp/vagrant/issues/7496
[GH-7499]: https://github.com/hashicorp/vagrant/issues/7499
[GH-7505]: https://github.com/hashicorp/vagrant/issues/7505
[GH-7516]: https://github.com/hashicorp/vagrant/issues/7516
[GH-7519]: https://github.com/hashicorp/vagrant/issues/7519
[GH-7533]: https://github.com/hashicorp/vagrant/issues/7533
[GH-7536]: https://github.com/hashicorp/vagrant/issues/7536
[GH-7537]: https://github.com/hashicorp/vagrant/issues/7537
[GH-7539]: https://github.com/hashicorp/vagrant/issues/7539
[GH-7540]: https://github.com/hashicorp/vagrant/issues/7540
[GH-7550]: https://github.com/hashicorp/vagrant/issues/7550
[GH-7574]: https://github.com/hashicorp/vagrant/issues/7574
[GH-7579]: https://github.com/hashicorp/vagrant/issues/7579
[GH-7580]: https://github.com/hashicorp/vagrant/issues/7580
[GH-7587]: https://github.com/hashicorp/vagrant/issues/7587
[GH-7598]: https://github.com/hashicorp/vagrant/issues/7598
[GH-7610]: https://github.com/hashicorp/vagrant/issues/7610
[GH-7611]: https://github.com/hashicorp/vagrant/issues/7611
[GH-7613]: https://github.com/hashicorp/vagrant/issues/7613
[GH-7616]: https://github.com/hashicorp/vagrant/issues/7616
[GH-7621]: https://github.com/hashicorp/vagrant/issues/7621
[GH-7623]: https://github.com/hashicorp/vagrant/issues/7623
[GH-7625]: https://github.com/hashicorp/vagrant/issues/7625
[GH-7629]: https://github.com/hashicorp/vagrant/issues/7629
[GH-7630]: https://github.com/hashicorp/vagrant/issues/7630
[GH-7632]: https://github.com/hashicorp/vagrant/issues/7632
[GH-7647]: https://github.com/hashicorp/vagrant/issues/7647
[GH-7651]: https://github.com/hashicorp/vagrant/issues/7651
[GH-7662]: https://github.com/hashicorp/vagrant/issues/7662
[GH-7668]: https://github.com/hashicorp/vagrant/issues/7668
[GH-7675]: https://github.com/hashicorp/vagrant/issues/7675
[GH-7676]: https://github.com/hashicorp/vagrant/issues/7676
[GH-7688]: https://github.com/hashicorp/vagrant/issues/7688
[GH-7693]: https://github.com/hashicorp/vagrant/issues/7693
[GH-7698]: https://github.com/hashicorp/vagrant/issues/7698
[GH-7699]: https://github.com/hashicorp/vagrant/issues/7699
[GH-7703]: https://github.com/hashicorp/vagrant/issues/7703
[GH-7705]: https://github.com/hashicorp/vagrant/issues/7705
[GH-7706]: https://github.com/hashicorp/vagrant/issues/7706
[GH-7712]: https://github.com/hashicorp/vagrant/issues/7712
[GH-7720]: https://github.com/hashicorp/vagrant/issues/7720
[GH-7723]: https://github.com/hashicorp/vagrant/issues/7723
[GH-7725]: https://github.com/hashicorp/vagrant/issues/7725
[GH-7726]: https://github.com/hashicorp/vagrant/issues/7726
[GH-7730]: https://github.com/hashicorp/vagrant/issues/7730
[GH-7735]: https://github.com/hashicorp/vagrant/issues/7735
[GH-7738]: https://github.com/hashicorp/vagrant/issues/7738
[GH-7739]: https://github.com/hashicorp/vagrant/issues/7739
[GH-7740]: https://github.com/hashicorp/vagrant/issues/7740
[GH-7751]: https://github.com/hashicorp/vagrant/issues/7751
[GH-7752]: https://github.com/hashicorp/vagrant/issues/7752
[GH-7756]: https://github.com/hashicorp/vagrant/issues/7756
[GH-7778]: https://github.com/hashicorp/vagrant/issues/7778
[GH-7793]: https://github.com/hashicorp/vagrant/issues/7793
[GH-7794]: https://github.com/hashicorp/vagrant/issues/7794
[GH-7797]: https://github.com/hashicorp/vagrant/issues/7797
[GH-7805]: https://github.com/hashicorp/vagrant/issues/7805
[GH-7808]: https://github.com/hashicorp/vagrant/issues/7808
[GH-7810]: https://github.com/hashicorp/vagrant/issues/7810
[GH-7813]: https://github.com/hashicorp/vagrant/issues/7813
[GH-7818]: https://github.com/hashicorp/vagrant/issues/7818
[GH-7827]: https://github.com/hashicorp/vagrant/issues/7827
[GH-7831]: https://github.com/hashicorp/vagrant/issues/7831
[GH-7840]: https://github.com/hashicorp/vagrant/issues/7840
[GH-7844]: https://github.com/hashicorp/vagrant/issues/7844
[GH-7854]: https://github.com/hashicorp/vagrant/issues/7854
[GH-7857]: https://github.com/hashicorp/vagrant/issues/7857
[GH-7858]: https://github.com/hashicorp/vagrant/issues/7858
[GH-7859]: https://github.com/hashicorp/vagrant/issues/7859
[GH-7865]: https://github.com/hashicorp/vagrant/issues/7865
[GH-7866]: https://github.com/hashicorp/vagrant/issues/7866
[GH-7867]: https://github.com/hashicorp/vagrant/issues/7867
[GH-7873]: https://github.com/hashicorp/vagrant/issues/7873
[GH-7874]: https://github.com/hashicorp/vagrant/issues/7874
[GH-7881]: https://github.com/hashicorp/vagrant/issues/7881
[GH-7887]: https://github.com/hashicorp/vagrant/issues/7887
[GH-7889]: https://github.com/hashicorp/vagrant/issues/7889
[GH-7895]: https://github.com/hashicorp/vagrant/issues/7895
[GH-7898]: https://github.com/hashicorp/vagrant/issues/7898
[GH-7901]: https://github.com/hashicorp/vagrant/issues/7901
[GH-7907]: https://github.com/hashicorp/vagrant/issues/7907
[GH-7910]: https://github.com/hashicorp/vagrant/issues/7910
[GH-7918]: https://github.com/hashicorp/vagrant/issues/7918
[GH-7921]: https://github.com/hashicorp/vagrant/issues/7921
[GH-7922]: https://github.com/hashicorp/vagrant/issues/7922
[GH-7926]: https://github.com/hashicorp/vagrant/issues/7926
[GH-7928]: https://github.com/hashicorp/vagrant/issues/7928
[GH-7929]: https://github.com/hashicorp/vagrant/issues/7929
[GH-7931]: https://github.com/hashicorp/vagrant/issues/7931
[GH-7938]: https://github.com/hashicorp/vagrant/issues/7938
[GH-7947]: https://github.com/hashicorp/vagrant/issues/7947
[GH-7956]: https://github.com/hashicorp/vagrant/issues/7956
[GH-7960]: https://github.com/hashicorp/vagrant/issues/7960
[GH-7967]: https://github.com/hashicorp/vagrant/issues/7967
[GH-7976]: https://github.com/hashicorp/vagrant/issues/7976
[GH-7978]: https://github.com/hashicorp/vagrant/issues/7978
[GH-7980]: https://github.com/hashicorp/vagrant/issues/7980
[GH-7981]: https://github.com/hashicorp/vagrant/issues/7981
[GH-7983]: https://github.com/hashicorp/vagrant/issues/7983
[GH-7985]: https://github.com/hashicorp/vagrant/issues/7985
[GH-7986]: https://github.com/hashicorp/vagrant/issues/7986
[GH-7988]: https://github.com/hashicorp/vagrant/issues/7988
[GH-7989]: https://github.com/hashicorp/vagrant/issues/7989
[GH-7994]: https://github.com/hashicorp/vagrant/issues/7994
[GH-8000]: https://github.com/hashicorp/vagrant/issues/8000
[GH-8011]: https://github.com/hashicorp/vagrant/issues/8011
[GH-8016]: https://github.com/hashicorp/vagrant/issues/8016
[GH-8028]: https://github.com/hashicorp/vagrant/issues/8028
[GH-8031]: https://github.com/hashicorp/vagrant/issues/8031
[GH-8051]: https://github.com/hashicorp/vagrant/issues/8051
[GH-8052]: https://github.com/hashicorp/vagrant/issues/8052
[GH-8064]: https://github.com/hashicorp/vagrant/issues/8064
[GH-8066]: https://github.com/hashicorp/vagrant/issues/8066
[GH-8068]: https://github.com/hashicorp/vagrant/issues/8068
[GH-8073]: https://github.com/hashicorp/vagrant/issues/8073
[GH-8086]: https://github.com/hashicorp/vagrant/issues/8086
[GH-8087]: https://github.com/hashicorp/vagrant/issues/8087
[GH-8089]: https://github.com/hashicorp/vagrant/issues/8089
[GH-8090]: https://github.com/hashicorp/vagrant/issues/8090
[GH-8092]: https://github.com/hashicorp/vagrant/issues/8092
[GH-8094]: https://github.com/hashicorp/vagrant/issues/8094
[GH-8099]: https://github.com/hashicorp/vagrant/issues/8099
[GH-8102]: https://github.com/hashicorp/vagrant/issues/8102
[GH-8108]: https://github.com/hashicorp/vagrant/issues/8108
[GH-8117]: https://github.com/hashicorp/vagrant/issues/8117
[GH-8119]: https://github.com/hashicorp/vagrant/issues/8119
[GH-8122]: https://github.com/hashicorp/vagrant/issues/8122
[GH-8125]: https://github.com/hashicorp/vagrant/issues/8125
[GH-8126]: https://github.com/hashicorp/vagrant/issues/8126
[GH-8147]: https://github.com/hashicorp/vagrant/issues/8147
[GH-8148]: https://github.com/hashicorp/vagrant/issues/8148
[GH-8151]: https://github.com/hashicorp/vagrant/issues/8151
[GH-8159]: https://github.com/hashicorp/vagrant/issues/8159
[GH-8165]: https://github.com/hashicorp/vagrant/issues/8165
[GH-8170]: https://github.com/hashicorp/vagrant/issues/8170
[GH-8171]: https://github.com/hashicorp/vagrant/issues/8171
[GH-8190]: https://github.com/hashicorp/vagrant/issues/8190
[GH-8191]: https://github.com/hashicorp/vagrant/issues/8191
[GH-8192]: https://github.com/hashicorp/vagrant/issues/8192
[GH-8194]: https://github.com/hashicorp/vagrant/issues/8194
[GH-8196]: https://github.com/hashicorp/vagrant/issues/8196
[GH-8198]: https://github.com/hashicorp/vagrant/issues/8198
[GH-8207]: https://github.com/hashicorp/vagrant/issues/8207
[GH-8210]: https://github.com/hashicorp/vagrant/issues/8210
[GH-8212]: https://github.com/hashicorp/vagrant/issues/8212
[GH-8248]: https://github.com/hashicorp/vagrant/issues/8248
[GH-8252]: https://github.com/hashicorp/vagrant/issues/8252
[GH-8253]: https://github.com/hashicorp/vagrant/issues/8253
[GH-8259]: https://github.com/hashicorp/vagrant/issues/8259
[GH-8264]: https://github.com/hashicorp/vagrant/issues/8264
[GH-8270]: https://github.com/hashicorp/vagrant/issues/8270
[GH-8273]: https://github.com/hashicorp/vagrant/issues/8273
[GH-8282]: https://github.com/hashicorp/vagrant/issues/8282
[GH-8283]: https://github.com/hashicorp/vagrant/issues/8283
[GH-8288]: https://github.com/hashicorp/vagrant/issues/8288
[GH-8291]: https://github.com/hashicorp/vagrant/issues/8291
[GH-8310]: https://github.com/hashicorp/vagrant/issues/8310
[GH-8325]: https://github.com/hashicorp/vagrant/issues/8325
[GH-8327]: https://github.com/hashicorp/vagrant/issues/8327
[GH-8329]: https://github.com/hashicorp/vagrant/issues/8329
[GH-8334]: https://github.com/hashicorp/vagrant/issues/8334
[GH-8336]: https://github.com/hashicorp/vagrant/issues/8336
[GH-8337]: https://github.com/hashicorp/vagrant/issues/8337
[GH-8341]: https://github.com/hashicorp/vagrant/issues/8341
[GH-8350]: https://github.com/hashicorp/vagrant/issues/8350
[GH-8366]: https://github.com/hashicorp/vagrant/issues/8366
[GH-8378]: https://github.com/hashicorp/vagrant/issues/8378
[GH-8379]: https://github.com/hashicorp/vagrant/issues/8379
[GH-8380]: https://github.com/hashicorp/vagrant/issues/8380
[GH-8385]: https://github.com/hashicorp/vagrant/issues/8385
[GH-8389]: https://github.com/hashicorp/vagrant/issues/8389
[GH-8390]: https://github.com/hashicorp/vagrant/issues/8390
[GH-8392]: https://github.com/hashicorp/vagrant/issues/8392
[GH-8393]: https://github.com/hashicorp/vagrant/issues/8393
[GH-8395]: https://github.com/hashicorp/vagrant/issues/8395
[GH-8399]: https://github.com/hashicorp/vagrant/issues/8399
[GH-8400]: https://github.com/hashicorp/vagrant/issues/8400
[GH-8401]: https://github.com/hashicorp/vagrant/issues/8401
[GH-8404]: https://github.com/hashicorp/vagrant/issues/8404
[GH-8406]: https://github.com/hashicorp/vagrant/issues/8406
[GH-8407]: https://github.com/hashicorp/vagrant/issues/8407
[GH-8410]: https://github.com/hashicorp/vagrant/issues/8410
[GH-8414]: https://github.com/hashicorp/vagrant/issues/8414
[GH-8422]: https://github.com/hashicorp/vagrant/issues/8422
[GH-8423]: https://github.com/hashicorp/vagrant/issues/8423
[GH-8428]: https://github.com/hashicorp/vagrant/issues/8428
[GH-8433]: https://github.com/hashicorp/vagrant/issues/8433
[GH-8437]: https://github.com/hashicorp/vagrant/issues/8437
[GH-8442]: https://github.com/hashicorp/vagrant/issues/8442
[GH-8443]: https://github.com/hashicorp/vagrant/issues/8443
[GH-8444]: https://github.com/hashicorp/vagrant/issues/8444
[GH-8448]: https://github.com/hashicorp/vagrant/issues/8448
[GH-8456]: https://github.com/hashicorp/vagrant/issues/8456
[GH-8467]: https://github.com/hashicorp/vagrant/issues/8467
[GH-8472]: https://github.com/hashicorp/vagrant/issues/8472
[GH-8485]: https://github.com/hashicorp/vagrant/issues/8485
[GH-8495]: https://github.com/hashicorp/vagrant/issues/8495
[GH-8497]: https://github.com/hashicorp/vagrant/issues/8497
[GH-8498]: https://github.com/hashicorp/vagrant/issues/8498
[GH-8503]: https://github.com/hashicorp/vagrant/issues/8503
[GH-8504]: https://github.com/hashicorp/vagrant/issues/8504
[GH-8506]: https://github.com/hashicorp/vagrant/issues/8506
[GH-8508]: https://github.com/hashicorp/vagrant/issues/8508
[GH-8510]: https://github.com/hashicorp/vagrant/issues/8510
[GH-8517]: https://github.com/hashicorp/vagrant/issues/8517
[GH-8520]: https://github.com/hashicorp/vagrant/issues/8520
[GH-8526]: https://github.com/hashicorp/vagrant/issues/8526
[GH-8529]: https://github.com/hashicorp/vagrant/issues/8529
[GH-8531]: https://github.com/hashicorp/vagrant/issues/8531
[GH-8535]: https://github.com/hashicorp/vagrant/issues/8535
[GH-8539]: https://github.com/hashicorp/vagrant/issues/8539
[GH-8548]: https://github.com/hashicorp/vagrant/issues/8548
[GH-8552]: https://github.com/hashicorp/vagrant/issues/8552
[GH-8553]: https://github.com/hashicorp/vagrant/issues/8553
[GH-8558]: https://github.com/hashicorp/vagrant/issues/8558
[GH-8565]: https://github.com/hashicorp/vagrant/issues/8565
[GH-8566]: https://github.com/hashicorp/vagrant/issues/8566
[GH-8567]: https://github.com/hashicorp/vagrant/issues/8567
[GH-8568]: https://github.com/hashicorp/vagrant/issues/8568
[GH-8570]: https://github.com/hashicorp/vagrant/issues/8570
[GH-8571]: https://github.com/hashicorp/vagrant/issues/8571
[GH-8575]: https://github.com/hashicorp/vagrant/issues/8575
[GH-8576]: https://github.com/hashicorp/vagrant/issues/8576
[GH-8577]: https://github.com/hashicorp/vagrant/issues/8577
[GH-8582]: https://github.com/hashicorp/vagrant/issues/8582
[GH-8588]: https://github.com/hashicorp/vagrant/issues/8588
[GH-8597]: https://github.com/hashicorp/vagrant/issues/8597
[GH-8618]: https://github.com/hashicorp/vagrant/issues/8618
[GH-8659]: https://github.com/hashicorp/vagrant/issues/8659
[GH-8660]: https://github.com/hashicorp/vagrant/issues/8660
[GH-8661]: https://github.com/hashicorp/vagrant/issues/8661
[GH-8664]: https://github.com/hashicorp/vagrant/issues/8664
[GH-8666]: https://github.com/hashicorp/vagrant/issues/8666
[GH-8676]: https://github.com/hashicorp/vagrant/issues/8676
[GH-8677]: https://github.com/hashicorp/vagrant/issues/8677
[GH-8678]: https://github.com/hashicorp/vagrant/issues/8678
[GH-8680]: https://github.com/hashicorp/vagrant/issues/8680
[GH-8682]: https://github.com/hashicorp/vagrant/issues/8682
[GH-8685]: https://github.com/hashicorp/vagrant/issues/8685
[GH-8692]: https://github.com/hashicorp/vagrant/issues/8692
[GH-8693]: https://github.com/hashicorp/vagrant/issues/8693
[GH-8695]: https://github.com/hashicorp/vagrant/issues/8695
[GH-8706]: https://github.com/hashicorp/vagrant/issues/8706
[GH-8707]: https://github.com/hashicorp/vagrant/issues/8707
[GH-8722]: https://github.com/hashicorp/vagrant/issues/8722
[GH-8725]: https://github.com/hashicorp/vagrant/issues/8725
[GH-8729]: https://github.com/hashicorp/vagrant/issues/8729
[GH-8730]: https://github.com/hashicorp/vagrant/issues/8730
[GH-8740]: https://github.com/hashicorp/vagrant/issues/8740
[GH-8746]: https://github.com/hashicorp/vagrant/issues/8746
[GH-8749]: https://github.com/hashicorp/vagrant/issues/8749
[GH-8756]: https://github.com/hashicorp/vagrant/issues/8756
[GH-8758]: https://github.com/hashicorp/vagrant/issues/8758
[GH-8759]: https://github.com/hashicorp/vagrant/issues/8759
[GH-8760]: https://github.com/hashicorp/vagrant/issues/8760
[GH-8762]: https://github.com/hashicorp/vagrant/issues/8762
[GH-8767]: https://github.com/hashicorp/vagrant/issues/8767
[GH-8775]: https://github.com/hashicorp/vagrant/issues/8775
[GH-8781]: https://github.com/hashicorp/vagrant/issues/8781
[GH-8790]: https://github.com/hashicorp/vagrant/issues/8790
[GH-8797]: https://github.com/hashicorp/vagrant/issues/8797
[GH-8806]: https://github.com/hashicorp/vagrant/issues/8806
[GH-8809]: https://github.com/hashicorp/vagrant/issues/8809
[GH-8819]: https://github.com/hashicorp/vagrant/issues/8819
[GH-8820]: https://github.com/hashicorp/vagrant/issues/8820
[GH-8821]: https://github.com/hashicorp/vagrant/issues/8821
[GH-8822]: https://github.com/hashicorp/vagrant/issues/8822
[GH-8828]: https://github.com/hashicorp/vagrant/issues/8828
[GH-8831]: https://github.com/hashicorp/vagrant/issues/8831
[GH-8837]: https://github.com/hashicorp/vagrant/issues/8837
[GH-8838]: https://github.com/hashicorp/vagrant/issues/8838
[GH-8839]: https://github.com/hashicorp/vagrant/issues/8839
[GH-8840]: https://github.com/hashicorp/vagrant/issues/8840
[GH-8842]: https://github.com/hashicorp/vagrant/issues/8842
[GH-8850]: https://github.com/hashicorp/vagrant/issues/8850
[GH-8863]: https://github.com/hashicorp/vagrant/issues/8863
[GH-8864]: https://github.com/hashicorp/vagrant/issues/8864
[GH-8871]: https://github.com/hashicorp/vagrant/issues/8871
[GH-8874]: https://github.com/hashicorp/vagrant/issues/8874
[GH-8875]: https://github.com/hashicorp/vagrant/issues/8875
[GH-8876]: https://github.com/hashicorp/vagrant/issues/8876
[GH-8880]: https://github.com/hashicorp/vagrant/issues/8880
[GH-8889]: https://github.com/hashicorp/vagrant/issues/8889
[GH-8895]: https://github.com/hashicorp/vagrant/issues/8895
[GH-8901]: https://github.com/hashicorp/vagrant/issues/8901
[GH-8902]: https://github.com/hashicorp/vagrant/issues/8902
[GH-8910]: https://github.com/hashicorp/vagrant/issues/8910
[GH-8911]: https://github.com/hashicorp/vagrant/issues/8911
[GH-8912]: https://github.com/hashicorp/vagrant/issues/8912
[GH-8914]: https://github.com/hashicorp/vagrant/issues/8914
[GH-8915]: https://github.com/hashicorp/vagrant/issues/8915
[GH-8918]: https://github.com/hashicorp/vagrant/issues/8918
[GH-8921]: https://github.com/hashicorp/vagrant/issues/8921
[GH-8924]: https://github.com/hashicorp/vagrant/issues/8924
[GH-8926]: https://github.com/hashicorp/vagrant/issues/8926
[GH-8927]: https://github.com/hashicorp/vagrant/issues/8927
[GH-8935]: https://github.com/hashicorp/vagrant/issues/8935
[GH-8938]: https://github.com/hashicorp/vagrant/issues/8938
[GH-8939]: https://github.com/hashicorp/vagrant/issues/8939
[GH-8945]: https://github.com/hashicorp/vagrant/issues/8945
[GH-8950]: https://github.com/hashicorp/vagrant/issues/8950
[GH-8951]: https://github.com/hashicorp/vagrant/issues/8951
[GH-8955]: https://github.com/hashicorp/vagrant/issues/8955
[GH-8962]: https://github.com/hashicorp/vagrant/issues/8962
[GH-8972]: https://github.com/hashicorp/vagrant/issues/8972
[GH-8983]: https://github.com/hashicorp/vagrant/issues/8983
[GH-8992]: https://github.com/hashicorp/vagrant/issues/8992
[GH-8995]: https://github.com/hashicorp/vagrant/issues/8995
[GH-8997]: https://github.com/hashicorp/vagrant/issues/8997
[GH-9000]: https://github.com/hashicorp/vagrant/issues/9000
[GH-9012]: https://github.com/hashicorp/vagrant/issues/9012
[GH-9014]: https://github.com/hashicorp/vagrant/issues/9014
[GH-9029]: https://github.com/hashicorp/vagrant/issues/9029
[GH-9034]: https://github.com/hashicorp/vagrant/issues/9034
[GH-9054]: https://github.com/hashicorp/vagrant/issues/9054
[GH-9065]: https://github.com/hashicorp/vagrant/issues/9065
[GH-9100]: https://github.com/hashicorp/vagrant/issues/9100
[GH-9102]: https://github.com/hashicorp/vagrant/issues/9102
[GH-9105]: https://github.com/hashicorp/vagrant/issues/9105
[GH-9107]: https://github.com/hashicorp/vagrant/issues/9107
[GH-9112]: https://github.com/hashicorp/vagrant/issues/9112
[GH-9127]: https://github.com/hashicorp/vagrant/issues/9127
[GH-9131]: https://github.com/hashicorp/vagrant/issues/9131
[GH-9135]: https://github.com/hashicorp/vagrant/issues/9135
[GH-9145]: https://github.com/hashicorp/vagrant/issues/9145
[GH-9173]: https://github.com/hashicorp/vagrant/issues/9173
[GH-9183]: https://github.com/hashicorp/vagrant/issues/9183
[GH-9202]: https://github.com/hashicorp/vagrant/issues/9202
[GH-9205]: https://github.com/hashicorp/vagrant/issues/9205
[GH-9212]: https://github.com/hashicorp/vagrant/issues/9212
[GH-9237]: https://github.com/hashicorp/vagrant/issues/9237
[GH-9245]: https://github.com/hashicorp/vagrant/issues/9245
[GH-9251]: https://github.com/hashicorp/vagrant/issues/9251
[GH-9252]: https://github.com/hashicorp/vagrant/issues/9252
[GH-9255]: https://github.com/hashicorp/vagrant/issues/9255
[GH-9261]: https://github.com/hashicorp/vagrant/issues/9261
[GH-9265]: https://github.com/hashicorp/vagrant/issues/9265
[GH-9269]: https://github.com/hashicorp/vagrant/issues/9269
[GH-9274]: https://github.com/hashicorp/vagrant/issues/9274
[GH-9275]: https://github.com/hashicorp/vagrant/issues/9275
[GH-9276]: https://github.com/hashicorp/vagrant/issues/9276
[GH-9295]: https://github.com/hashicorp/vagrant/issues/9295
[GH-9300]: https://github.com/hashicorp/vagrant/issues/9300
[GH-9302]: https://github.com/hashicorp/vagrant/issues/9302
[GH-9307]: https://github.com/hashicorp/vagrant/issues/9307
[GH-9315]: https://github.com/hashicorp/vagrant/issues/9315
[GH-9330]: https://github.com/hashicorp/vagrant/issues/9330
[GH-9338]: https://github.com/hashicorp/vagrant/issues/9338
[GH-9341]: https://github.com/hashicorp/vagrant/issues/9341
[GH-9344]: https://github.com/hashicorp/vagrant/issues/9344
[GH-9347]: https://github.com/hashicorp/vagrant/issues/9347
[GH-9351]: https://github.com/hashicorp/vagrant/issues/9351
[GH-9354]: https://github.com/hashicorp/vagrant/issues/9354
[GH-9363]: https://github.com/hashicorp/vagrant/issues/9363
[GH-9365]: https://github.com/hashicorp/vagrant/issues/9365
[GH-9366]: https://github.com/hashicorp/vagrant/issues/9366
[GH-9367]: https://github.com/hashicorp/vagrant/issues/9367
[GH-9369]: https://github.com/hashicorp/vagrant/issues/9369
[GH-9380]: https://github.com/hashicorp/vagrant/issues/9380
[GH-9389]: https://github.com/hashicorp/vagrant/issues/9389
[GH-9394]: https://github.com/hashicorp/vagrant/issues/9394
[GH-9398]: https://github.com/hashicorp/vagrant/issues/9398
[GH-9400]: https://github.com/hashicorp/vagrant/issues/9400
[GH-9404]: https://github.com/hashicorp/vagrant/issues/9404
[GH-9405]: https://github.com/hashicorp/vagrant/issues/9405
[GH-9420]: https://github.com/hashicorp/vagrant/issues/9420
[GH-9431]: https://github.com/hashicorp/vagrant/issues/9431
[GH-9432]: https://github.com/hashicorp/vagrant/issues/9432
[GH-9456]: https://github.com/hashicorp/vagrant/issues/9456
[GH-9459]: https://github.com/hashicorp/vagrant/issues/9459
[GH-9462]: https://github.com/hashicorp/vagrant/issues/9462
[GH-9470]: https://github.com/hashicorp/vagrant/issues/9470
[GH-9472]: https://github.com/hashicorp/vagrant/issues/9472
[GH-9490]: https://github.com/hashicorp/vagrant/issues/9490
[GH-9499]: https://github.com/hashicorp/vagrant/issues/9499
[GH-9502]: https://github.com/hashicorp/vagrant/issues/9502
[GH-9503]: https://github.com/hashicorp/vagrant/issues/9503
[GH-9504]: https://github.com/hashicorp/vagrant/issues/9504
[GH-9518]: https://github.com/hashicorp/vagrant/issues/9518
[GH-9525]: https://github.com/hashicorp/vagrant/issues/9525
[GH-9528]: https://github.com/hashicorp/vagrant/issues/9528
[GH-9578]: https://github.com/hashicorp/vagrant/issues/9578
[GH-9600]: https://github.com/hashicorp/vagrant/issues/9600
[GH-9639]: https://github.com/hashicorp/vagrant/issues/9639
[GH-9644]: https://github.com/hashicorp/vagrant/issues/9644
[GH-9645]: https://github.com/hashicorp/vagrant/issues/9645
[GH-9646]: https://github.com/hashicorp/vagrant/issues/9646
[GH-9654]: https://github.com/hashicorp/vagrant/issues/9654
[GH-9659]: https://github.com/hashicorp/vagrant/issues/9659
[GH-9669]: https://github.com/hashicorp/vagrant/issues/9669
[GH-9670]: https://github.com/hashicorp/vagrant/issues/9670
[GH-9673]: https://github.com/hashicorp/vagrant/issues/9673
[GH-9674]: https://github.com/hashicorp/vagrant/issues/9674
[GH-9676]: https://github.com/hashicorp/vagrant/issues/9676
[GH-9685]: https://github.com/hashicorp/vagrant/issues/9685
[GH-9690]: https://github.com/hashicorp/vagrant/issues/9690
[GH-9692]: https://github.com/hashicorp/vagrant/issues/9692
[GH-9696]: https://github.com/hashicorp/vagrant/issues/9696
[GH-9705]: https://github.com/hashicorp/vagrant/issues/9705
[GH-9713]: https://github.com/hashicorp/vagrant/issues/9713
[GH-9720]: https://github.com/hashicorp/vagrant/issues/9720
[GH-9729]: https://github.com/hashicorp/vagrant/issues/9729
[GH-9730]: https://github.com/hashicorp/vagrant/issues/9730
[GH-9734]: https://github.com/hashicorp/vagrant/issues/9734
[GH-9735]: https://github.com/hashicorp/vagrant/issues/9735
[GH-9737]: https://github.com/hashicorp/vagrant/issues/9737
[GH-9738]: https://github.com/hashicorp/vagrant/issues/9738
[GH-9739]: https://github.com/hashicorp/vagrant/issues/9739
[GH-9746]: https://github.com/hashicorp/vagrant/issues/9746
[GH-9747]: https://github.com/hashicorp/vagrant/issues/9747
[GH-9758]: https://github.com/hashicorp/vagrant/issues/9758
[GH-9759]: https://github.com/hashicorp/vagrant/issues/9759
[GH-9760]: https://github.com/hashicorp/vagrant/issues/9760
[GH-9761]: https://github.com/hashicorp/vagrant/issues/9761
[GH-9766]: https://github.com/hashicorp/vagrant/issues/9766
[GH-9769]: https://github.com/hashicorp/vagrant/issues/9769
[GH-9781]: https://github.com/hashicorp/vagrant/issues/9781
[GH-9784]: https://github.com/hashicorp/vagrant/issues/9784
[GH-9785]: https://github.com/hashicorp/vagrant/issues/9785
[GH-9796]: https://github.com/hashicorp/vagrant/issues/9796
[GH-9799]: https://github.com/hashicorp/vagrant/issues/9799
[GH-9800]: https://github.com/hashicorp/vagrant/issues/9800
[GH-9808]: https://github.com/hashicorp/vagrant/issues/9808
[GH-9811]: https://github.com/hashicorp/vagrant/issues/9811
[GH-9824]: https://github.com/hashicorp/vagrant/issues/9824
[GH-9829]: https://github.com/hashicorp/vagrant/issues/9829
[GH-9833]: https://github.com/hashicorp/vagrant/issues/9833
[GH-9855]: https://github.com/hashicorp/vagrant/issues/9855
[GH-9856]: https://github.com/hashicorp/vagrant/issues/9856
[GH-9867]: https://github.com/hashicorp/vagrant/issues/9867
[GH-9872]: https://github.com/hashicorp/vagrant/issues/9872
[GH-9878]: https://github.com/hashicorp/vagrant/issues/9878
[GH-9879]: https://github.com/hashicorp/vagrant/issues/9879
[GH-9889]: https://github.com/hashicorp/vagrant/issues/9889
[GH-9900]: https://github.com/hashicorp/vagrant/issues/9900
[GH-9916]: https://github.com/hashicorp/vagrant/issues/9916
[GH-9917]: https://github.com/hashicorp/vagrant/issues/9917
[GH-9923]: https://github.com/hashicorp/vagrant/issues/9923
[GH-9926]: https://github.com/hashicorp/vagrant/issues/9926
[GH-9932]: https://github.com/hashicorp/vagrant/issues/9932
[GH-9936]: https://github.com/hashicorp/vagrant/issues/9936
[GH-9943]: https://github.com/hashicorp/vagrant/issues/9943
[GH-9944]: https://github.com/hashicorp/vagrant/issues/9944
[GH-9952]: https://github.com/hashicorp/vagrant/issues/9952
[GH-9966]: https://github.com/hashicorp/vagrant/issues/9966
[GH-9968]: https://github.com/hashicorp/vagrant/issues/9968
[GH-9976]: https://github.com/hashicorp/vagrant/issues/9976
[GH-9987]: https://github.com/hashicorp/vagrant/issues/9987
[GH-9998]: https://github.com/hashicorp/vagrant/issues/9998
[GH-9999]: https://github.com/hashicorp/vagrant/issues/9999
[GH-10000]: https://github.com/hashicorp/vagrant/issues/10000
[GH-10001]: https://github.com/hashicorp/vagrant/issues/10001
[GH-10005]: https://github.com/hashicorp/vagrant/issues/10005
[GH-10012]: https://github.com/hashicorp/vagrant/issues/10012
[GH-10017]: https://github.com/hashicorp/vagrant/issues/10017
[GH-10030]: https://github.com/hashicorp/vagrant/issues/10030
[GH-10037]: https://github.com/hashicorp/vagrant/issues/10037
[GH-10041]: https://github.com/hashicorp/vagrant/issues/10041
[GH-10043]: https://github.com/hashicorp/vagrant/issues/10043
[GH-10063]: https://github.com/hashicorp/vagrant/issues/10063
[GH-10066]: https://github.com/hashicorp/vagrant/issues/10066
[GH-10076]: https://github.com/hashicorp/vagrant/issues/10076
[GH-10077]: https://github.com/hashicorp/vagrant/issues/10077
[GH-10078]: https://github.com/hashicorp/vagrant/issues/10078
[GH-10079]: https://github.com/hashicorp/vagrant/issues/10079
[GH-10081]: https://github.com/hashicorp/vagrant/issues/10081
[GH-10083]: https://github.com/hashicorp/vagrant/issues/10083
[GH-10084]: https://github.com/hashicorp/vagrant/issues/10084
[GH-10092]: https://github.com/hashicorp/vagrant/issues/10092
[GH-10100]: https://github.com/hashicorp/vagrant/issues/10100
[GH-10115]: https://github.com/hashicorp/vagrant/issues/10115
[GH-10116]: https://github.com/hashicorp/vagrant/issues/10116
[GH-10118]: https://github.com/hashicorp/vagrant/issues/10118
[GH-10123]: https://github.com/hashicorp/vagrant/issues/10123
[GH-10126]: https://github.com/hashicorp/vagrant/issues/10126
[GH-10140]: https://github.com/hashicorp/vagrant/issues/10140
[GH-10148]: https://github.com/hashicorp/vagrant/issues/10148
[GH-10154]: https://github.com/hashicorp/vagrant/issues/10154
[GH-10155]: https://github.com/hashicorp/vagrant/issues/10155
[GH-10156]: https://github.com/hashicorp/vagrant/issues/10156
[GH-10165]: https://github.com/hashicorp/vagrant/issues/10165
[GH-10168]: https://github.com/hashicorp/vagrant/issues/10168
[GH-10171]: https://github.com/hashicorp/vagrant/issues/10171
[GH-10181]: https://github.com/hashicorp/vagrant/issues/10181
[GH-10182]: https://github.com/hashicorp/vagrant/issues/10182
[GH-10189]: https://github.com/hashicorp/vagrant/issues/10189
[GH-10191]: https://github.com/hashicorp/vagrant/issues/10191
[GH-10194]: https://github.com/hashicorp/vagrant/issues/10194
[GH-10198]: https://github.com/hashicorp/vagrant/issues/10198
[GH-10199]: https://github.com/hashicorp/vagrant/issues/10199
[GH-10200]: https://github.com/hashicorp/vagrant/issues/10200
[GH-10215]: https://github.com/hashicorp/vagrant/issues/10215
[GH-10218]: https://github.com/hashicorp/vagrant/issues/10218
[GH-10219]: https://github.com/hashicorp/vagrant/issues/10219
[GH-10220]: https://github.com/hashicorp/vagrant/issues/10220
[GH-10221]: https://github.com/hashicorp/vagrant/issues/10221
[GH-10223]: https://github.com/hashicorp/vagrant/issues/10223
[GH-10232]: https://github.com/hashicorp/vagrant/issues/10232
[GH-10235]: https://github.com/hashicorp/vagrant/issues/10235
[GH-10242]: https://github.com/hashicorp/vagrant/issues/10242
[GH-10255]: https://github.com/hashicorp/vagrant/issues/10255
[GH-10258]: https://github.com/hashicorp/vagrant/issues/10258
[GH-10259]: https://github.com/hashicorp/vagrant/issues/10259
[GH-10264]: https://github.com/hashicorp/vagrant/issues/10264
[GH-10265]: https://github.com/hashicorp/vagrant/issues/10265
[GH-10267]: https://github.com/hashicorp/vagrant/issues/10267
[GH-10275]: https://github.com/hashicorp/vagrant/issues/10275
[GH-10279]: https://github.com/hashicorp/vagrant/issues/10279
[GH-10291]: https://github.com/hashicorp/vagrant/issues/10291
[GH-10301]: https://github.com/hashicorp/vagrant/issues/10301
[GH-10311]: https://github.com/hashicorp/vagrant/issues/10311
[GH-10313]: https://github.com/hashicorp/vagrant/issues/10313
[GH-10319]: https://github.com/hashicorp/vagrant/issues/10319
[GH-10321]: https://github.com/hashicorp/vagrant/issues/10321
[GH-10326]: https://github.com/hashicorp/vagrant/issues/10326
[GH-10330]: https://github.com/hashicorp/vagrant/issues/10330
[GH-10332]: https://github.com/hashicorp/vagrant/issues/10332
[GH-10347]: https://github.com/hashicorp/vagrant/issues/10347
[GH-10351]: https://github.com/hashicorp/vagrant/issues/10351
[GH-10359]: https://github.com/hashicorp/vagrant/issues/10359
[GH-10364]: https://github.com/hashicorp/vagrant/issues/10364
[GH-10365]: https://github.com/hashicorp/vagrant/issues/10365
[GH-10366]: https://github.com/hashicorp/vagrant/issues/10366
[GH-10368]: https://github.com/hashicorp/vagrant/issues/10368
[GH-10374]: https://github.com/hashicorp/vagrant/issues/10374
[GH-10379]: https://github.com/hashicorp/vagrant/issues/10379
[GH-10383]: https://github.com/hashicorp/vagrant/issues/10383
[GH-10387]: https://github.com/hashicorp/vagrant/issues/10387
[GH-10389]: https://github.com/hashicorp/vagrant/issues/10389
[GH-10390]: https://github.com/hashicorp/vagrant/issues/10390
[GH-10399]: https://github.com/hashicorp/vagrant/issues/10399
[GH-10404]: https://github.com/hashicorp/vagrant/issues/10404
[GH-10405]: https://github.com/hashicorp/vagrant/issues/10405
[GH-10406]: https://github.com/hashicorp/vagrant/issues/10406
[GH-10409]: https://github.com/hashicorp/vagrant/issues/10409
[GH-10410]: https://github.com/hashicorp/vagrant/issues/10410
[GH-10450]: https://github.com/hashicorp/vagrant/issues/10450
[GH-10467]: https://github.com/hashicorp/vagrant/issues/10467
[GH-10468]: https://github.com/hashicorp/vagrant/issues/10468
[GH-10469]: https://github.com/hashicorp/vagrant/issues/10469
[GH-10470]: https://github.com/hashicorp/vagrant/issues/10470
[GH-10474]: https://github.com/hashicorp/vagrant/issues/10474
[GH-10479]: https://github.com/hashicorp/vagrant/issues/10479
[GH-10482]: https://github.com/hashicorp/vagrant/issues/10482
[GH-10485]: https://github.com/hashicorp/vagrant/issues/10485
[GH-10486]: https://github.com/hashicorp/vagrant/issues/10486
[GH-10487]: https://github.com/hashicorp/vagrant/issues/10487
[GH-10488]: https://github.com/hashicorp/vagrant/issues/10488
[GH-10489]: https://github.com/hashicorp/vagrant/issues/10489
[GH-10490]: https://github.com/hashicorp/vagrant/issues/10490
[GH-10496]: https://github.com/hashicorp/vagrant/issues/10496
[GH-10506]: https://github.com/hashicorp/vagrant/issues/10506
[GH-10512]: https://github.com/hashicorp/vagrant/issues/10512
[GH-10513]: https://github.com/hashicorp/vagrant/issues/10513
[GH-10515]: https://github.com/hashicorp/vagrant/issues/10515
[GH-10524]: https://github.com/hashicorp/vagrant/issues/10524
[GH-10527]: https://github.com/hashicorp/vagrant/issues/10527
[GH-10528]: https://github.com/hashicorp/vagrant/issues/10528
[GH-10529]: https://github.com/hashicorp/vagrant/issues/10529
[GH-10532]: https://github.com/hashicorp/vagrant/issues/10532
[GH-10537]: https://github.com/hashicorp/vagrant/issues/10537
[GH-10554]: https://github.com/hashicorp/vagrant/issues/10554
[GH-10570]: https://github.com/hashicorp/vagrant/issues/10570
[GH-10571]: https://github.com/hashicorp/vagrant/issues/10571
[GH-10573]: https://github.com/hashicorp/vagrant/issues/10573
[GH-10574]: https://github.com/hashicorp/vagrant/issues/10574
[GH-10586]: https://github.com/hashicorp/vagrant/issues/10586
[GH-10591]: https://github.com/hashicorp/vagrant/issues/10591
[GH-10595]: https://github.com/hashicorp/vagrant/issues/10595
[GH-10615]: https://github.com/hashicorp/vagrant/issues/10615
[GH-10622]: https://github.com/hashicorp/vagrant/issues/10622
[GH-10625]: https://github.com/hashicorp/vagrant/issues/10625
[GH-10629]: https://github.com/hashicorp/vagrant/issues/10629
[GH-10638]: https://github.com/hashicorp/vagrant/issues/10638
[GH-10645]: https://github.com/hashicorp/vagrant/issues/10645
[GH-10647]: https://github.com/hashicorp/vagrant/issues/10647
[GH-10664]: https://github.com/hashicorp/vagrant/issues/10664
[GH-10666]: https://github.com/hashicorp/vagrant/issues/10666
[GH-10686]: https://github.com/hashicorp/vagrant/issues/10686
[GH-10690]: https://github.com/hashicorp/vagrant/issues/10690
[GH-10698]: https://github.com/hashicorp/vagrant/issues/10698
[GH-10702]: https://github.com/hashicorp/vagrant/issues/10702
[GH-10706]: https://github.com/hashicorp/vagrant/issues/10706
[GH-10707]: https://github.com/hashicorp/vagrant/issues/10707
[GH-10713]: https://github.com/hashicorp/vagrant/issues/10713
[GH-10717]: https://github.com/hashicorp/vagrant/issues/10717
[GH-10726]: https://github.com/hashicorp/vagrant/issues/10726
[GH-10727]: https://github.com/hashicorp/vagrant/issues/10727
[GH-10745]: https://github.com/hashicorp/vagrant/issues/10745
[GH-10748]: https://github.com/hashicorp/vagrant/issues/10748
[GH-10752]: https://github.com/hashicorp/vagrant/issues/10752
[GH-10761]: https://github.com/hashicorp/vagrant/issues/10761
[GH-10763]: https://github.com/hashicorp/vagrant/issues/10763
[GH-10784]: https://github.com/hashicorp/vagrant/issues/10784
[GH-10803]: https://github.com/hashicorp/vagrant/issues/10803
[GH-10810]: https://github.com/hashicorp/vagrant/issues/10810
[GH-10811]: https://github.com/hashicorp/vagrant/issues/10811
[GH-10820]: https://github.com/hashicorp/vagrant/issues/10820
[GH-10824]: https://github.com/hashicorp/vagrant/issues/10824
[GH-10828]: https://github.com/hashicorp/vagrant/issues/10828
[GH-10829]: https://github.com/hashicorp/vagrant/issues/10829
[GH-10841]: https://github.com/hashicorp/vagrant/issues/10841
[GH-10854]: https://github.com/hashicorp/vagrant/issues/10854
[GH-10889]: https://github.com/hashicorp/vagrant/issues/10889
[GH-10890]: https://github.com/hashicorp/vagrant/issues/10890
[GH-10891]: https://github.com/hashicorp/vagrant/issues/10891
[GH-10894]: https://github.com/hashicorp/vagrant/issues/10894
[GH-10896]: https://github.com/hashicorp/vagrant/issues/10896
[GH-10901]: https://github.com/hashicorp/vagrant/issues/10901
[GH-10902]: https://github.com/hashicorp/vagrant/issues/10902
[GH-10908]: https://github.com/hashicorp/vagrant/issues/10908
[GH-10909]: https://github.com/hashicorp/vagrant/issues/10909
[GH-10917]: https://github.com/hashicorp/vagrant/issues/10917
[GH-10938]: https://github.com/hashicorp/vagrant/issues/10938
[GH-10975]: https://github.com/hashicorp/vagrant/issues/10975
[GH-10978]: https://github.com/hashicorp/vagrant/issues/10978
[GH-11000]: https://github.com/hashicorp/vagrant/issues/11000
[GH-11012]: https://github.com/hashicorp/vagrant/issues/11012
[GH-11013]: https://github.com/hashicorp/vagrant/issues/11013
[GH-11014]: https://github.com/hashicorp/vagrant/issues/11014
[GH-11043]: https://github.com/hashicorp/vagrant/issues/11043
[GH-11053]: https://github.com/hashicorp/vagrant/issues/11053
[GH-11056]: https://github.com/hashicorp/vagrant/issues/11056
[GH-11068]: https://github.com/hashicorp/vagrant/issues/11068
[GH-11075]: https://github.com/hashicorp/vagrant/issues/11075
[GH-11076]: https://github.com/hashicorp/vagrant/issues/11076
[GH-11089]: https://github.com/hashicorp/vagrant/issues/11089
[GH-11093]: https://github.com/hashicorp/vagrant/issues/11093
[GH-11097]: https://github.com/hashicorp/vagrant/issues/11097
[GH-11098]: https://github.com/hashicorp/vagrant/issues/11098
[GH-11099]: https://github.com/hashicorp/vagrant/issues/11099
[GH-11100]: https://github.com/hashicorp/vagrant/issues/11100
[GH-11101]: https://github.com/hashicorp/vagrant/issues/11101
[GH-11106]: https://github.com/hashicorp/vagrant/issues/11106
[GH-11108]: https://github.com/hashicorp/vagrant/issues/11108
[GH-11111]: https://github.com/hashicorp/vagrant/issues/11111
[GH-11116]: https://github.com/hashicorp/vagrant/issues/11116
[GH-11126]: https://github.com/hashicorp/vagrant/issues/11126
[GH-11152]: https://github.com/hashicorp/vagrant/issues/11152
[GH-11170]: https://github.com/hashicorp/vagrant/issues/11170
[GH-11175]: https://github.com/hashicorp/vagrant/issues/11175
[GH-11178]: https://github.com/hashicorp/vagrant/issues/11178
[GH-11183]: https://github.com/hashicorp/vagrant/issues/11183
[GH-11184]: https://github.com/hashicorp/vagrant/issues/11184
[GH-11188]: https://github.com/hashicorp/vagrant/issues/11188
[GH-11191]: https://github.com/hashicorp/vagrant/issues/11191
[GH-11192]: https://github.com/hashicorp/vagrant/issues/11192
[GH-11194]: https://github.com/hashicorp/vagrant/issues/11194
[GH-11201]: https://github.com/hashicorp/vagrant/issues/11201
[GH-11205]: https://github.com/hashicorp/vagrant/issues/11205
[GH-11211]: https://github.com/hashicorp/vagrant/issues/11211
[GH-11212]: https://github.com/hashicorp/vagrant/issues/11212
[GH-11216]: https://github.com/hashicorp/vagrant/issues/11216
[GH-11220]: https://github.com/hashicorp/vagrant/issues/11220
[GH-11223]: https://github.com/hashicorp/vagrant/issues/11223
[GH-11231]: https://github.com/hashicorp/vagrant/issues/11231
[GH-11239]: https://github.com/hashicorp/vagrant/issues/11239
[GH-11244]: https://github.com/hashicorp/vagrant/issues/11244
[GH-11250]: https://github.com/hashicorp/vagrant/issues/11250
[GH-11258]: https://github.com/hashicorp/vagrant/issues/11258
[GH-11265]: https://github.com/hashicorp/vagrant/issues/11265
[GH-11267]: https://github.com/hashicorp/vagrant/issues/11267
[GH-11295]: https://github.com/hashicorp/vagrant/issues/11295
[GH-11349]: https://github.com/hashicorp/vagrant/issues/11349
[GH-11355]: https://github.com/hashicorp/vagrant/issues/11355
[GH-11356]: https://github.com/hashicorp/vagrant/issues/11356
[GH-11359]: https://github.com/hashicorp/vagrant/issues/11359
[GH-11363]: https://github.com/hashicorp/vagrant/issues/11363
[GH-11366]: https://github.com/hashicorp/vagrant/issues/11366
[GH-11398]: https://github.com/hashicorp/vagrant/issues/11398
[GH-11400]: https://github.com/hashicorp/vagrant/issues/11400
[GH-11404]: https://github.com/hashicorp/vagrant/issues/11404
[GH-11407]: https://github.com/hashicorp/vagrant/issues/11407
[GH-11411]: https://github.com/hashicorp/vagrant/issues/11411
[GH-11414]: https://github.com/hashicorp/vagrant/issues/11414
[GH-11425]: https://github.com/hashicorp/vagrant/issues/11425
[GH-11427]: https://github.com/hashicorp/vagrant/issues/11427
[GH-11428]: https://github.com/hashicorp/vagrant/issues/11428
[GH-11430]: https://github.com/hashicorp/vagrant/issues/11430
[GH-11436]: https://github.com/hashicorp/vagrant/issues/11436
[GH-11441]: https://github.com/hashicorp/vagrant/issues/11441
[GH-11445]: https://github.com/hashicorp/vagrant/issues/11445
[GH-11446]: https://github.com/hashicorp/vagrant/issues/11446
[GH-11454]: https://github.com/hashicorp/vagrant/issues/11454
[GH-11455]: https://github.com/hashicorp/vagrant/issues/11455
[GH-11461]: https://github.com/hashicorp/vagrant/issues/11461
[GH-11462]: https://github.com/hashicorp/vagrant/issues/11462
[GH-11463]: https://github.com/hashicorp/vagrant/issues/11463
[GH-11472]: https://github.com/hashicorp/vagrant/issues/11472
[GH-11473]: https://github.com/hashicorp/vagrant/issues/11473
[GH-11487]: https://github.com/hashicorp/vagrant/issues/11487
[GH-11498]: https://github.com/hashicorp/vagrant/issues/11498
[GH-11499]: https://github.com/hashicorp/vagrant/issues/11499
[GH-11500]: https://github.com/hashicorp/vagrant/issues/11500
[GH-11503]: https://github.com/hashicorp/vagrant/issues/11503
[GH-11517]: https://github.com/hashicorp/vagrant/issues/11517
[GH-11523]: https://github.com/hashicorp/vagrant/issues/11523
[GH-11533]: https://github.com/hashicorp/vagrant/issues/11533
[GH-11541]: https://github.com/hashicorp/vagrant/issues/11541
[GH-11560]: https://github.com/hashicorp/vagrant/issues/11560
[GH-11565]: https://github.com/hashicorp/vagrant/issues/11565
[GH-11566]: https://github.com/hashicorp/vagrant/issues/11566
[GH-11567]: https://github.com/hashicorp/vagrant/issues/11567
[GH-11570]: https://github.com/hashicorp/vagrant/issues/11570
[GH-11571]: https://github.com/hashicorp/vagrant/issues/11571
[GH-11579]: https://github.com/hashicorp/vagrant/issues/11579
[GH-11581]: https://github.com/hashicorp/vagrant/issues/11581
[GH-11584]: https://github.com/hashicorp/vagrant/issues/11584
[GH-11587]: https://github.com/hashicorp/vagrant/issues/11587
[GH-11592]: https://github.com/hashicorp/vagrant/issues/11592
[GH-11602]: https://github.com/hashicorp/vagrant/issues/11602
[GH-11613]: https://github.com/hashicorp/vagrant/issues/11613
[GH-11614]: https://github.com/hashicorp/vagrant/issues/11614
[GH-11618]: https://github.com/hashicorp/vagrant/issues/11618
[GH-11621]: https://github.com/hashicorp/vagrant/issues/11621
[GH-11628]: https://github.com/hashicorp/vagrant/issues/11628
[GH-11629]: https://github.com/hashicorp/vagrant/issues/11629
[GH-11631]: https://github.com/hashicorp/vagrant/issues/11631
[GH-11644]: https://github.com/hashicorp/vagrant/issues/11644
[GH-11654]: https://github.com/hashicorp/vagrant/issues/11654
[GH-11656]: https://github.com/hashicorp/vagrant/issues/11656
[GH-11679]: https://github.com/hashicorp/vagrant/issues/11679
[GH-11688]: https://github.com/hashicorp/vagrant/issues/11688
[GH-11694]: https://github.com/hashicorp/vagrant/issues/11694
[GH-11704]: https://github.com/hashicorp/vagrant/issues/11704
[GH-11717]: https://github.com/hashicorp/vagrant/issues/11717
[GH-11718]: https://github.com/hashicorp/vagrant/issues/11718
[GH-11719]: https://github.com/hashicorp/vagrant/issues/11719
[GH-11721]: https://github.com/hashicorp/vagrant/issues/11721
[GH-11732]: https://github.com/hashicorp/vagrant/issues/11732
[GH-11746]: https://github.com/hashicorp/vagrant/issues/11746
[GH-11750]: https://github.com/hashicorp/vagrant/issues/11750
[GH-11756]: https://github.com/hashicorp/vagrant/issues/11756
[GH-11759]: https://github.com/hashicorp/vagrant/issues/11759
[GH-11767]: https://github.com/hashicorp/vagrant/issues/11767
[GH-11773]: https://github.com/hashicorp/vagrant/issues/11773
[GH-11787]: https://github.com/hashicorp/vagrant/issues/11787
[GH-11795]: https://github.com/hashicorp/vagrant/issues/11795
[GH-11805]: https://github.com/hashicorp/vagrant/issues/11805
[GH-11806]: https://github.com/hashicorp/vagrant/issues/11806
[GH-11807]: https://github.com/hashicorp/vagrant/issues/11807
[GH-11809]: https://github.com/hashicorp/vagrant/issues/11809
[GH-11810]: https://github.com/hashicorp/vagrant/issues/11810
[GH-11814]: https://github.com/hashicorp/vagrant/issues/11814
