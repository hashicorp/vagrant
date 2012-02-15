require 'digest/md5'
require 'fileutils'
require 'pathname'

require 'log4r'

module Vagrant
  module Action
    module VM
      # Enables NFS based shared folders. `nfsd` must already be installed
      # on the host machine, and NFS client must already be installed on
      # the guest machine.
      #
      # This is a two part process:
      #
      #   1. Adds an entry to `/etc/exports` on the host machine using
      #      the host class to export the proper folder to the proper
      #      machine.
      #   2. After boot, runs `mount` on the guest to mount the shared
      #      folder.
      #
      class NFS
        def initialize(app,env)
          @logger = Log4r::Logger.new("vagrant::action::vm::nfs")
          @app = app
          @env = env

          verify_settings if nfs_enabled?
        end

        def call(env)
          @env = env

          extract_folders

          if !folders.empty?
            prepare_folders
            export_folders
          end

          @app.call(env)

          mount_folders if !folders.empty?
        end

        # Returns the folders which are to be synced via NFS.
        def folders
          @folders ||= {}
        end

        # Removes the NFS enabled shared folders from the configuration,
        # so they will no longer be mounted by the actual shared folder
        # task.
        def extract_folders
          # Load the NFS enabled shared folders
          @folders = {}
          @env[:vm].config.vm.shared_folders.each do |key, opts|
            if opts[:nfs]
              # Duplicate the options, set the hostpath, and set disabled on the original
              # options so the ShareFolders middleware doesn't try to mount it.
              folder = opts.dup
              hostpath = Pathname.new(opts[:hostpath]).expand_path(@env[:root_path])

              if !hostpath.directory? && opts[:create]
                # Host path doesn't exist, so let's create it.
                @logger.debug("Host path doesn't exist, creating: #{hostpath}")

                begin
                  FileUtils.mkpath(hostpath)
                rescue Errno::EACCES
                  raise Errors::SharedFolderCreateFailed, :path => hostpath.to_s
                end
              end

              # Set the hostpath now that it exists.
              folder[:hostpath] = hostpath.to_s

              # Assign the folder to our instance variable for later use
              @folders[key] = folder

              # Disable the folder so that regular shared folders don't try to
              # mount it.
              opts[:disabled] = true
            end
          end
        end

        # Prepares the settings for the NFS folders, such as setting the
        # options on the NFS folders.
        def prepare_folders
          @folders = @folders.inject({}) do |acc, data|
            key, opts = data
            opts[:map_uid] = prepare_permission(:uid, opts)
            opts[:map_gid] = prepare_permission(:gid, opts)
            opts[:nfs_version] ||= 3

            # The poor man's UUID. An MD5 hash here is sufficient since
            # we need a 32 character "uuid" to represent the filesystem
            # of an export. Hashing the host path is safe because two of
            # the same host path will hash to the same fsid.
            opts[:uuid]    = Digest::MD5.hexdigest(opts[:hostpath])

            acc[key] = opts
            acc
          end
        end

        # Prepares the UID/GID settings for a single folder.
        def prepare_permission(perm, opts)
          key = "map_#{perm}".to_sym
          return nil if opts.has_key?(key) && opts[key].nil?

          # The options on the hash get priority, then the default
          # values
          value = opts.has_key?(key) ? opts[key] : @env[:vm].config.nfs.send(key)
          return value if value != :auto

          # Get UID/GID from folder if we've made it this far
          # (value == :auto)
          stat = File.stat(opts[:hostpath])
          return stat.send(perm)
        end

        # Uses the host class to export the folders via NFS. This typically
        # involves adding a line to `/etc/exports` for this VM, but it is
        # up to the host class to define the specific behavior.
        def export_folders
          @env[:ui].info I18n.t("vagrant.actions.vm.nfs.exporting")
          @env[:host].nfs_export(@env[:vm].uuid, guest_ip, folders)
        end

        # Uses the system class to mount the NFS folders.
        def mount_folders
          @env[:ui].info I18n.t("vagrant.actions.vm.nfs.mounting")

          # Only mount the folders which have a guest path specified
          mount_folders = {}
          folders.each do |name, opts|
            if opts[:guestpath]
              mount_folders[name] = opts.dup
            end
          end

          @env[:vm].guest.mount_nfs(host_ip, mount_folders)
        end

        # Returns the IP address of the first host only network adapter
        #
        # @return [String]
        def host_ip
          @env[:vm].driver.read_network_interfaces.each do |adapter, opts|
            if opts[:type] == :hostonly
              @env[:vm].driver.read_host_only_interfaces.each do |interface|
                if interface[:name] == opts[:hostonly]
                  return interface[:ip]
                end
              end
            end
          end

          nil
        end

        # Returns the IP address of the guest by looking at the first
        # enabled host only network.
        #
        # @return [String]
        def guest_ip
          @env[:vm].config.vm.networks.each do |type, args|
            if type == :hostonly && args[0].is_a?(String)
              return args[0]
            end
          end

          nil
        end

        # Checks if there are any NFS enabled shared folders.
        def nfs_enabled?
          @env[:vm].config.vm.shared_folders.each do |key, opts|
            return true if opts[:nfs]
          end

          false
        end

        # Verifies that the host is set and supports NFS.
        def verify_settings
          raise Errors::NFSHostRequired if @env[:host].nil?
          raise Errors::NFSNotSupported if !@env[:host].nfs?
          raise Errors::NFSNoHostNetwork if !guest_ip
        end
      end
    end
  end
end
