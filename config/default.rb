Vagrant::Config.run do |config|
  # default config goes here
  config.vagrant.dotfile_name = ".vagrant"
  config.vagrant.host = :detect
  config.vagrant.ssh_session_cache = false

  config.ssh.username = "vagrant"
  config.ssh.host = "127.0.0.1"
  config.ssh.forwarded_port_key = "ssh"
  config.ssh.forwarded_port_destination = 22
  config.ssh.max_tries = 10
  config.ssh.timeout = 30
  config.ssh.connect_timeout = 2
  config.ssh.private_key_path = File.expand_path("keys/vagrant", Vagrant.source_root)
  config.ssh.forward_agent = false
  config.ssh.forward_x11 = false
  config.ssh.shared_connections = true
  config.ssh.master_connection = nil

  config.vm.auto_port_range = (2200..2250)
  config.vm.box_ovf = "box.ovf"
  config.vm.box_url = nil
  config.vm.base_mac = nil
  config.vm.forward_port("ssh", 22, 2222, :auto => true)
  config.vm.boot_mode = "vrdp"
  config.vm.system = :linux
  config.vm.distribution = :ubuntu

  config.vm.customize do |vm|
    # Make VM name the name of the containing folder by default
    vm.name = File.basename(config.env.cwd) + "_#{Time.now.to_i}"
  end

  # Share the root folder. This can then be overridden by
  # other Vagrantfiles, if they wish.
  config.vm.share_folder("v-root", "/vagrant", ".")

  config.nfs.map_uid = :auto
  config.nfs.map_gid = :auto

  config.package.name = 'package.box'
end
