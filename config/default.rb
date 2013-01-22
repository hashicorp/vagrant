Vagrant.configure("2") do |config|
  # default config goes here
  config.vagrant.host = :detect

  config.ssh.username = "vagrant"
  config.ssh.guest_port = 22
  config.ssh.max_tries = 100
  config.ssh.timeout = 10
  config.ssh.forward_agent = false
  config.ssh.forward_x11 = false
  config.ssh.shell = "bash -l"

  config.vm.usable_port_range = (2200..2250)
  config.vm.box_url = nil
  config.vm.base_mac = nil
  config.vm.graceful_halt_retry_count = 60
  config.vm.graceful_halt_retry_interval = 1
  config.vm.guest = :linux

  # Share SSH locally by default
  config.vm.network :forwarded_port, 22, 2222,
    :id => "ssh",
    :auto_correct => true

  # Share the root folder. This can then be overridden by
  # other Vagrantfiles, if they wish.
  config.vm.share_folder("v-root", "/vagrant", ".")

  config.nfs.map_uid = :auto
  config.nfs.map_gid = :auto

  config.package.name = 'package.box'
end
