require "log4r"
require "vagrant/util/credential_scrubber"
# Update the default formatter within the log4r library to ensure
# sensitive values are being properly scrubbed from logger data
class Log4r::BasicFormatter
  alias_method :vagrant_format_object, :format_object
  def format_object(obj)
    Vagrant::Util::CredentialScrubber.desensitize(vagrant_format_object(obj))
  end
end


require "optparse"

module Vagrant
  # This is a customized OptionParser for Vagrant plugins. It
  # will automatically add any default CLI options defined
  # outside of command implementations to the local option
  # parser instances in use
  class OptionParser < ::OptionParser
    def initialize(*_)
      super
      Vagrant.default_cli_options.each do |opt_proc|
        opt_proc.call(self)
      end
    end
  end
end

# Inject the option parser into the vagrant plugins
# module so it is automatically used when defining
# command options
module VagrantPlugins
  OptionParser = Vagrant::OptionParser
end

require "vagrant/shared_helpers"
require "rubygems"
require "vagrant/util"
require "vagrant/plugin/manager"

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
    # NOTE: We must do this little hack to allow
    # rest-client to write using the `<<` operator.
    # See https://github.com/rest-client/rest-client/issues/34#issuecomment-290858
    # for more information
    class VagrantLogger < Log4r::Logger
      def << (msg)
        debug(msg.strip)
      end
    end
    logger = VagrantLogger.new("vagrant")
    logger.outputters = Log4r::Outputter.stderr
    logger.level = level
    base_formatter = Log4r::BasicFormatter.new
    if ENV["VAGRANT_LOG_TIMESTAMP"]
      base_formatter = Log4r::PatternFormatter.new(
        pattern: "%d [%5l] %m",
        date_pattern: "%F %T"
      )
    end

    Log4r::Outputter.stderr.formatter = Vagrant::Util::LoggingFormatter.new(base_formatter)
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
Vagrant.global_logger = global_logger
global_logger.info("Vagrant version: #{Vagrant::VERSION}")
global_logger.info("Ruby version: #{RUBY_VERSION}")
global_logger.info("RubyGems version: #{Gem::VERSION}")
ENV.each do |k, v|
  next if k.start_with?("VAGRANT_OLD")
  global_logger.info("#{k}=#{v.inspect}") if k.start_with?("VAGRANT_")
end

# We need these components always so instead of an autoload we
# just require them explicitly here.
require "vagrant/plugin"
require "vagrant/registry"

module Vagrant
  autoload :Action,        'vagrant/action'
  autoload :Alias,         'vagrant/alias'
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
  autoload :Host,          'vagrant/host'
  autoload :Machine,       'vagrant/machine'
  autoload :MachineIndex,  'vagrant/machine_index'
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
    c.register([:"2", :push])         { Plugin::V2::Push }
    c.register([:"2", :synced_folder]) { Plugin::V2::SyncedFolder }
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

  # This checks if a plugin with the given name is available (installed
  # and enabled). This can be used from the Vagrantfile to easily branch
  # based on plugin availability.
  def self.has_plugin?(name, version=nil)
    return false unless Vagrant.plugins_enabled?

    if !version
      # We check the plugin names first because those are cheaper to check
      return true if plugin("2").manager.registered.any? { |p| p.name == name }
    end

    # Now check the plugin gem names
    require "vagrant/plugin/manager"
    Plugin::Manager.instance.plugin_installed?(name, version)
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

  # @deprecated
  def self.require_plugin(name)
    puts "Vagrant.require_plugin is deprecated and has no effect any longer."
    puts "Use `vagrant plugin` commands to manage plugins. This warning will"
    puts "be removed in the next version of Vagrant."
  end

  # This checks if Vagrant is installed in a specific version.
  #
  # Example:
  #
  #    Vagrant.version?(">= 2.1.0")
  #
  def self.version?(*requirements)
    req = Gem::Requirement.new(*requirements)
    req.satisfied_by?(Gem::Version.new(VERSION))
  end

  # This allows a Vagrantfile to specify the version of Vagrant that is
  # required. You can specify a list of requirements which will all be checked
  # against the running Vagrant version.
  #
  # This should be specified at the _top_ of any Vagrantfile.
  #
  # Examples are shown below:
  #
  #   Vagrant.require_version(">= 1.3.5")
  #   Vagrant.require_version(">= 1.3.5", "< 1.4.0")
  #   Vagrant.require_version("~> 1.3.5")
  #
  def self.require_version(*requirements)
    logger = Log4r::Logger.new("vagrant::root")
    logger.info("Version requirements from Vagrantfile: #{requirements.inspect}")

    if version?(*requirements)
      logger.info("  - Version requirements satisfied!")
      return
    end

    raise Errors::VagrantVersionBad,
      requirements: requirements.join(", "),
      version: VERSION
  end

  # This allows plugin developers to access the original environment before
  # Vagrant even ran. This is useful when shelling out, especially to other
  # Ruby processes.
  #
  # @return [Hash]
  def self.original_env
    {}.tap do |h|
      ENV.each do |k,v|
        if k.start_with?("VAGRANT_OLD_ENV")
          key = k.sub(/^VAGRANT_OLD_ENV_/, "")
          if !key.empty?
            h[key] = v
          end
        end
      end
    end
  end
end

# Default I18n to load the en locale
I18n.load_path << File.expand_path("templates/locales/en.yml", Vagrant.source_root)

if I18n.config.respond_to?(:enforce_available_locales=)
  # Make sure only available locales are used. This will be the default in the
  # future but we need this to silence a deprecation warning from 0.6.9
  I18n.config.enforce_available_locales = true
end

if Vagrant.enable_resolv_replace
  global_logger.info("resolv replacement has been enabled!")
else
  global_logger.warn("resolv replacement has not been enabled!")
end

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
