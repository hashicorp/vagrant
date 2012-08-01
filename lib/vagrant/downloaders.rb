module Vagrant
  module Downloaders
    autoload :Base, 'vagrant/downloaders/base'
    autoload :File, 'vagrant/downloaders/file'
    autoload :HTTP, 'vagrant/downloaders/http'
    autoload :SCP, 'vagrant/downloaders/scp'
  end
end
