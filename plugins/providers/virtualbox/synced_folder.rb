require "vagrant/util/platform"

module VagrantPlugins
  module ProviderVirtualBox
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      def usable?(machine, raise_errors=false)
        # These synced folders only work if the provider if VirtualBox
        return false if machine.provider_name != :virtualbox

        # This only happens with `vagrant package --base`. Sigh.
        return true if !machine.provider_config

        machine.provider_config.functional_vboxsf
      end

      def prepare(machine, folders, _opts)
        share_folders(machine, folders, false)
      end

      def enable(machine, folders, _opts)
        share_folders(machine, folders, true)

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
        machine.ui.output(I18n.t("vagrant.actions.vm.share_folders.mounting"))
        folders.each do |id, data|
          if data[:guestpath]
            # Guest path specified, so mount the folder to specified point
            machine.ui.detail(I18n.t("vagrant.actions.vm.share_folders.mounting_entry",
                                  guestpath: data[:guestpath],
                                  hostpath: data[:hostpath]))

            # Dup the data so we can pass it to the guest API
            data = data.dup

            # Calculate the owner and group
            ssh_info = machine.ssh_info
            data[:owner] ||= ssh_info[:username]
            data[:group] ||= ssh_info[:username]

            # Mount the actual folder
            machine.guest.capability(
              :mount_virtualbox_shared_folder,
              os_friendly_id(id), data[:guestpath], data)
          else
            # If no guest path is specified, then automounting is disabled
            machine.ui.detail(I18n.t("vagrant.actions.vm.share_folders.nomount_entry",
                                  hostpath: data[:hostpath]))
          end
        end
      end

      def disable(machine, folders, _opts)
        if machine.guest.capability?(:unmount_virtualbox_shared_folder)
          folders.each do |id, data|
            machine.guest.capability(
              :unmount_virtualbox_shared_folder,
              data[:guestpath], data)
          end
        end

        # Remove the shared folders from the VM metadata
        names = folders.map { |id, _data| os_friendly_id(id) }
        driver(machine).unshare_folders(names)
      end

      def cleanup(machine, opts)
        driver(machine).clear_shared_folders if machine.id && machine.id != ""
      end

      protected

      # This is here so that we can stub it for tests
      def driver(machine)
        machine.provider.driver
      end

      def os_friendly_id(id)
        id.gsub(/[\/]/,'_').sub(/^_/, '')
      end

      # share_folders sets up the shared folder definitions on the
      # VirtualBox VM.
      #
      # The transient parameter determines if we're FORCING transient
      # or not. If this is false, then any shared folders will be
      # shared as non-transient unless they've specifically asked for
      # transient.
      def share_folders(machine, folders, transient)
        defs = []
        folders.each do |id, data|
          hostpath = data[:hostpath]
          if !data[:hostpath_exact]
            hostpath = Vagrant::Util::Platform.cygwin_windows_path(hostpath)
          end

          # Only setup the shared folders that match our transient level
          if (!!data[:transient]) == transient
            defs << {
              name: os_friendly_id(id),
              hostpath: hostpath.to_s,
              transient: transient,
            }
          end
        end

        driver(machine).share_folders(defs)
      end
    end
  end
end
