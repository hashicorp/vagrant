Vagrant::Config.run do |config|
  # default config goes here
  config.vagrant.log_output = STDOUT
  config.vagrant.dotfile_name = ".vagrant"
  config.vagrant.home = "~/.vagrant"

  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"
  config.ssh.host = "localhost"
  config.ssh.forwarded_port_key = "ssh"
  config.ssh.max_tries = 10
  config.ssh.timeout = 30
  config.ssh.private_key_path = File.join(PROJECT_ROOT, 'keys', 'vagrant')

  config.vm.box_ovf = "box.ovf"
  config.vm.base_mac = "0800279C2E42"
  config.vm.project_directory = "/vagrant"
  config.vm.forward_port("ssh", 22, 2222)
  config.vm.disk_image_format = 'VMDK'
  config.vm.provisioner = nil
  config.vm.shared_folder_uid = nil
  config.vm.shared_folder_gid = nil
  config.vm.boot_mode = "vrdp"

  config.package.name = 'vagrant'
  config.package.extension = '.box'
end
