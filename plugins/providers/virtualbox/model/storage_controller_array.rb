module VagrantPlugins
  module ProviderVirtualBox
    module Model
      # A collection of storage controllers. Includes finder methods to look
      # up a storage controller by given attributes.
      class StorageControllerArray < Array
        # TODO: hook into ValidateDiskExt capability
        DEFAULT_DISK_EXT = [".vdi", ".vmdk", ".vhd"].map(&:freeze).freeze

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
          controller = nil

          ide_controller = detect { |c| c.ide? }
          if ide_controller && ide_controller.attachments.any? { |a| hdd?(a) }
            controller = ide_controller
          else
            controller = detect { |c| c.sata? }
          end

          if !controller
            supported_types = StorageController::SATA_CONTROLLER_TYPES + StorageController::IDE_CONTROLLER_TYPES
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

        # Find a suitable storage controller for attaching dvds. Will raise an
        # exception if no suitable controller can be found.
        #
        # @return [VagrantPlugins::ProviderVirtualBox::Model::StorageController]
        def get_dvd_controller
          controller = detect { |c| c.ide? } || detect { |c| c.sata? }

          if !controller
            supported_types = StorageController::SATA_CONTROLLER_TYPES + StorageController::IDE_CONTROLLER_TYPES
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
          ext = File.extname(attachment[:location].to_s).downcase
          DEFAULT_DISK_EXT.include?(ext)
        end
      end
    end
  end
end
