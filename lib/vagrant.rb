# Enable logging if it is requested. We do this before
# anything else so that we can setup the output before
# any logging occurs.
if ENV["VAGRANT_LOG"]
  require 'log4r'
  logger = Log4r::Logger.new("vagrant")
  logger.outputters = Log4r::Outputter.stdout
  logger.level = Log4r.const_get(ENV["VAGRANT_LOG"].upcase)
  logger = nil
end

require 'pathname'
require 'json'
require 'i18n'
require 'virtualbox'

# OpenSSL must be loaded here since when it is loaded via `autoload`
# there are issues with ciphers not being properly loaded.
require 'openssl'

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
  autoload :Registry,      'vagrant/registry'
  autoload :SSH,           'vagrant/ssh'
  autoload :TestHelpers,   'vagrant/test_helpers'
  autoload :UI,            'vagrant/ui'
  autoload :Util,          'vagrant/util'
  autoload :VM,            'vagrant/vm'

  # The source root is the path to the root directory of
  # the Vagrant gem.
  def self.source_root
    @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
  end

  # Global registry of available host classes and shortcut symbols
  # associated with them.
  #
  # This registry is used to look up the shorcuts for `config.vagrant.host`,
  # or to query all hosts for automatically detecting the host system.
  # The registry is global to all of Vagrant.
  def self.hosts
    @hosts ||= Registry.new
  end

  # Global registry of available guest classes and shortcut symbols
  # associated with them.
  #
  # This registry is used to look up the shortcuts for `config.vm.guest`.
  def self.guests
    @guests ||= Registry.new
  end
end

# # Default I18n to load the en locale
I18n.load_path << File.expand_path("templates/locales/en.yml", Vagrant.source_root)

# Register the built-in hosts
Vagrant.hosts.register(:arch)    { Vagrant::Hosts::Arch }
Vagrant.hosts.register(:freebsd) { Vagrant::Hosts::FreeBSD }
Vagrant.hosts.register(:fedora)  { Vagrant::Hosts::Fedora }
Vagrant.hosts.register(:linux)   { Vagrant::Hosts::Linux }
Vagrant.hosts.register(:bsd)     { Vagrant::Hosts::BSD }

# Register the built-in guests
Vagrant.guests.register(:arch)    { Vagrant::Systems::Arch }
Vagrant.guests.register(:debian)  { Vagrant::Systems::Debian }
Vagrant.guests.register(:freebsd) { Vagrant::Systems::FreeBSD }
Vagrant.guests.register(:gentoo)  { Vagrant::Systems::Gentoo }
Vagrant.guests.register(:linux)   { Vagrant::Systems::Linux }
Vagrant.guests.register(:redhat)  { Vagrant::Systems::Redhat }
Vagrant.guests.register(:solaris) { Vagrant::Systems::Solaris }
Vagrant.guests.register(:suse)    { Vagrant::Systems::Suse }
Vagrant.guests.register(:ubuntu)  { Vagrant::Systems::Ubuntu }

# Load the things which must be loaded before anything else.
require 'vagrant/command'
require 'vagrant/provisioners'
require 'vagrant/systems'
require 'vagrant/version'
Vagrant::Plugin.load!
