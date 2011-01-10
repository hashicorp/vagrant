module Vagrant
  class Action
    module Box
      autoload :Destroy,   'vagrant/action/box/destroy'
      autoload :Download,  'vagrant/action/box/download'
      autoload :Package,   'vagrant/action/box/package'
      autoload :Unpackage, 'vagrant/action/box/unpackage'
      autoload :Verify,    'vagrant/action/box/verify'
    end
  end
end
