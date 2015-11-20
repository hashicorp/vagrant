require "json"
require "set"

require 'vagrant/util/scoped_hash_override'

module Vagrant
  module Action
    module Builtin
      module MixinSyncedFolders
        include Vagrant::Util::ScopedHashOverride

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

          # Order the plugins by priority. Higher is tried before lower.
          ordered = ordered.sort { |a, b| b[0] <=> a[0] }

          allowed_types = machine.config.vm.allowed_synced_folder_types
          if allowed_types
            ordered = allowed_types.map do |type|
              ordered.find do |_, key, impl|
                key == type
              end
            end.compact
          end

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
                # While I generally don't like the 'rescue' syntax,
                # we do this to just fall back to the default value
                # if it isn't dup-able.
                k = k.dup rescue k
                v = v.dup rescue v

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

        # This saves the synced folders data to the machine data directory.
        # They can then be retrieved again with `synced_folders` by passing
        # the `cached` option to it.
        #
        # @param [Machine] machine The machine that the folders belong to
        # @param [Hash] folders The result from a {#synced_folders} call.
        def save_synced_folders(machine, folders, **opts)
          if opts[:merge]
            existing = cached_synced_folders(machine)
            if existing
              if opts[:vagrantfile]
                # Go through and find any cached that were from the
                # Vagrantfile itself. We remove those if it was requested.
                existing.each do |impl, fs|
                  fs.each do |id, data|
                    fs.delete(id) if data[:__vagrantfile]
                  end
                end
              end

              folders.each do |impl, fs|
                existing[impl] ||= {}
                fs.each do |id, data|
                  existing[impl][id] = data
                end
              end

              folders = existing
            end
          end

          machine.data_dir.join("synced_folders").open("w") do |f|
            f.write(JSON.dump(folders))
          end
        end

        # This returns the set of shared folders that should be done for
        # this machine. It returns the folders in a hash keyed by the
        # implementation class for the synced folders.
        #
        # @return [Hash<Symbol, Hash<String, Hash>>]
        def synced_folders(machine, **opts)
          return cached_synced_folders(machine) if opts[:cached]

          config = opts[:config]
          root   = false
          if !config
            config = machine.config.vm
            root   = true
          end

          config_folders = config.synced_folders
          folders = {}

          # Determine all the synced folders as well as the implementation
          # they're going to use.
          config_folders.each do |id, data|
            # Ignore disabled synced folders
            next if data[:disabled]

            impl = ""
            impl = data[:type].to_sym if data[:type] && !data[:type].empty?

            if impl != ""
              impl_class = plugins[impl]
              if !impl_class
                # This should never happen because configuration validation
                # should catch this case. But we put this here as an assert
                raise "Internal error. Report this as a bug. Invalid: #{data[:type]}"
              end

              if !opts[:disable_usable_check]
                if !impl_class[0].new.usable?(machine, true)
                  # Verify that explicitly defined shared folder types are
                  # actually usable.
                  raise Errors::SyncedFolderUnusable, type: data[:type].to_s
                end
              end
            end

            # Get the data to store
            data = data.dup
            if root
              # If these are the root synced folders (attached directly)
              # to the Vagrantfile, then we mark it as such.
              data[:__vagrantfile] = true
            end

            # Keep track of this shared folder by the implementation.
            folders[impl] ||= {}
            folders[impl][id] = data
          end

          # If we have folders with the "default" key, then determine the
          # most appropriate implementation for this.
          if folders.key?("") && !folders[""].empty?
            default_impl = default_synced_folder_type(machine, plugins)
            if !default_impl
              types = plugins.to_hash.keys.map { |t| t.to_s }.sort.join(", ")
              raise Errors::NoDefaultSyncedFolderImpl, types: types
            end

            folders[default_impl] ||= {}
            folders[default_impl].merge!(folders[""])
            folders.delete("")
          end

          # Apply the scoped hash overrides to get the options
          folders.dup.each do |impl_name, fs|
            new_fs = {}
            fs.each do |id, data|
              id         = data[:id] if data[:id]
              new_fs[id] = scoped_hash_override(data, impl_name)
            end

            folders[impl_name] = new_fs
          end

          return folders
        end

        # This finds the difference between two lists of synced folder
        # definitions.
        #
        # This will return a hash with three keys: "added", "removed",
        # and "modified". These will contain a set of IDs of folders
        # that were added, removed, or modified, respectively.
        #
        # The parameters should be results from the {#synced_folders} call.
        #
        # @return [hash]
        def synced_folders_diff(one, two)
          existing_ids = {}
          one.each do |impl, fs|
            fs.each do |id, data|
              existing_ids[id] = data
            end
          end

          result = Hash.new { |h, k| h[k] = Set.new }
          two.each do |impl, fs|
            fs.each do |id, data|
              existing = existing_ids.delete(id)
              if !existing
                result[:added] << id
                next
              end

              # Exists, so we have to compare the host and guestpath, which
              # is most important...
              if existing[:hostpath] != data[:hostpath] ||
                existing[:guestpath] != data[:guestpath]
                result[:modified] << id
              end
            end
          end

          existing_ids.each do |k, _|
            result[:removed] << k
          end

          result
        end

        protected

        def cached_synced_folders(machine)
          JSON.parse(machine.data_dir.join("synced_folders").read).tap do |r|
            # We have to do all sorts of things to make the proper things
            # symbols and
            r.keys.each do |k|
              r[k].each do |ik, v|
                v.keys.each do |vk|
                  v[vk.to_sym] = v[vk]
                  v.delete(vk)
                end
              end

              r[k.to_sym] = r[k]
              r.delete(k)
            end
          end
        rescue Errno::ENOENT
          # If the file doesn't exist, we probably just have a machine created
          # by a version of Vagrant that didn't cache shared folders. Report no
          # shared folders to be safe.
          return {}
        end
      end
    end
  end
end
