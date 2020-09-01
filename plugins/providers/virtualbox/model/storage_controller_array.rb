require_relative "../cap/validate_disk_ext"

module VagrantPlugins
  module ProviderVirtualBox
    module Model
      # A collection of storage controllers. Includes finder methods to look
      # up a storage controller by given attributes.
      class StorageControllerArray < Array
        # Returns a storage controller with the given name. Raises an
        # exception if a matching controller can't be found.
        #
        # @param [String] name - The name of the storage controller
        # @return [VagrantPlugins::ProviderVirtualBox::Model::StorageController]
        def get_controller(name)
          controller = detect { |c| c.name == name }
          if !controller
            raise Vagrant::Errors::VirtualBoxDisksControllerNotFound, name: name
          end
          controller
        end

        # Find the controller containing the primary disk (i.e. the boot
        # disk). This is used to determine which controller virtual disks
        # should be attached to.
        #
        # Raises an exception if no supported controllers are found.
        #
        # @return [VagrantPlugins::ProviderVirtualBox::Model::StorageController]
        def get_primary_controller
          ordered = find_all(&:supported?).sort_by(&:boot_priority)
          controller = ordered.detect { |c| c.attachments.any? { |a| hdd?(a) } }

          if !controller
            raise Vagrant::Errors::VirtualBoxDisksNoSupportedControllers,
              supported_types: supported_types.join(" ,")
          end

          controller
        end

        # Find the attachment representing the primary disk (i.e. the boot
        # disk). We can't rely on the order of #list_hdds, as they will not
        # always come in port order, but primary is always Port 0 Device 0.
        #
        # @return [Hash] attachment - Primary disk attachment information
        def get_primary_attachment
          attachment = nil

          controller = get_primary_controller
          attachment = controller.get_attachment(port: "0", device: "0")
          if !attachment
            raise Vagrant::Errors::VirtualBoxDisksPrimaryNotFound
          end

          attachment
        end

        # Returns the first supported storage controller for attaching dvds.
        # Will raise an exception if no suitable controller can be found.
        #
        # @return [VagrantPlugins::ProviderVirtualBox::Model::StorageController]
        def get_dvd_controller
          ordered = find_all(&:supported?).sort_by(&:boot_priority)
          controller = ordered.first
          if !controller
            raise Vagrant::Errors::VirtualBoxDisksNoSupportedControllers,
              supported_types: supported_types.join(" ,")
          end

          controller
        end

        private

        # Determine whether the given attachment is a hard disk.
        #
        # @param [Hash] attachment - Attachment information
        # @return [Boolean]
        def hdd?(attachment)
          if !attachment
            false
          else
            ext = File.extname(attachment[:location].to_s).downcase.split('.').last
            VagrantPlugins::ProviderVirtualBox::Cap::ValidateDiskExt.validate_disk_ext(nil, ext)
          end
        end

        # Returns a list of all the supported controller types.
        #
        # @return [Array<String>]
        def supported_types
          StorageController::SATA_CONTROLLER_TYPES + StorageController::IDE_CONTROLLER_TYPES +
            StorageController::SCSI_CONTROLLER_TYPES
        end
      end
    end
  end
end
