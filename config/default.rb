Vagrant::Config.run do |config|
  # default config goes here
  config.vagrant.log_output = STDOUT
  config.vagrant.dotfile_name = ".vagrant"
  config.vagrant.home = "~/.vagrant"
  config.vagrant.host = :detect

  config.ssh.username = "vagrant"
  config.ssh.host = "localhost"
  config.ssh.port = 22
  config.ssh.forwarded_port_key = "ssh"
  config.ssh.max_tries = 10
  config.ssh.timeout = 30
  config.ssh.private_key_path = File.join(PROJECT_ROOT, 'keys', 'vagrant')
  config.ssh.forward_agent = false

  config.vm.auto_port_range = (2200..2250)
  config.vm.box_ovf = "box.ovf"
  config.vm.box_url = nil
  config.vm.base_mac = "0800279C2E42"
  config.vm.forward_port("ssh", 22, 2222, :auto => true)
  config.vm.disk_image_format = 'VMDK'
  config.vm.provisioner = nil
  config.vm.shared_folder_uid = nil
  config.vm.shared_folder_gid = nil
  config.vm.boot_mode = "vrdp"
  config.vm.system = :linux

  # Share the root folder. This can then be overridden by
  # other Vagrantfiles, if they wish.
  config.vm.share_folder("v-root", "/vagrant", ".")

  config.unison.folder_suffix = ".sync"
  config.unison.script = "/tmp/vagrant-unison"
  config.unison.options = "-terse -owner -group -batch"
  config.unison.crontab_entry_file = "/tmp/vagrant-unison-crontab"
  config.unison.log_file = "/tmp/v-unison-log-%s"

  config.nfs.map_uid = :auto
  config.nfs.map_gid = :auto

  config.package.name = 'package.box'
end
