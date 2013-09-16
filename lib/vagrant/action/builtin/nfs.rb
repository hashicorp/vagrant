require 'fileutils'
require 'pathname'
require 'zlib'

require "log4r"

require 'vagrant/util/platform'

module Vagrant
  module Action
    module Builtin
      # This built-in middleware exports and mounts NFS shared folders.
      #
      # To use this middleware, two configuration parameters must be given
      # via the environment hash:
      #
      #   - `:nfs_host_ip` - The IP of where to mount the NFS folder from.
      #   - `:nfs_machine_ip` - The IP of the machine where the NFS folder
      #     will be mounted.
      #
      class NFS
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::nfs")
        end

        def call(env)
          # We forward things along first. We do everything on the tail
          # end of the middleware call.
          @app.call(env)

          # Used by prepare_permission, so we need to save it
          @env = env

          folders = {}
          env[:machine].config.vm.synced_folders.each do |id, opts|
            # If this synced folder doesn't enable NFS, ignore it.
            next if !opts[:nfs]

            # Expand the host path, create it if we have to and
            # store away the folder.
            hostpath = Pathname.new(opts[:hostpath]).
              expand_path(env[:root_path])

            if !hostpath.directory? && opts[:create]
              # Host path doesn't exist, so let's create it.
              @logger.debug("Host path doesn't exist, creating: #{hostpath}")

              begin
                FileUtils.mkpath(hostpath)
              rescue Errno::EACCES
                raise Vagrant::Errors::SharedFolderCreateFailed,
                  :path => hostpath.to_s
              end
            end

            # Determine the real path by expanding symlinks and getting
            # proper casing. We have to do this after creating it
            # if it doesn't exist.
            hostpath = hostpath.realpath
            hostpath = Util::Platform.fs_real_path(hostpath)

            # Set the hostpath back on the options and save it
            opts[:hostpath] = hostpath.to_s
            folders[id] = opts
          end

          if !folders.empty?
            raise Errors::NFSNoHostIP if !env[:nfs_host_ip]
            raise Errors::NFSNoGuestIP if !env[:nfs_machine_ip]

            machine_ip = env[:nfs_machine_ip]
            machine_ip = [machine_ip] if !machine_ip.is_a?(Array)

            # Prepare the folder, this means setting up various options
            # and such on the folder itself.
            folders.each { |id, opts| prepare_folder(opts) }

            # Export the folders
            env[:ui].info I18n.t("vagrant.actions.vm.nfs.exporting")
            env[:host].nfs_export(env[:machine].id, machine_ip, folders)

            # Mount
            env[:ui].info I18n.t("vagrant.actions.vm.nfs.mounting")

            # Only mount folders that have a guest path specified.
            mount_folders = {}
            folders.each do |id, opts|
              mount_folders[id] = opts.dup if opts[:guestpath]
            end

            # Mount them!
            env[:machine].guest.capability(
              :mount_nfs_folder, env[:nfs_host_ip], mount_folders)
          end
        end

        protected

        def prepare_folder(opts)
          opts[:map_uid] = prepare_permission(:uid, opts)
          opts[:map_gid] = prepare_permission(:gid, opts)
          opts[:nfs_version] ||= 3

          # We use a CRC32 to generate a 32-bit checksum so that the
          # fsid is compatible with both old and new kernels.
          opts[:uuid] = Zlib.crc32(opts[:hostpath]).to_s
        end

        # Prepares the UID/GID settings for a single folder.
        def prepare_permission(perm, opts)
          key = "map_#{perm}".to_sym
          return nil if opts.has_key?(key) && opts[key].nil?

          # The options on the hash get priority, then the default
          # values
          value = opts.has_key?(key) ? opts[key] : @env[:machine].config.nfs.send(key)
          return value if value != :auto

          # Get UID/GID from folder if we've made it this far
          # (value == :auto)
          stat = File.stat(opts[:hostpath])
          return stat.send(perm)
        end
      end
    end
  end
end
