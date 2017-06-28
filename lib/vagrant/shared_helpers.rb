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
  DEFAULT_SERVER_URL = "https://vagrantcloud.com"

  # Max number of seconds to wait for joining an active thread.
  #
  # @return [Integer]
  # @note This is not the maxium time for a thread to complete.
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
    ENV["VAGRANT_LOG"]
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
    # Use user spcified env var if available
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
end
