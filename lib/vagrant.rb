# Enable logging if it is requested. We do this before
# anything else so that we can setup the output before
# any logging occurs.
if ENV["VAGRANT_LOG"] && ENV["VAGRANT_LOG"] != ""
  # Require Log4r and define the levels we'll be using
  require 'log4r'
  require 'log4r/config'
  Log4r.define_levels(*Log4r::Log4rConfig::LogLevels)

  level = nil
  begin
    level = Log4r.const_get(ENV["VAGRANT_LOG"].upcase)
  rescue NameError
    # This means that the logging constant wasn't found,
    # which is fine. We just keep `level` as `nil`. But
    # we tell the user.
    level = nil
  end

  # Some constants, such as "true" resolve to booleans, so the
  # above error checking doesn't catch it. This will check to make
  # sure that the log level is an integer, as Log4r requires.
  level = nil if !level.is_a?(Integer)

  if !level
    # We directly write to stderr here because the VagrantError system
    # is not setup yet.
    $stderr.puts "Invalid VAGRANT_LOG level is set: #{ENV["VAGRANT_LOG"]}"
    $stderr.puts ""
    $stderr.puts "Please use one of the standard log levels: debug, info, warn, or error"
    exit 1
  end

  # Set the logging level on all "vagrant" namespaced
  # logs as long as we have a valid level.
  if level
    logger = Log4r::Logger.new("vagrant")
    logger.outputters = Log4r::Outputter.stderr
    logger.level = level
    logger = nil
  end
end

require 'pathname'
require 'childprocess'
require 'json'
require 'i18n'

# OpenSSL must be loaded here since when it is loaded via `autoload`
# there are issues with ciphers not being properly loaded.
require 'openssl'

module Vagrant
  autoload :Action,        'vagrant/action'
  autoload :Box,           'vagrant/box'
  autoload :BoxCollection, 'vagrant/box_collection'
  autoload :CLI,           'vagrant/cli'
  autoload :Command,       'vagrant/command'
  autoload :Communication, 'vagrant/communication'
  autoload :Config,        'vagrant/config'
  autoload :DataStore,     'vagrant/data_store'
  autoload :Downloaders,   'vagrant/downloaders'
  autoload :Driver,        'vagrant/driver'
  autoload :Environment,   'vagrant/environment'
  autoload :Errors,        'vagrant/errors'
  autoload :Guest,         'vagrant/guest'
  autoload :Hosts,         'vagrant/hosts'
  autoload :Plugin,        'vagrant/plugin'
  autoload :Provisioners,  'vagrant/provisioners'
  autoload :Registry,      'vagrant/registry'
  autoload :SSH,           'vagrant/ssh'
  autoload :TestHelpers,   'vagrant/test_helpers'
  autoload :UI,            'vagrant/ui'
  autoload :Util,          'vagrant/util'
  autoload :VM,            'vagrant/vm'

  # Returns a `Vagrant::Registry` object that contains all the built-in
  # middleware stacks.
  def self.actions
    @actions ||= Vagrant::Action::Builtin.new
  end

  # The source root is the path to the root directory of
  # the Vagrant gem.
  def self.source_root
    @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
  end

  # Global registry of commands that are available via the CLI.
  #
  # This registry is used to look up the sub-commands that are available
  # to Vagrant.
  def self.commands
    @commands ||= Registry.new
  end

  # Global registry of config keys that are available.
  #
  # This registry is used to look up the keys for `config` objects.
  # For example, `config.vagrant` looks up the `:vagrant` config key
  # for the configuration class to use.
  def self.config_keys
    @config_keys ||= Registry.new
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

  # Global registry of provisioners.
  #
  # This registry is used to look up the provisioners provided for
  # `config.vm.provision`.
  def self.provisioners
    @provisioners ||= Registry.new
  end
end

# # Default I18n to load the en locale
I18n.load_path << File.expand_path("templates/locales/en.yml", Vagrant.source_root)

# Register the built-in commands
Vagrant.commands.register(:box)          { Vagrant::Command::Box }
Vagrant.commands.register(:destroy)      { Vagrant::Command::Destroy }
Vagrant.commands.register(:halt)         { Vagrant::Command::Halt }
Vagrant.commands.register(:init)         { Vagrant::Command::Init }
Vagrant.commands.register(:package)      { Vagrant::Command::Package }
Vagrant.commands.register(:provision)    { Vagrant::Command::Provision }
Vagrant.commands.register(:reload)       { Vagrant::Command::Reload }
Vagrant.commands.register(:resume)       { Vagrant::Command::Resume }
Vagrant.commands.register(:ssh)          { Vagrant::Command::SSH }
Vagrant.commands.register(:"ssh-config") { Vagrant::Command::SSHConfig }
Vagrant.commands.register(:status)       { Vagrant::Command::Status }
Vagrant.commands.register(:suspend)      { Vagrant::Command::Suspend }
Vagrant.commands.register(:up)           { Vagrant::Command::Up }

# Register the built-in config keys
Vagrant.config_keys.register(:vagrant) { Vagrant::Config::VagrantConfig }
Vagrant.config_keys.register(:ssh)     { Vagrant::Config::SSHConfig }
Vagrant.config_keys.register(:nfs)     { Vagrant::Config::NFSConfig }
Vagrant.config_keys.register(:vm)      { Vagrant::Config::VMConfig }
Vagrant.config_keys.register(:package) { Vagrant::Config::PackageConfig }

# Register the built-in hosts
Vagrant.hosts.register(:arch)    { Vagrant::Hosts::Arch }
Vagrant.hosts.register(:bsd)     { Vagrant::Hosts::BSD }
Vagrant.hosts.register(:fedora)  { Vagrant::Hosts::Fedora }
Vagrant.hosts.register(:freebsd) { Vagrant::Hosts::FreeBSD }
Vagrant.hosts.register(:gentoo)  { Vagrant::Hosts::Gentoo }
Vagrant.hosts.register(:linux)   { Vagrant::Hosts::Linux }
Vagrant.hosts.register(:windows) { Vagrant::Hosts::Windows }

# Register the built-in guests
Vagrant.guests.register(:arch)    { Vagrant::Guest::Arch }
Vagrant.guests.register(:debian)  { Vagrant::Guest::Debian }
Vagrant.guests.register(:freebsd) { Vagrant::Guest::FreeBSD }
Vagrant.guests.register(:gentoo)  { Vagrant::Guest::Gentoo }
Vagrant.guests.register(:linux)   { Vagrant::Guest::Linux }
Vagrant.guests.register(:redhat)  { Vagrant::Guest::Redhat }
Vagrant.guests.register(:solaris) { Vagrant::Guest::Solaris }
Vagrant.guests.register(:suse)    { Vagrant::Guest::Suse }
Vagrant.guests.register(:ubuntu)  { Vagrant::Guest::Ubuntu }

# Register the built-in provisioners
Vagrant.provisioners.register(:chef_solo)     { Vagrant::Provisioners::ChefSolo }
Vagrant.provisioners.register(:chef_client)   { Vagrant::Provisioners::ChefClient }
Vagrant.provisioners.register(:puppet)        { Vagrant::Provisioners::Puppet }
Vagrant.provisioners.register(:puppet_server) { Vagrant::Provisioners::PuppetServer }
Vagrant.provisioners.register(:shell)         { Vagrant::Provisioners::Shell }

# Register the built-in systems
Vagrant.config_keys.register(:freebsd) { Vagrant::Guest::FreeBSD::FreeBSDConfig }
Vagrant.config_keys.register(:linux)   { Vagrant::Guest::Linux::LinuxConfig }
Vagrant.config_keys.register(:solaris) { Vagrant::Guest::Solaris::SolarisConfig }

# Load the things which must be loaded before anything else.
require 'vagrant/version'
Vagrant::Plugin.load!
