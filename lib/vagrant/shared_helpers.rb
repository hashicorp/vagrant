# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "pathname"
require "tempfile"
require "thread"

module Vagrant
  @@global_lock = Mutex.new

  # This is the default endpoint of the Vagrant Cloud in
  # use. API calls will be made to this for various functions
  # of Vagrant that may require remote access.
  #
  # @return [String]
  DEFAULT_SERVER_URL = "https://vagrantcloud.com".freeze

  # Max number of seconds to wait for joining an active thread.
  #
  # @return [Integer]
  # @note This is not the maximum time for a thread to complete.
  THREAD_MAX_JOIN_TIMEOUT = 60

  # This holds a global lock for the duration of the block. This should
  # be invoked around anything that is modifying process state (such as
  # environmental variables).
  def self.global_lock
    @@global_lock.synchronize do
      return yield
    end
  end

  # This returns a true/false showing whether we're running from the
  # environment setup by the Vagrant installers.
  #
  # @return [Boolean]
  def self.in_installer?
    !!ENV["VAGRANT_INSTALLER_ENV"]
  end

  # This returns a true/false if we are running within a bundler environment
  #
  # @return [Boolean]
  def self.in_bundler?
    !!ENV["BUNDLE_GEMFILE"] &&
      !defined?(::Bundler).nil?
  end

  # Returns the path to the embedded directory of the Vagrant installer,
  # if there is one (if we're running in an installer).
  #
  # @return [String]
  def self.installer_embedded_dir
    return nil if !Vagrant.in_installer?
    ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"]
  end

  # Should the plugin system be initialized
  #
  # @return [Boolean]
  def self.plugins_init?
    !ENV['VAGRANT_DISABLE_PLUGIN_INIT']
  end

  # This returns whether or not 3rd party plugins should and can be loaded.
  #
  # @return [Boolean]
  def self.plugins_enabled?
    !ENV["VAGRANT_NO_PLUGINS"]
  end

  # Whether or not super quiet mode is enabled. This is ill-advised.
  #
  # @return [Boolean]
  def self.very_quiet?
    !!ENV["VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET"]
  end

  # The current log level for Vagrant
  #
  # @return [String]
  def self.log_level
    ENV.fetch("VAGRANT_LOG", "fatal").downcase
  end

  # Returns the URL prefix to the server.
  #
  # @return [String]
  def self.server_url(config_server_url=nil)
    result = ENV["VAGRANT_SERVER_URL"]
    result = config_server_url if result == "" or result == nil
    result || DEFAULT_SERVER_URL
  end

  # The source root is the path to the root directory of the Vagrant source.
  #
  # @return [Pathname]
  def self.source_root
    @source_root ||= Pathname.new(File.expand_path('../../../', __FILE__))
  end

  # This returns the path to the ~/.vagrant.d folder where Vagrant's
  # per-user state is stored.
  #
  # @return [Pathname]
  def self.user_data_path
    # Use user specified env var if available
    path = ENV["VAGRANT_HOME"]

    # On Windows, we default to the USERPROFILE directory if it
    # is available. This is more compatible with Cygwin and sharing
    # the home directory across shells.
    if !path && ENV["USERPROFILE"]
      path = "#{ENV["USERPROFILE"]}/.vagrant.d"
    end

    # Fallback to the default
    path ||= "~/.vagrant.d"

    Pathname.new(path).expand_path
  end

  # This returns true/false if the running version of Vagrant is
  # a pre-release version (development)
  #
  # @return [Boolean]
  def self.prerelease?
    Gem::Version.new(Vagrant::VERSION).prerelease?
  end

  # This returns true/false if the Vagrant should allow prerelease
  # versions when resolving plugin dependency constraints
  #
  # @return [Boolean]
  def self.allow_prerelease_dependencies?
    !!ENV["VAGRANT_ALLOW_PRERELEASE"]
  end

  # This allows control over dependency resolution when installing
  # plugins into vagrant. When true, dependency libraries that Vagrant
  # core relies upon will be hard constraints.
  #
  # @return [Boolean]
  def self.strict_dependency_enforcement
    if ENV["VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT"]
      false
    else
      true
    end
  end

  # Automatically install locally defined plugins instead of
  # waiting for user confirmation.
  #
  # @return [Boolean]
  def self.auto_install_local_plugins?
    if ENV["VAGRANT_INSTALL_LOCAL_PLUGINS"]
      true
    else
      false
    end
  end

  # Use Ruby Resolv in place of libc
  #
  # @return [boolean] enabled or not
  def self.enable_resolv_replace
    if ENV["VAGRANT_ENABLE_RESOLV_REPLACE"]
      if !ENV["VAGRANT_DISABLE_RESOLV_REPLACE"]
        begin
          Vagrant.require "resolv-replace"
          true
        rescue
          false
        end
      else
        false
      end
    end
  end

  # Set the global logger
  #
  # @param log Logger
  # @return [Logger]
  def self.global_logger=(log)
    @_global_logger = log
  end

  # Get the global logger instance
  #
  # @return [Logger]
  def self.global_logger
    if @_global_logger.nil?
      Vagrant.require "log4r"
      @_global_logger = Log4r::Logger.new("vagrant::global")
    end
    @_global_logger
  end

  # Add a new block of default CLI options which
  # should be automatically added to all commands
  #
  # @param [Proc] block Proc instance containing OptParser configuration
  # @return [nil]
  def self.add_default_cli_options(block)
    if !block.is_a?(Proc)
      raise TypeError,
        "Expecting type `Proc` but received `#{block.class}`"
    end
    if block.arity != 1 && block.arity != -1
      raise ArgumentError,
        "Proc must accept OptionParser argument"
    end
    @_default_cli_options = [] if !@_default_cli_options
    @_default_cli_options << block
    nil
  end

  # Array of default CLI options to automatically
  # add to commands.
  #
  # @return [Array<Proc>] Default optparse options
  def self.default_cli_options
    @_default_cli_options = [] if !@_default_cli_options
    @_default_cli_options.dup
  end

  # Loads the provided path. If the base of the path
  # is a Vagrant runtime dependency, the gem will be
  # activated with the proper constraint first.
  #
  # NOTE: This is currently disabled by default and
  # will transition to enabled by default as more
  # non-installer based environments are tested.
  #
  # @return [nil]
  def self.require(path)
    catch(:activation_complete) do
      # If activation is not enabled, don't attempt activation
      throw :activation_complete if ENV["VAGRANT_ENABLE_GEM_ACTIVATION"].nil?

      # If it's a vagrant path, don't do anything.
      throw :activation_complete if path.to_s.start_with?("vagrant/")

      # Attempt to fetch the vagrant specification
      if @_vagrant_spec.nil?
        @_vagrant_activated_dependencies = {}
        begin
          @_vagrant_spec = Gem::Specification.find_by_name("vagrant")
        rescue Gem::MissingSpecError
          # If it couldn't be found, print a warning to stderr and bail
          if !@_spec_load_failure_warning
            $stderr.puts "WARN: Failed to locate vagrant specification for dependency loading"
            @_spec_load_failure_warning = true
          end

          throw :activation_complete
        end
      end

      # Attempt to get the name of the gem by the given path
      dep_name = Gem::Specification.find_by_path(path)&.name

      # Bail if a dependency name cannot be determined
      throw :activation_complete if dep_name.nil?

      # Bail if already activated
      throw :activation_complete if @_vagrant_activated_dependencies[dep_name]

      # Extract the dependency from the runtime dependency list
      dependency = @_vagrant_spec.runtime_dependencies.detect do |d|
        d.name == dep_name
      end

      # If the dependency isn't found, bail
      throw :activation_complete if dependency.nil?

      # Activate the gem
      gem(dependency.name, dependency.requirement.as_list)
puts "Activated: #{dependency.name}"
      @_vagrant_activated_dependencies[dependency.name] = true
    end

    # Finally, require the provided path.
    ::Kernel.require(path)

    nil
  end

  # Check if Vagrant is running in server mode
  #
  # @return [Boolean]
  def self.server_mode?
    !!@_server_mode
  end

  # Flag Vagrant as running in server mode
  #
  # @return [true]
  def self.enable_server_mode!
    if !server_mode?
      Util::HCLogOutputter.new("hclog")
      Log4r::Outputter["hclog"].formatter = Util::HCLogFormatter.new
      Log4r::Outputter.stderr.formatter = Log4r::Outputter["hclog"].formatter
      Log4r::RootLogger.instance.outputters = Log4r::Outputter["hclog"]
      Log4r::Logger.each_logger do |l|
        l.outputters = Log4r::Outputter["hclog"] #if l.parent&.is_root?
      end

      Log4r::Logger::Repository.class_eval do
        def self.[]=(n, l)
          self.synchronize do
            l.outputters = Log4r::Outputter["hclog"] # if l.parent&.is_root?
            instance.loggers[n] = l
          end
        end
      end

      # By default only display error logs from the mappers unless explicitly
      # requested due to their verbosity
      if ENV["VAGRANT_LOG_MAPPER"].to_s == ""
        l = Log4r::Logger.factory("vagrantplugins::commandserve::mappers")
        l.level = Log4r::ERROR
      end
    end
    Log4r::Logger.factory("vagrant").trace("service logger initialization")
    Log4r::Logger.factory("vagrantplugins").trace("service logger initialization")

    load_vagrant_proto!
    SERVER_MODE_CALLBACKS.each(&:call)

    @_server_mode = true
  end

  # Load the vagrant proto messages
  def self.load_vagrant_proto!
    return if @_vagrant_proto_loaded
    # Update the load path so our protos can be located
    $LOAD_PATH << Vagrant.source_root.join("lib/vagrant/protobufs").to_s
    $LOAD_PATH << Vagrant.source_root.join("lib/vagrant/protobufs/proto").to_s
    $LOAD_PATH << Vagrant.source_root.join("lib/vagrant/protobufs/proto/vagrant_plugin_sdk").to_s

    # Load our protos so they are available
    require 'vagrant/protobufs/proto/vagrant_server/server_pb'
    require 'vagrant/protobufs/proto/vagrant_server/server_services_pb'
    require 'vagrant/protobufs/proto/ruby_vagrant/ruby-server_pb'
    require 'vagrant/protobufs/proto/ruby_vagrant/ruby-server_services_pb'
    require 'vagrant/protobufs/proto/vagrant_plugin_sdk/plugin_pb'
    require 'vagrant/protobufs/proto/vagrant_plugin_sdk/plugin_services_pb'
    require 'vagrant/protobufs/proto/plugin/grpc_broker_pb'
    require 'vagrant/protobufs/proto/plugin/grpc_broker_services_pb'
    @_vagrant_proto_loaded = true
  end

  SERVER_MODE_CALLBACKS = [
    ->{ Vagrant::Box.prepend(Vagrant::Box::Remote) },
    ->{ Vagrant::BoxCollection.prepend(Vagrant::BoxCollection::Remote) },
    ->{ Vagrant::BoxMetadata.prepend(Vagrant::BoxMetadata::Remote) },
    ->{ Vagrant::Guest.prepend(Vagrant::Guest::Remote) },
    ->{ Vagrant::Host.prepend(Vagrant::Host::Remote) },
    ->{ Vagrant::Machine.prepend(Vagrant::Machine::Remote) },
    ->{ Vagrant::Environment.prepend(Vagrant::Environment::Remote) },
    ->{ Vagrant::MachineIndex.prepend(Vagrant::MachineIndex::Remote) },
    ->{ Vagrant::MachineIndex::Entry.prepend(Vagrant::MachineIndex::Entry::Remote::InstanceMethods) },
    ->{ Vagrant::MachineIndex::Entry.extend(Vagrant::MachineIndex::Entry::Remote::ClassMethods) },
    ->{ Vagrant::Action::Builtin::MixinSyncedFolders.prepend(Vagrant::Action::Builtin::Remote::MixinSyncedFolders) },
    ->{ Vagrant::Action::Builtin::SSHRun.prepend(Vagrant::Action::Builtin::Remote::SSHRun) },
    ->{ Vagrant::Vagrantfile.prepend(Vagrant::Vagrantfile::Remote) },
    ->{ Vagrant::Util::SSH.prepend(Vagrant::Util::Remote::SSH) },
    ->{ Vagrant::Util::SafePuts.prepend(Vagrant::Util::Remote::SafePuts) },
  ].freeze
end
