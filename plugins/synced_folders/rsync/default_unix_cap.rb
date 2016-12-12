require "shellwords"

module VagrantPlugins
  module SyncedFolderRSync
    # This module provides default rsync capabilities for
    # unix type operating systems.
    module DefaultUnixCap

      def rsync_installed(machine)
        machine.communicate.test("which rsync")
      end

      def rsync_command(machine)
        "sudo rsync"
      end

      def rsync_pre(machine, opts)
        guest_path = Shellwords.escape(opts[:guestpath])
        machine.communicate.sudo("mkdir -p #{guest_path}")
      end

      def rsync_post(machine, opts)
        if opts.key?(:chown) && !opts[:chown]
          return
        end
        machine.communicate.sudo(build_rsync_chown(opts))
      end

      def build_rsync_chown(opts)
        guest_path = Shellwords.escape(opts[:guestpath])
        if(opts[:exclude])
          exclude_base = Pathname.new(opts[:guestpath])
          exclusions = Array(opts[:exclude]).map do |ex_path|
            ex_path = ex_path.slice(1, ex_path.size) if ex_path.start_with?(File::SEPARATOR)
            "-path #{Shellwords.escape(exclude_base.join(ex_path))} -prune"
          end.join(" -o ") + " -o "
        end
        "find #{guest_path} #{exclusions}" \
          "'!' -type l -a " \
          "'(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -exec " \
          "chown #{opts[:owner]}:#{opts[:group]} '{}' +"
      end
    end
  end
end
