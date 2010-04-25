module Vagrant
  module Systems
    # A general Vagrant system implementation for "linux." In general,
    # any linux-based OS will work fine with this system, although its
    # not tested exhaustively. BSD or other based systems may work as
    # well, but that hasn't been tested at all.
    #
    # At any rate, this system implementation should server as an
    # example of how to implement any custom systems necessary.
    class Linux < Base
      #-------------------------------------------------------------------
      # Overridden methods
      #-------------------------------------------------------------------
      def mount_shared_folder(ssh, name, guestpath)
        ssh.exec!("sudo mkdir -p #{guestpath}")
        mount_folder(ssh, name, guestpath)
        ssh.exec!("sudo chown #{vm.env.config.ssh.username} #{guestpath}")
      end

      #-------------------------------------------------------------------
      # "Private" methods which assist above methods
      #-------------------------------------------------------------------
      def mount_folder(ssh, name, guestpath, sleeptime=5)
        # Determine the permission string to attach to the mount command
        perms = []
        perms << "uid=#{vm.env.config.vm.shared_folder_uid}"
        perms << "gid=#{vm.env.config.vm.shared_folder_gid}"
        perms = " -o #{perms.join(",")}" if !perms.empty?

        attempts = 0
        while true
          result = ssh.exec!("sudo mount -t vboxsf#{perms} #{name} #{guestpath}") do |ch, type, data|
            # net/ssh returns the value in ch[:result] (based on looking at source)
            ch[:result] = !!(type == :stderr && data =~ /No such device/i)
          end

          break unless result

          attempts += 1
          raise Actions::ActionException.new(:vm_mount_fail) if attempts >= 10
          sleep sleeptime
        end
      end
    end
  end
end