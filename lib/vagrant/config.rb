require 'vagrant/config/base'
require 'vagrant/config/error_recorder'
require 'vagrant/config/top'

# The built-in configuration classes
require 'vagrant/config/vagrant'
require 'vagrant/config/ssh'
require 'vagrant/config/nfs'
require 'vagrant/config/vm'
require 'vagrant/config/package'

module Vagrant
  # The config class is responsible for loading Vagrant configurations, which
  # are usually found in Vagrantfiles but may also be procs. The loading is done
  # by specifying a queue of files or procs that are for configuration, and then
  # executing them. The config loader will run each item in the queue, so that
  # configuration from later items overwrite that from earlier items. This is how
  # Vagrant "scoping" of Vagranfiles is implemented.
  #
  # If you're looking to create your own configuration classes, see {Base}.
  #
  # # Loading Configuration Files
  #
  # If you are in fact looking to load configuration files, then this is the
  # class you are looking for. Loading configuration is quite easy. The following
  # example assumes `env` is already a loaded instance of {Environment}:
  #
  #     config = Vagrant::Config.new
  #     config.set(:first, "/path/to/some/Vagrantfile")
  #     config.set(:second, "/path/to/another/Vagrantfile")
  #     config.load_order = [:first, :second]
  #     result = config.load(env)
  #
  #     p "Your box is: #{result.vm.box}"
  #
  # The load order determines what order the config files specified are loaded.
  # If a key is not mentioned (for example if above the load order was set to
  # `[:first]`, therefore `:second` was not mentioned), then that config file
  # won't be loaded.
  class Config
    # An array of symbols specifying the load order for the procs.
    attr_accessor :load_order
    attr_reader :procs

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

    # Returns the last proc which was activated for the class via {run}. This
    # also sets the last proc to `nil` so that calling this method multiple times
    # will not return duplicates.
    #
    # @return [Proc]
    def self.last_proc
      value = @last_procs
      @last_procs = nil
      value
    end

    def initialize(parent=nil)
      @procs = {}
      @load_order = []

      if parent
        # Shallow copy the procs and load order from parent if given
        @procs = parent.procs.dup
        @load_order = parent.load_order.dup
      end
    end

    # Adds a Vagrantfile to be loaded to the queue of config procs. Note
    # that this causes the Vagrantfile file to be loaded at this point,
    # and it will never be loaded again.
    def set(key, path)
      return if @procs.has_key?(key)
      @procs[key] = [path].flatten.map(&method(:proc_for)).flatten
    end

    # Loads the added procs using the set `load_order` attribute and returns
    # the {Config::Top} object result. The configuration is loaded for the
    # given {Environment} object.
    #
    # @param [Environment] env
    def load(env)
      config = Top.new(env)

      # Only run the procs specified in the load order, in the order
      # specified.
      load_order.each do |key|
        if @procs[key]
          @procs[key].each do |proc|
            proc.call(config) if proc
          end
        end
      end

      config
    end

    protected

    def proc_for(path)
      return nil if !path
      return path if path.is_a?(Proc)

      begin
        Kernel.load path if File.exist?(path)
        return self.class.last_proc
      rescue SyntaxError => e
        # Report syntax errors in a nice way for Vagrantfiles
        raise Errors::VagrantfileSyntaxError, :file => e.message
      end
    end
  end
end
