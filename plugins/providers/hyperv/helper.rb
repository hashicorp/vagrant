require "vagrant/util/platform"

module VagrantPlugins
  module HyperV
    class SyncHelper
      WINDOWS_SEPARATOR = "\\"
      UNIX_SEPARATOR = "/"

      def self.expand_excludes(path, exclude)
        excludes = ['.vagrant/']
        excludes += Array(exclude).map(&:to_s) if exclude
        excludes.uniq!

        expanded_path = expand_path(path)
        excluded_dirs = []
        excluded_files = []
        excludes.map do |exclude|
          # Dir.glob accepts Unix style path only
          excluded_path = platform_join expanded_path, exclude, is_windows: false
          Dir.glob(excluded_path) do |e|
            if directory?(e)
              excluded_dirs << e
            else
              excluded_files << e
            end
          end
        end
        {dirs: excluded_dirs,
         files: excluded_files}
      end

      def self.platform_join(string, *smth, is_windows: true)
        joined = [string, *smth].join is_windows ? WINDOWS_SEPARATOR : UNIX_SEPARATOR
        if is_windows
          joined.tr! UNIX_SEPARATOR, WINDOWS_SEPARATOR
        else
          joined.tr! WINDOWS_SEPARATOR, UNIX_SEPARATOR
        end
        joined
      end

      def self.sync_single(machine, ssh_info, opts)
        opts = opts.dup
        opts[:owner] ||= ssh_info[:username]
        opts[:group] ||= ssh_info[:username]
        machine.provider.capability(:sync_folder, opts)
      end

      def self.expand_path(*path)
        # stub for unit test
        File.expand_path(*path)
      end

      def self.directory?(path)
        # stub for unit test
        File.directory? path
      end
    end
  end
end
