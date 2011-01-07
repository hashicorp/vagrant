module Vagrant
  module Downloaders
    autoload :Base, 'vagrant/downloaders/base'
    autoload :File, 'vagrant/downloaders/file'
    autoload :HTTP, 'vagrant/downloaders/http'
  end
end
