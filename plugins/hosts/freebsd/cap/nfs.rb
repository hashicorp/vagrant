require 'vagrant/util'
require 'vagrant/util/retryable'

require Vagrant.source_root.join('plugins', 'hosts', 'bsd', 'cap', 'nfs')

module VagrantPlugins
  module HostFreeBSD
    module Cap
      class NFS
        def self.nfs_export(environment, ui, id, ips, folders)
          folders.each do |_folder_name, folder_values|
            if folder_values[:hostpath] =~ /\s+/
              fail Vagrant::Errors::VagrantError,
                   _key: :freebsd_nfs_whitespace
            end
          end

          HostBSD::Cap::NFS.nfs_export(environment, ui, id, ips, folders)
        end

        def self.nfs_exports_template(_environment)
          'nfs/exports_freebsd'
        end

        def self.nfs_restart_command(_environment)
          ['sudo', '/etc/rc.d/mountd', 'onereload']
        end
      end
    end
  end
end
