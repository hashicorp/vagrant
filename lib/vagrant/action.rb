require 'log4r'

require 'vagrant/action/builder'
require 'vagrant/action/builtin'

# The builtin middlewares
require 'vagrant/action/box'
require 'vagrant/action/env'
require 'vagrant/action/general'
require 'vagrant/action/vm'

module Vagrant
  class Action
    autoload :Environment, 'vagrant/action/environment'
    autoload :Registry,    'vagrant/action/registry'
    autoload :Runner,      'vagrant/action/runner'
    autoload :Warden,      'vagrant/action/warden'
  end
end
