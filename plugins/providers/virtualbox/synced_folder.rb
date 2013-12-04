require "vagrant/util/platform"

module VagrantPlugins
  module ProviderVirtualBox
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      def usable?(machine)
        # These synced folders only work if the provider if VirtualBox
        machine.provider_name == :virtualbox
      end

      def prepare(machine, folders, _opts)
        defs = []
        folders.each do |id, data|
          hostpath = Vagrant::Util::Platform.cygwin_windows_path(data[:hostpath])

          defs << {
            name: id,
            hostpath: hostpath.to_s,
            transient: data[:transient],
          }
        end

        driver(machine).share_folders(defs)
      end

      def enable(machine, folders, _opts)
        # short guestpaths first, so we don't step on ourselves
        folders = folders.sort_by do |id, data|
          if data[:guestpath]
            data[:guestpath].length
          else
            # A long enough path to just do this at the end.
            10000
          end
        end

        # Go through each folder and mount
        machine.ui.info(I18n.t("vagrant.actions.vm.share_folders.mounting"))
        folders.each do |id, data|
          if data[:guestpath]
            # Guest path specified, so mount the folder to specified point
            machine.ui.info(I18n.t("vagrant.actions.vm.share_folders.mounting_entry",
                                  :guest_path => data[:guestpath]))

            # Dup the data so we can pass it to the guest API
            data = data.dup

            # Calculate the owner and group
            ssh_info = machine.ssh_info
            data[:owner] ||= ssh_info[:username]
            data[:group] ||= ssh_info[:username]

            # Mount the actual folder
            machine.guest.capability(
              :mount_virtualbox_shared_folder, id, data[:guestpath], data)
          else
            # If no guest path is specified, then automounting is disabled
            machine.ui.info(I18n.t("vagrant.actions.vm.share_folders.nomount_entry",
                                  :host_path => data[:hostpath]))
          end
        end
      end

      def cleanup(machine)
        driver.clear_shared_folders
      end

      protected

      # This is here so that we can stub it for tests
      def driver(machine)
        machine.provider.driver
      end
    end
  end
end
