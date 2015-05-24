require "vagrant/util/retryable"
require "shellwords"

module VagrantPlugins
  module GuestDarwin
    module Cap
      class MountSMBSharedFolder
        extend Vagrant::Util::Retryable
        def self.mount_smb_shared_folder(machine, name, guestpath, options)
          expanded_guest_path = machine.guest.capability(:shell_expand_guest_path, guestpath)
          machine.communicate.execute("mkdir -p #{expanded_guest_path}")

          smb_password = Shellwords.shellescape(options[:smb_password])
          mount_options = options[:mount_options];

          mount_command = "mount -t smbfs " +
            (mount_options ? "-o '#{mount_options.join(",")}' " : "") +
            "'//#{options[:smb_username]}:#{smb_password}@#{options[:smb_host]}/#{name}' " +
            "#{expanded_guest_path}"
          retryable(on: Vagrant::Errors::DarwinMountFailed, tries: 10, sleep: 5) do 
            machine.communicate.execute(
              mount_command,
              error_class: Vagrant::Errors::DarwinMountFailed)
          end
        end
      end
    end
  end
end
