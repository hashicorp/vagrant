require "json"
require "set"

module Vagrant
  module Action
    module Builtin
      module MixinSyncedFolders

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
            existing = machine.synced_folders(cached: true)
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

          folder_data = JSON.dump(folders)

          # Scrub any register credentials from the synced folders
          # configuration data to prevent accidental leakage
          folder_data = Util::CredentialScrubber.desensitize(folder_data)

          machine.data_dir.join("synced_folders").open("w") do |f|
            f.write(folder_data)
          end
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
      end
    end
  end
end
