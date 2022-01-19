require 'vagrant/machine_index/remote'

module Vagrant
  class Environment
    module Remote

      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      def initialize(opts={})
        @client = opts[:client]
        if @client.nil?
          raise ArgumentError,
            "Remote client is required for `#{self.class.name}'"
        end

        @logger = Log4r::Logger.new("vagrant::environment")

        # Set the default ui class
        opts[:ui_class] ||= UI::Remote

        @cwd = Pathname.new(@client.cwd)
        @home_path = Pathname.new(@client.home)
        @vagrantfile_name = [@client.vagrantfile_name]
        @ui = opts.fetch(:ui, opts[:ui_class].new(@client.ui))
        @local_data_path = Pathname.new(@client.local_data)
        @boxes_path = @home_path.join("boxes")
        @data_dir = Pathname.new(@client.data_dir)
        @gems_path = Vagrant::Bundler.instance.plugin_gem_path
        @tmp_path = Pathname.new(@client.temp_dir)

        # This is the batch lock, that enforces that only one {BatchAction}
        # runs at a time from {#batch}.
        @batch_lock = Mutex.new
        @locks = {}

        @logger.info("Environment initialized (#{self})")
        @logger.info("  - cwd: #{cwd}")
        @logger.info("  - home path: #{home_path}")

        # TODO: aliases
        @aliases_path = Pathname.new(ENV["VAGRANT_ALIAS_FILE"]).expand_path if ENV.key?("VAGRANT_ALIAS_FILE")
        @aliases_path ||= @home_path.join("aliases")

        @default_private_key_path = Pathname.new(@client.default_private_key)
        copy_insecure_private_key

        # Initialize localized plugins
        plugins = Vagrant::Plugin::Manager.instance.localize!(self)
        # Load any environment local plugins
        Vagrant::Plugin::Manager.instance.load_plugins(plugins)

        # Initialize globalize plugins
        plugins = Vagrant::Plugin::Manager.instance.globalize!
        # Load any global plugins
        Vagrant::Plugin::Manager.instance.load_plugins(plugins)

        plugins = process_configured_plugins

        # Call the hooks that does not require configurations to be loaded
        # by using a "clean" action runner
        hook(:environment_plugins_loaded, runner: Action::Runner.new(env: self))

        # Call the environment load hooks
        hook(:environment_load, runner: Action::Runner.new(env: self))
      end

      # Returns the collection of boxes for the environment.
      #
      # @return [BoxCollection]
      def boxes
        box_colletion_client = client.boxes
        @_boxes ||= BoxCollection.new(nil, client: box_colletion_client)
      end

      # Returns the host object associated with this environment.
      #
      # @return [Class]
      def host
        if !@host
          h = @client.host
          @host = Vagrant::Host.new(h, nil, nil, self)
        end
        @host
      end

      # Gets a target (machine) by name
      #
      # @param [String] machine name
      # return [VagrantPlugins::CommandServe::Client::Machine]
      def get_target(name)
        client.target(name)
      end

      def setup_home_path
        # no-op
        # Don't setup a home path in ruby
      end

      def setup_local_data_path(force=false)
        # no-op
        # Don't setup a home path in ruby
      end

      # The {MachineIndex} to store information about the machines.
      #
      # @return [MachineIndex]
      def machine_index
        @machine_index ||= Vagrant::MachineIndex.new(client: client.target_index)
      end

      def vagrantfile
        if @vagrantfile.nil?
          path = client.vagrantfile_path
          name = client.vagrantfile_name
          full_path = path.join(name).to_s

          config_loader = Vagrant::Config::Loader.new(
            Vagrant::Config::VERSIONS, Vagrant::Config::VERSIONS_ORDER)
          config_loader.set(:root, full_path)
          @vagrantfile = Vagrant::Vagrantfile.new(config_loader, [:root])
        end
        @vagrantfile
      end
      
      def to_proto
        client.proto
      end
    end
  end
end
