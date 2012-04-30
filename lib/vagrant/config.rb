module Vagrant
  module Config
    autoload :Base,          'vagrant/config/base'
    autoload :Container,     'vagrant/config/container'
    autoload :ErrorRecorder, 'vagrant/config/error_recorder'
    autoload :Loader,        'vagrant/config/loader'
    autoload :Top,           'vagrant/config/top'

    autoload :V1,            'vagrant/config/v1'

    CONFIGURE_MUTEX = Mutex.new

    # This is the method which is called by all Vagrantfiles to configure Vagrant.
    # This method expects a block which accepts a single argument representing
    # an instance of the {Config::Top} class.
    #
    # Note that the block is not run immediately. Instead, it's proc is stored
    # away for execution later.
    def self.run(&block)
      # Store it for later
      @last_procs ||= []
      @last_procs << block
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
