require "fileutils"
require "vagrant/util/platform"

require_relative 'sync_helper'

module VagrantPlugins
  module HyperV
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      def usable?(machine, raise_errors=false)
        # These synced folders only work if the provider if VirtualBox
        return false if machine.provider_name != :hyperv

        true
      end

      def prepare(machine, folders, _opts)
        # Nothing is necessary to do before VM boot.
      end

      def enable(machine, folders, _opts)
        machine.ui.warn I18n.t("vagrant_hyperv.share_folders.no_daemons") unless configure_hv_daemons(machine)

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
        machine.ui.output(I18n.t("vagrant_hyperv.share_folders.syncing"))
        folders.each do |id, data|
          if data[:guestpath]
            # Guest path specified, so sync the folder to specified point
            machine.ui.detail(I18n.t("vagrant_hyperv.share_folders.syncing_entry",
                                     guestpath: data[:guestpath],
                                     hostpath: data[:hostpath]))

            # Dup the data so we can pass it to the guest API
            SyncHelper.sync_single machine, machine.ssh_info, data.dup
          else
            # If no guest path is specified, then automounting is disabled
            machine.ui.detail(I18n.t("vagrant_hyperv.share_folders.nosync_entry",
                                     hostpath: data[:hostpath]))
          end
        end
      end

      def disable(machine, folders, _opts) end

      def cleanup(machine, opts) end

      protected

      def configure_hv_daemons(machine)
        return false unless machine.guest.capability?(:hyperv_daemons_running)

        unless machine.guest.capability(:hyperv_daemons_running)
          installed = machine.guest.capability(:hyperv_daemons_installed)
          unless installed
            can_install = machine.guest.capability?(:hyperv_daemons_install)
            unless can_install
              machine.ui.warn I18n.t("vagrant_hyperv.daemons.unable_to_install")
              return false
            end

            machine.ui.info I18n.t("vagrant_hyperv.daemons.installing")
            machine.guest.capability(:hyperv_daemons_install)
          end

          can_activate = machine.guest.capability?(:hyperv_daemons_activate)
          unless can_activate
            machine.ui.warn I18n.t("vagrant_hyperv.daemons.unable_to_activate")
            return false
          end

          machine.ui.info I18n.t("vagrant_hyperv.daemons.activating")
          activated = machine.guest.capability(:hyperv_daemons_activate)
          unless activated
            machine.ui.warn I18n.t("vagrant_hyperv.daemons.activation_failed")
            return false
          end
        end
        true
      end

      # This is here so that we can stub it for tests
      def driver(machine)
        machine.provider.driver
      end
    end
  end
end
