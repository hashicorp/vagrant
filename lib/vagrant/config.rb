require "vagrant/registry"

module Vagrant
  module Config
    autoload :Loader,        'vagrant/config/loader'
    autoload :VersionBase,   'vagrant/config/version_base'

    autoload :V1,            'vagrant/config/v1'
    autoload :V2,            'vagrant/config/v2'

    # This is a mutex used to guarantee that only one thread can load
    # procs at any given time.
    CONFIGURE_MUTEX = Mutex.new

    # This is the registry which keeps track of what configuration
    # versions are available, mapped by the version string used in
    # `Vagrant.configure` calls.
    VERSIONS = Registry.new
    VERSIONS.register("1") { V1::Loader }
    VERSIONS.register("2") { V2::Loader }

    # This is the order of versions. This is used by the loader to figure out
    # how to "upgrade" versions up to the desired (current) version. The
    # current version is always considered to be the last version in this
    # list.
    VERSIONS_ORDER = ["1", "2"]
    CURRENT_VERSION = VERSIONS_ORDER.last

    # This is the method which is called by all Vagrantfiles to configure Vagrant.
    # This method expects a block which accepts a single argument representing
    # an instance of the {Config::Top} class.
    #
    # Note that the block is not run immediately. Instead, it's proc is stored
    # away for execution later.
    def self.run(version="1", &block)
      # Store it for later
      @last_procs ||= []
      @last_procs << [version.to_s, block]
    end

    # This is a method which will yield to a block and will capture all
    # ``Vagrant.configure`` calls, returning an array of `Proc`s.
    #
    # Wrapping this around anytime you call code which loads configurations
    # will force a mutex so that procs never get mixed up. This keeps
    # the configuration loading part of Vagrant thread-safe.
    def self.capture_configures
      CONFIGURE_MUTEX.synchronize do
        # Reset the last procs so that we start fresh
        @last_procs = []

        # Yield to allow the caller to do whatever loading needed
        yield

        # Return the last procs we've seen while still in the mutex,
        # knowing we're safe.
        return @last_procs
      end
    end
  end
end
