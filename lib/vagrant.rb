require 'log4r'

# Enable logging if it is requested. We do this before
# anything else so that we can setup the output before
# any logging occurs.
if ENV["VAGRANT_LOG"] && ENV["VAGRANT_LOG"] != ""
  # Require Log4r and define the levels we'll be using
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

# Always make the version available
require 'vagrant/version'
Log4r::Logger.new("vagrant::global").info("Vagrant version: #{Vagrant::VERSION}")

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
  autoload :Easy,          'vagrant/easy'
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

  # Returns a superclass to use when creating a plugin for Vagrant.
  # Given a specific version, this returns a proper superclass to use
  # to register plugins for that version.
  #
  # Plugins should subclass the class returned by this method, and will
  # be registered as soon as they have a name associated with them.
  #
  # @return [Class]
  def self.plugin(version)
    # We only support version 1 right now.
    return Plugin::V1 if version == "1"

    # Raise an error that the plugin version is invalid
    raise ArgumentError, "Invalid plugin version API: #{version}"
  end

  # This should be used instead of Ruby's built-in `require` in order to
  # load a Vagrant plugin. This will load the given plugin by first doing
  # a normal `require`, giving a nice error message if things go wrong,
  # and second by verifying that a Vagrant plugin was actually defined in
  # the process.
  #
  # @param [String] name Name of the plugin to load.
  def self.require_plugin(name)
    # Attempt the normal require
    begin
      require name
    rescue LoadError
      raise Errors::PluginLoadError, :plugin => name
    end
  end
end

# # Default I18n to load the en locale
I18n.load_path << File.expand_path("templates/locales/en.yml", Vagrant.source_root)

# A lambda that knows how to load plugins from a single directory.
plugin_load_proc = lambda do |directory|
  # We only care about directories
  return false if !directory.directory?

  # If there is a plugin file in the top-level directory, then load
  # that up.
  plugin_file = directory.join("plugin.rb")
  if plugin_file.file?
    load(plugin_file)
    return true
  end
end

# Go through the `plugins` directory and attempt to load any plugins. The
# plugins are allowed to be in a directory in `plugins` or at most one
# directory deep within the plugins directory. So a plugin can be at
# `plugins/foo` or also at `plugins/foo/bar`, but no deeper.
Vagrant.source_root.join("plugins").each_child do |directory|
  # Ignore non-directories
  next if !directory.directory?

  # Load from this directory, and exit if we successfully loaded a plugin
  next if plugin_load_proc.call(directory)

  # Otherwise, attempt to load from sub-directories
  directory.each_child(&plugin_load_proc)
end
