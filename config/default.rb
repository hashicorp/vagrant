Vagrant::Config.run do |config|
  # default config goes here
  config.vagrant.log_output = STDOUT
  config.vagrant.home = "~/.vagrant"

  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"
  config.ssh.host = "localhost"
  config.ssh.forwarded_port_key = "ssh"
  config.ssh.max_tries = 10

  config.dotfile_name = ".vagrant"

  config.vm.base = "~/.vagrant/base/base.ovf"
  config.vm.base_mac = "0800279C2E41"
  config.vm.project_directory = "/vagrant"
  config.vm.forward_port("ssh", 22, 2222)
  config.vm.disk_image_format = 'VMDK'

  config.package.name = 'vagrant'
  config.package.extension = '.box'
  config.package.delimiter = 'VAGRANT'
  config.package.delimiter_regex = /(.*)#{config.package.delimiter}(.+)#{config.package.delimiter}(.*[\n\r])/

  config.chef.enabled = false
  config.chef.cookbooks_path = "cookbooks"
  config.chef.provisioning_path = "/tmp/vagrant-chef"
  config.chef.json = {
    :instance_role => "vagrant",
    :recipes => ["vagrant_main"]
  }
end
