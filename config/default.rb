Hobo::Config.run do |config|
  # default config goes here
  config.ssh.uname = "hobo"
  config.ssh.pass = "hobo"
  config.ssh.host = "localhost"
  config.ssh.port = 2222
  config.ssh.max_tries = 10

  config.dotfile_name = ".hobo"

  config.vm.base = "~/.hobo/base/base.ovf"
  config.vm.base_mac = "0800279C2E41"
end