module Vagrant
  class Machine
    # This module enables the Machine for server mode
    module Remote

      # Add an attribute reader for the client
      # when applied to the Machine class
      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      # Initialize a new machine.
      #
      # @param [String] name Name of the virtual machine.
      # @param [Class] provider The provider backing this machine. This is
      #   currently expected to be a V1 `provider` plugin.
      # @param [Object] provider_config The provider-specific configuration for
      #   this machine.
      # @param [Hash] provider_options The provider-specific options from the
      #   plugin definition.
      # @param [Object] config The configuration for this machine.
      # @param [Pathname] data_dir The directory where machine-specific data
      #   can be stored. This directory is ensured to exist.
      # @param [Box] box The box that is backing this virtual machine.
      # @param [Environment] env The environment that this machine is a
      #   part of.
      def initialize(name, provider_name, provider_cls, provider_config, provider_options, config, data_dir, box, env, vagrantfile, base=false)
        @logger = Log4r::Logger.new("vagrant::machine")
        @client = env.get_target(name)
        @env = env
        @ui = Vagrant::UI::Prefixed.new(@env.ui, name)

        # TODO: Get provider info from client
        @provider_name = provider_name
        @provider = provider_cls.new(self)
        @provider._initialize(provider_name, self)
        @provider_options = provider_options
        @provider_config = provider_config

        @box             = @client.box
        @config          = config
        @data_dir        = @client.data_dir
        @vagrantfile     = vagrantfile
        @name            = name
        @ui_mutex        = Mutex.new
        @state_mutex     = Mutex.new
        @triggers        = Vagrant::Plugin::V2::Trigger.new(@env, @config.trigger, self, @ui)

        # Keep track of where our UUID should be placed
        @index_uuid_file = nil
        @index_uuid_file = @data_dir.join("index_uuid") if @data_dir

        # If the ID is the special not created ID, then set our ID to
        # nil so that we destroy all our data.
        # if state.id == MachineState::NOT_CREATED_ID
        #   self.id = nil
        # end

        # Output a bunch of information about this machine in
        # machine-readable format in case someone is listening.
        @ui.machine("metadata", "provider", provider_name)
      end

      # @return [Box]
      # def box
      #   client.get_box
      # end

      # def config
      #   raise NotImplementedError, "TODO"
      # end

      # @return [Pathname]
      # def data_dir
      #   Pathname.new(client.get_data_dir)
      # end

      def id
        result = client.id
        result.to_s.empty? ? nil : result
      end

      def name
        client.name
      end

      # def index_uuid
      #   client.get_uuid
      # end

      def recover_machine(*_)
        nil
      end

      def state
        s = @provider.state
        if s != @_cached_state
          client.set_machine_state(s) unless s.nil?
          @_cached_state = s
        end
        s
      end

      def provider
        @provider
      end

      def provider_name
        client.provider_name.to_sym
      end

      def provider_options
        @provider_options
      end

      def inspect
        "<Vagrant::Machine:resource_id=#{client.resource_id}>"
      end

      ### HACKS

      def action(name, opts=nil)
        @logger.info("Calling action: #{name} on provider #{@provider}")

        opts ||= {}

        # Determine whether we lock or not
        lock = true
        lock = opts.delete(:lock) if opts.key?(:lock)

        # Extra env keys are the remaining opts
        extra_env = opts.dup
        # An environment is required for triggers to function properly. This is
        # passed in specifically for the `#Action::Warden` class triggers. We call it
        # `:trigger_env` instead of `env` in case it collides with an existing environment
        extra_env[:trigger_env] = @env

        check_cwd # Warns the UI if the machine was last used on a different dir

        # Create a deterministic ID for this machine
        vf = nil
        vf = @env.vagrantfile_name[0] if @env.vagrantfile_name
        id = Digest::MD5.hexdigest(
          "#{@env.root_path}#{vf}#{@env.local_data_path}#{@name}")

        # We only lock if we're not executing an SSH action. In the future
        # we will want to do more fine-grained unlocking in actions themselves
        # but for a 1.6.2 release this will work.
        locker = Proc.new { |*args, &block| block.call }
        locker = @env.method(:lock) if lock && !name.to_s.start_with?("ssh")

        # Lock this machine for the duration of this action
        return_env = locker.call("machine-action-#{id}") do
          # Get the callable from the provider.
          callable = @provider.action(name)

          # If this action doesn't exist on the provider, then an exception
          # must be raised.
          if callable.nil?
            raise Errors::UnimplementedProviderAction,
              action: name,
              provider: @provider.to_s
          end

          # Call the action
          ui.machine("action", name.to_s, "start")
          action_result = action_raw(name, callable, extra_env)
          ui.machine("action", name.to_s, "end")
          action_result
        end
        # preserve returning environment after machine action runs
        return return_env
      rescue Errors::EnvironmentLockedError
        raise Errors::MachineActionLockedError,
          action: name,
          name: @name
      end

      def action_raw(name, callable, extra_env={})
        if !extra_env.is_a?(Hash)
          extra_env = {}
        end

        # Run the action with the action runner on the environment
        env = {ui: @ui}.merge(extra_env).merge(
          raw_action_name: name,
          action_name: "machine_action_#{name}".to_sym,
          machine: self,
          machine_action: name
        )
        @env.action_runner.run(callable, env)
      end

      def communicate
        # TODO: this should be communicating with the client.communicate
        if !@communicator
          requested  = @config.vm.communicator
          requested ||= :ssh
          klass = Vagrant.plugin("2").manager.communicators[requested]
          raise Errors::CommunicatorNotFound, comm: requested.to_s if !klass
          @communicator = klass.new(self)
        end

        @communicator
      end

      def guest
        raise Errors::MachineGuestNotReady if !communicate.ready?
        if !@guest
          @guest = Guest.new(self, nil, nil)
        end
        @guest
      end

      def id=(value)
        @logger.info("New machine ID: #{value.inspect}")
        client.set_id(value.to_s)
        # Store the ID locally
        @id = value.nil? ? nil : value.to_s
        # Notify the provider that the ID changed in case it needs to do
        # any accounting from it.
        @provider.machine_id_changed
      end

      def index_uuid
        return nil if !@index_uuid_file
        return @index_uuid_file.read.chomp if @index_uuid_file.file?
        return nil
      end

      def ssh_info
        # First, ask the provider for their information. If the provider
        # returns nil, then the machine is simply not ready for SSH, and
        # we return nil as well.
        info = @provider.ssh_info
        return nil if info.nil?

        # Delete out the nil entries.
        info.dup.each do |key, value|
          info.delete(key) if value.nil?
        end

        # We set the defaults
        info[:host] ||= @config.ssh.default.host
        info[:port] ||= @config.ssh.default.port
        info[:private_key_path] ||= @config.ssh.default.private_key_path
        info[:keys_only] ||= @config.ssh.default.keys_only
        info[:verify_host_key] ||= @config.ssh.default.verify_host_key
        info[:username] ||= @config.ssh.default.username
        info[:remote_user] ||= @config.ssh.default.remote_user
        info[:compression] ||= @config.ssh.default.compression
        info[:dsa_authentication] ||= @config.ssh.default.dsa_authentication
        info[:extra_args] ||= @config.ssh.default.extra_args
        info[:config] ||= @config.ssh.default.config

        # We set overrides if they are set. These take precedence over
        # provider-returned data.
        info[:host] = @config.ssh.host if @config.ssh.host
        info[:port] = @config.ssh.port if @config.ssh.port
        info[:keys_only] = @config.ssh.keys_only
        info[:verify_host_key] = @config.ssh.verify_host_key
        info[:compression] = @config.ssh.compression
        info[:dsa_authentication] = @config.ssh.dsa_authentication
        info[:username] = @config.ssh.username if @config.ssh.username
        info[:password] = @config.ssh.password if @config.ssh.password
        info[:remote_user] = @config.ssh.remote_user if @config.ssh.remote_user
        info[:extra_args] = @config.ssh.extra_args if @config.ssh.extra_args
        info[:config] = @config.ssh.config if @config.ssh.config

        # We also set some fields that are purely controlled by Vagrant
        info[:forward_agent] = @config.ssh.forward_agent
        info[:forward_x11] = @config.ssh.forward_x11
        info[:forward_env] = @config.ssh.forward_env
        info[:connect_timeout] = @config.ssh.connect_timeout

        info[:ssh_command] = @config.ssh.ssh_command if @config.ssh.ssh_command

        # Add in provided proxy command config
        info[:proxy_command] = @config.ssh.proxy_command if @config.ssh.proxy_command

        # Set the private key path. If a specific private key is given in
        # the Vagrantfile we set that. Otherwise, we use the default (insecure)
        # private key, but only if the provider didn't give us one.
        if !info[:private_key_path] && !info[:password]
          if @config.ssh.private_key_path
            info[:private_key_path] = @config.ssh.private_key_path
          elsif info[:keys_only]
            info[:private_key_path] = @env.default_private_key_path
          end
        end

        # If we have a private key in our data dir, then use that
        if @data_dir && !@config.ssh.private_key_path
          data_private_key = @data_dir.join("private_key")
          if data_private_key.file?
            info[:private_key_path] = [data_private_key.to_s]
          end
        end

        # Setup the keys
        info[:private_key_path] ||= []
        info[:private_key_path] = Array(info[:private_key_path])

        # Expand the private key path relative to the root path
        info[:private_key_path].map! do |path|
          File.expand_path(path, @env.root_path)
        end

        # Check that the private key permissions are valid
        info[:private_key_path].each do |path|
          key_path = Pathname.new(path)
          if key_path.exist?
            Vagrant::Util::SSH.check_key_permissions(key_path)
          end
        end

        # Return the final compiled SSH info data
        info
      end

      def recover_machine(state)
        # no-op
      end

      def uid
        path = uid_file
        return nil if !path
        return nil if !path.file?
        return uid_file.read.chomp
      end

      def with_ui(ui)
        @ui_mutex.synchronize do
          begin
            old_ui = @ui
            @ui    = ui
            yield
          ensure
            @ui = old_ui
          end
        end
      end

      def uid_file
        return nil if !@data_dir
        @data_dir.join("creator_uid")
      end

      def check_cwd
        desired_encoding = @env.root_path.to_s.encoding
        vagrant_cwd_filepath = @data_dir.join('vagrant_cwd')
        vagrant_cwd = if File.exist?(vagrant_cwd_filepath)
                        File.read(vagrant_cwd_filepath,
                          external_encoding: desired_encoding
                        ).chomp
                      end

        if !File.identical?(vagrant_cwd.to_s, @env.root_path.to_s)
          if vagrant_cwd
            ui.warn(I18n.t(
              'vagrant.moved_cwd',
              old_wd:     "#{vagrant_cwd}",
              current_wd: "#{@env.root_path.to_s}"))
          end
          File.write(vagrant_cwd_filepath, @env.root_path.to_s,
            external_encoding: desired_encoding
          )
        end
      end

      def synced_folders
        folders = Vagrant::Plugin::V2::SyncedFolder::Collection.new
        synced_folder_clients = client.synced_folders
        @logger.debug("synced folder clients: #{synced_folder_clients}")
        synced_folder_clients.each do |f|
          # TODO: get type of synced folder and wrap it up in this hash
          impl = "virtualbox"
          sf = Vagrant::Plugin::V2::SyncedFolder.new._initialize(self, impl, f)
          folders[impl] = {"id": {plugin: sf}}
        end
        folders
      end

      def to_proto
        client.proto
      end
    end
  end
end
