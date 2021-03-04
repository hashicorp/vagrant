module Vagrant
  class Machine
    class Thin < Machine
      extend Vagrant::Action::Builtin::MixinSyncedFolders

      attr_accessor :box, :config, :data_dir, :env, :name, :provider, :provider_config,
        :provider_name, :provider_options, :triggers, :ui, :vagrantfile


      attr_reader :client
      # NOTE: The client is internal so don't make it publicly accessible
#      protected :client

      def initialize(name, provider_name, provider_cls, provider_config, provider_options, config, data_dir, box, env, vagrantfile, base=false)
        @logger = Log4r::Logger.new("vagrant::machine")
        @client = VagrantPlugins::CommandServe::Client::Machine.new(name: name)
        @env = env
        @ui = Vagrant::UI::Prefixed.new(@env.ui, name)
        @provider_name = provider_name
        @provider = provider_cls.new(self)
        @provider._initialize(provider_name, self)
        @provider_options = provider_options

        @box             = box
        @config          = config
        @data_dir        = data_dir
        @vagrantfile     = vagrantfile
        @guest           = Guest.new(
          self,
          Vagrant.plugin("2").manager.guests,
          Vagrant.plugin("2").manager.guest_capabilities)
        @name            = name
        @provider_config = provider_config
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
        result = client.get_id
        result.to_s.empty? ? nil : result
      end

      def name
        client.get_name
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
          client.set_state(s) unless s.nil?
          @_cached_state = s
        end
        s
      end

      def provider
        @provider
      end

      def provider_name
        @provider_name
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
        @guest.detect! if !@guest.ready?
        @guest
      end

      def id=(value)
        @logger.info("New machine ID: #{value.inspect}")

        client.set_id(value.to_s)

        id_file = nil
        if @data_dir
          # The file that will store the id if we have one. This allows the
          # ID to persist across Vagrant runs. Also, store the UUID for the
          # machine index.
          id_file = @data_dir.join("id")
        end

        if value
          if id_file
            # Write the "id" file with the id given.
            id_file.open("w+") do |f|
              f.write(value)
            end
          end

          if uid_file
            # Write the user id that created this machine
            uid_file.open("w+") do |f|
              f.write(Process.uid.to_s)
            end
          end

          # If we don't have a UUID, then create one
          if index_uuid.nil?
            # Create the index entry and save it
            entry = MachineIndex::Entry.new
            entry.local_data_path = @env.local_data_path
            entry.name = @name.to_s
            entry.provider = @provider_name.to_s
            entry.state = "preparing"
            entry.vagrantfile_path = @env.root_path
            entry.vagrantfile_name = @env.vagrantfile_name

            if @box
              entry.extra_data["box"] = {
                "name"     => @box.name,
                "provider" => @box.provider.to_s,
                "version"  => @box.version.to_s,
              }
            end

            entry = @env.machine_index.set(entry)
            @env.machine_index.release(entry)

            # Store our UUID so we can access it later
            if @index_uuid_file
              @index_uuid_file.open("w+") do |f|
                f.write(entry.id)
              end
            end
          end
        else
          # Delete the file, since the machine is now destroyed
          id_file.delete if id_file && id_file.file?
          uid_file.delete if uid_file && uid_file.file?

          # If we have a UUID associated with the index, remove it
          uuid = index_uuid
          if uuid
            entry = @env.machine_index.get(uuid)
            @env.machine_index.delete(entry) if entry
          end

          if @data_dir
            # Delete the entire data directory contents since all state
            # associated with the VM is now gone.
            @data_dir.children.each do |child|
              begin
                child.rmtree
              rescue Errno::EACCES
                @logger.info("EACCESS deleting file: #{child}")
              end
            end
          end
        end

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
        entry = @env.machine_index.get(index_uuid)
        if entry
          @env.machine_index.release(entry)
          return entry
        end

        entry = MachineIndex::Entry.new(id=index_uuid, {})
        entry.local_data_path = @env.local_data_path
        entry.name = @name.to_s
        entry.provider = @provider_name.to_s
        entry.state = state
        entry.vagrantfile_path = @env.root_path
        entry.vagrantfile_name = @env.vagrantfile_name

        if @box
          entry.extra_data["box"] = {
            "name"     => @box.name,
            "provider" => @box.provider.to_s,
            "version"  => @box.version.to_s,
          }
        end

        @state_mutex.synchronize do
          entry = @env.machine_index.recover(entry)
          @env.machine_index.release(entry)
        end
        return entry
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
        self.class.synced_folders(self)
      end

    end
  end
end
