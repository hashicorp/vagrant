require 'pathname'
require 'json'
require 'i18n'
require 'virtualbox'

module Vagrant
  autoload :Action,        'vagrant/action'
  autoload :Box,           'vagrant/box'
  autoload :BoxCollection, 'vagrant/box_collection'
  autoload :CLI,           'vagrant/cli'
  autoload :Config,        'vagrant/config'
  autoload :DataStore,     'vagrant/data_store'
  autoload :Downloaders,   'vagrant/downloaders'
  autoload :Environment,   'vagrant/environment'
  autoload :Errors,        'vagrant/errors'
  autoload :Hosts,         'vagrant/hosts'
  autoload :Plugin,        'vagrant/plugin'
  autoload :TestHelpers,   'vagrant/test_helpers'
  autoload :UI,            'vagrant/ui'
  autoload :Util,          'vagrant/util'
  autoload :VM,            'vagrant/vm'

  # The source root is the path to the root directory of
  # the Vagrant gem.
  def self.source_root
    @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
  end
end

# Default I18n to load the en locale
I18n.load_path << File.expand_path("templates/locales/en.yml", Vagrant.source_root)

# Load the things which must be loaded before anything else. Note that
# I'm not sure why 'vagrant/ssh' must be loaded. But if I don't, I get
# a very scary "unsupported cipher" error from net-ssh for no apparent reason.
require 'vagrant/command'
require 'vagrant/provisioners'
require 'vagrant/systems'
require 'vagrant/ssh'
require 'vagrant/version'
Vagrant::Action.builtin!
Vagrant::Plugin.load!
