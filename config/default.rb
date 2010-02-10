Hobo::Config.run do |config|
  # default config goes here
  config.ssh.username = "hobo"
  config.ssh.password = "hobo"
  config.ssh.host = "localhost"
  config.ssh.forwarded_port_key = "ssh"
  config.ssh.max_tries = 10

  config.dotfile_name = ".hobo"

  config.vm.base = "~/.hobo/base/base.ovf"
  config.vm.base_mac = "0800279C2E41"
  config.vm.project_directory = "/hobo"
  config.vm.forward_port("ssh", 22, 2222)

  config.chef.cookbooks_path = "cookbooks"
  config.chef.provisioning_path = "/tmp/hobo-chef"
  config.chef.json = {
    :recipes => ["hobo_main"]
  }
end