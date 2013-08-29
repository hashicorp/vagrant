Vagrant.configure("2") do |config|
  config.vagrant.host = :detect

  config.ssh.forward_agent = false
  config.ssh.forward_x11 = false
  config.ssh.guest_port = 22
  config.ssh.keep_alive = true
  config.ssh.shell = "bash -l"

  config.ssh.default.username = "vagrant"

  config.vm.usable_port_range = (2200..2250)
  config.vm.box_url = nil
  config.vm.base_mac = nil
  config.vm.boot_timeout = 300
  config.vm.graceful_halt_timeout = 60

  # Share SSH locally by default
  config.vm.network :forwarded_port,
    guest: 22,
    host: 2222,
    host_ip: "127.0.0.1",
    id: "ssh",
    auto_correct: true

  # Share the root folder. This can then be overridden by
  # other Vagrantfiles, if they wish.
  config.vm.synced_folder ".", "/vagrant"

  config.nfs.map_uid = :auto
  config.nfs.map_gid = :auto

  config.package.name = 'package.box'
end
