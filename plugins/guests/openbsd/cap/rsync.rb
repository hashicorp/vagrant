require_relative "../../../synced_folders/rsync/default_unix_cap"

module VagrantPlugins
  module GuestOpenBSD
    module Cap
      class RSync
        extend VagrantPlugins::SyncedFolderRSync::DefaultUnixCap

        def self.rsync_install(machine)
          install_output = {:stderr => '', :stdout => ''}
          command = 'PKG_PATH="http://ftp.openbsd.org/pub/OpenBSD/' \
            '`uname -r`/packages/`arch -s`/" ' \
            'pkg_add -I rsync--'
          machine.communicate.sudo(command) do |type, data|
            install_output[type] << data if install_output.key?(type)
          end
          # pkg_add returns 0 even if package was not found, so
          # validate package is actually installed
          machine.communicate.sudo('pkg_info -cA | grep inst:rsync-[[:digit:]]',
            error_class: Vagrant::Errors::RSyncNotInstalledInGuest,
            command: command,
            stderr: install_output[:stderr],
            stdout: install_output[:stdout]
          )
        end
      end
    end
  end
end
