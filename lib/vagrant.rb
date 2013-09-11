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

require 'json'
require 'pathname'
require 'stringio'

require 'childprocess'
require 'i18n'

# OpenSSL must be loaded here since when it is loaded via `autoload`
# there are issues with ciphers not being properly loaded.
require 'openssl'

# Always make the version available
require 'vagrant/version'
global_logger = Log4r::Logger.new("vagrant::global")
global_logger.info("Vagrant version: #{Vagrant::VERSION}")

# We need these components always so instead of an autoload we
# just require them explicitly here.
require "vagrant/registry"

module Vagrant
  autoload :Action,        'vagrant/action'
  autoload :BatchAction,   'vagrant/batch_action'
  autoload :Box,           'vagrant/box'
  autoload :BoxCollection, 'vagrant/box_collection'
  autoload :CLI,           'vagrant/cli'
  autoload :Command,       'vagrant/command'
  autoload :Config,        'vagrant/config'
  autoload :Driver,        'vagrant/driver'
  autoload :Environment,   'vagrant/environment'
  autoload :Errors,        'vagrant/errors'
  autoload :Guest,         'vagrant/guest'
  autoload :Hosts,         'vagrant/hosts'
  autoload :Machine,       'vagrant/machine'
  autoload :MachineState,  'vagrant/machine_state'
  autoload :Plugin,        'vagrant/plugin'
  autoload :UI,            'vagrant/ui'
  autoload :Util,          'vagrant/util'

  # These are the various plugin versions and their components in
  # a lazy loaded Hash-like structure.
  PLUGIN_COMPONENTS = Registry.new.tap do |c|
    c.register(:"1")                  { Plugin::V1::Plugin }
    c.register([:"1", :command])      { Plugin::V1::Command }
    c.register([:"1", :communicator]) { Plugin::V1::Communicator }
    c.register([:"1", :config])       { Plugin::V1::Config }
    c.register([:"1", :guest])        { Plugin::V1::Guest }
    c.register([:"1", :host])         { Plugin::V1::Host }
    c.register([:"1", :provider])     { Plugin::V1::Provider }
    c.register([:"1", :provisioner])  { Plugin::V1::Provisioner }

    c.register(:"2")                  { Plugin::V2::Plugin }
    c.register([:"2", :command])      { Plugin::V2::Command }
    c.register([:"2", :communicator]) { Plugin::V2::Communicator }
    c.register([:"2", :config])       { Plugin::V2::Config }
    c.register([:"2", :guest])        { Plugin::V2::Guest }
    c.register([:"2", :host])         { Plugin::V2::Host }
    c.register([:"2", :provider])     { Plugin::V2::Provider }
    c.register([:"2", :provisioner])  { Plugin::V2::Provisioner }
  end

  # This returns a true/false showing whether we're running from the
  # environment setup by the Vagrant installers.
  #
  # @return [Boolean]
  def self.in_installer?
    !!ENV["VAGRANT_INSTALLER_ENV"]
  end

  # The source root is the path to the root directory of
  # the Vagrant gem.
  def self.source_root
    @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
  end

  # Configure a Vagrant environment. The version specifies the version
  # of the configuration that is expected by the block. The block, based
  # on that version, configures the environment.
  #
  # Note that the block isn't run immediately. Instead, the configuration
  # block is stored until later, and is run when an environment is loaded.
  #
  # @param [String] version Version of the configuration
  def self.configure(version, &block)
    Config.run(version, &block)
  end

  # This checks if a plugin with the given name is installed. This can
  # be used from the Vagrantfile to easily branch based on plugin
  # availability.
  def self.has_plugin?(name)
    plugin("2").manager.registered.any? { |plugin| plugin.name == name }
  end

  # Returns a superclass to use when creating a plugin for Vagrant.
  # Given a specific version, this returns a proper superclass to use
  # to register plugins for that version.
  #
  # Optionally, if you give a specific component, then it will return
  # the proper superclass for that component as well.
  #
  # Plugins and plugin components should subclass the classes returned by
  # this method. This method lets Vagrant core control these superclasses
  # and change them over time without affecting plugins. For example, if
  # the V1 superclass happens to be "Vagrant::V1," future versions of
  # Vagrant may move it to "Vagrant::Plugins::V1" and plugins will not be
  # affected.
  #
  # @param [String] version
  # @param [String] component
  # @return [Class]
  def self.plugin(version, component=nil)
    # Build up the key and return a result
    key    = version.to_s.to_sym
    key    = [key, component.to_s.to_sym] if component
    result = PLUGIN_COMPONENTS.get(key)

    # If we found our component then we return that
    return result if result

    # If we didn't find a result, then raise an exception, depending
    # on if we got a component or not.
    raise ArgumentError, "Plugin superclass not found for version/component: " +
      "#{version} #{component}"
  end

  # This should be used instead of Ruby's built-in `require` in order to
  # load a Vagrant plugin. This will load the given plugin by first doing
  # a normal `require`, giving a nice error message if things go wrong,
  # and second by verifying that a Vagrant plugin was actually defined in
  # the process.
  #
  # @param [String] name Name of the plugin to load.
  def self.require_plugin(name)
    if ENV["VAGRANT_NO_PLUGINS"]
      logger = Log4r::Logger.new("vagrant::root")
      logger.warn("VAGRANT_NO_PLUGINS is set, not loading 3rd party plugin: #{name}")
      return
    end

    # Redirect stdout/stderr so that we can output it in our own way.
    previous_stderr = $stderr
    previous_stdout = $stdout
    $stderr = StringIO.new
    $stdout = StringIO.new

    # Attempt the normal require
    begin
      require name
    rescue Exception => e
      # Since this is a rare case, we create a one-time logger here
      # in order to output the error
      logger = Log4r::Logger.new("vagrant::root")
      logger.error("Failed to load plugin: #{name}")
      logger.error(" -- Error: #{e.inspect}")
      logger.error(" -- Backtrace:")
      logger.error(e.backtrace.join("\n"))

      # If it is a LoadError we first try to see if it failed loading
      # the top-level entrypoint. If so, then we report a different error.
      if e.is_a?(LoadError)
        # Parse the message in order to get what failed to load, and
        # add some extra protection around if the message is different.
        parts = e.to_s.split(" -- ", 2)
        if parts.length == 2 && parts[1] == name
          raise Errors::PluginLoadError, :plugin => name
        end
      end

      # Get the string data out from the stdout/stderr captures
      stderr = $stderr.string
      stdout = $stdout.string
      if !stderr.empty? || !stdout.empty?
        raise Errors::PluginLoadFailedWithOutput,
          :plugin => name,
          :stderr => stderr,
          :stdout => stdout
      end

      # And raise an error itself
      raise Errors::PluginLoadFailed,
        :plugin => name
    end
  ensure
    $stderr = previous_stderr if previous_stderr
    $stdout = previous_stdout if previous_stdout
  end
end

# Default I18n to load the en locale
I18n.load_path << File.expand_path("templates/locales/en.yml", Vagrant.source_root)

# A lambda that knows how to load plugins from a single directory.
plugin_load_proc = lambda do |directory|
  # We only care about directories
  next false if !directory.directory?

  # If there is a plugin file in the top-level directory, then load
  # that up.
  plugin_file = directory.join("plugin.rb")
  if plugin_file.file?
    global_logger.debug("Loading core plugin: #{plugin_file}")
    load(plugin_file)
    next true
  end
end

# Go through the `plugins` directory and attempt to load any plugins. The
# plugins are allowed to be in a directory in `plugins` or at most one
# directory deep within the plugins directory. So a plugin can be at
# `plugins/foo` or also at `plugins/foo/bar`, but no deeper.
Vagrant.source_root.join("plugins").children(true).each do |directory|
  # Ignore non-directories
  next if !directory.directory?

  # Load from this directory, and exit if we successfully loaded a plugin
  next if plugin_load_proc.call(directory)

  # Otherwise, attempt to load from sub-directories
  directory.children(true).each(&plugin_load_proc)
end
