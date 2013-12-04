module Vagrant
  module Action
    module Builtin
      module MixinSyncedFolders
        # This goes over all the registered synced folder types and returns
        # the highest priority implementation that is usable for this machine.
        def default_synced_folder_type(machine, plugins)
          ordered = []

          # First turn the plugins into an array
          plugins.each do |key, data|
            impl     = data[0]
            priority = data[1]

            ordered << [priority, key, impl]
          end

          # Order the plugins by priority
          ordered = ordered.sort { |a, b| b[0] <=> a[0] }

          # Find the proper implementation
          ordered.each do |_, key, impl|
            return key if impl.new.usable?(machine)
          end

          return nil
        end
        
        # This finds the options in the env that are set for a given
        # synced folder type.
        def impl_opts(name, env)
          {}.tap do |result|
            env.each do |k, v|
              if k.to_s.start_with?("#{name}_")
                k = k.dup if !k.is_a?(Symbol)
                v = v.dup if !v.is_a?(Symbol)
                result[k] = v
              end
            end
          end
        end

        # This returns the available synced folder implementations. This
        # is a separate method so that it can be easily stubbed by tests.
        def plugins
          @plugins ||= Vagrant.plugin("2").manager.synced_folders
        end

        # This returns the set of shared folders that should be done for
        # this machine. It returns the folders in a hash keyed by the
        # implementation class for the synced folders.
        def synced_folders(machine)
          folders = {}

          # Determine all the synced folders as well as the implementation
          # they're going to use.
          machine.config.vm.synced_folders.each do |id, data|
            # Ignore disabled synced folders
            next if data[:disabled]

            impl = ""
            impl = data[:type].to_sym if data[:type]

            if impl != ""
              impl_class = plugins[impl]
              if !impl_class
                # This should never happen because configuration validation
                # should catch this case. But we put this here as an assert
                raise "Internal error. Report this as a bug. Invalid: #{data[:type]}"
              end

              if !impl_class[0].new.usable?(machine)
                # Verify that explicitly defined shared folder types are
                # actually usable.
                raise Errors::SyncedFolderUnusable, type: data[:type].to_s
              end
            end

            # Keep track of this shared folder by the implementation.
            folders[impl] ||= {}
            folders[impl][id] = data.dup
          end

          # If we have folders with the "default" key, then determine the
          # most appropriate implementation for this.
          if folders.has_key?("") && !folders[""].empty?
            default_impl = default_synced_folder_type(machine, plugins)
            if !default_impl
              types = plugins.to_hash.keys.map { |t| t.to_s }.sort.join(", ")
              raise Errors::NoDefaultSyncedFolderImpl, types: types
            end

            folders[default_impl] = folders[""]
            folders.delete("")
          end

          return folders
        end
      end
    end
  end
end
