module Vagrant
  class Action
    module General
      autoload :Package,  'vagrant/action/general/package'
      autoload :Validate, 'vagrant/action/general/validate'
    end
  end
end
