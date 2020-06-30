module VagrantPlugins
  module ProviderVirtualBox
    module Model
      # A collection of storage controllers. Includes finder methods to look
      # up a storage controller by given attributes.
      class StorageControllerArray < Array
        SATA_TYPE = "SATA".freeze
        IDE_TYPE = "IDE".freeze
        SUPPORTED_TYPES = [SATA_TYPE, IDE_TYPE].freeze

        # TODO: hook into ValidateDiskExt capability
        DEFAULT_DISK_EXT = [".vdi", ".vmdk", ".vhd"].map(&:freeze).freeze

        # Get a single controller matching the given options.
        #
        # @param [Hash] opts - A hash of attributes to match.
        # @return [VagrantPlugins::ProviderVirtualBox::Model::StorageController]
        def get_controller(opts = {})
          if opts[:name]
            detect { |c| c.name == opts[:name] }
          elsif opts[:storage_bus]
            detect { |c| c.storage_bus == opts[:storage_bus] }
          end
        end

        # Get a single controller matching the given options. Raise an
        # exception if a matching controller can't be found.
        #
        # @param [Hash] opts - A hash of attributes to match.
        # @return [VagrantPlugins::ProviderVirtualBox::Model::StorageController]
        def get_controller!(opts = {})
          controller = get_controller(opts)
          if !controller && opts[:name]
            raise Vagrant::Errors::VirtualBoxDisksControllerNotFound, name: opts[:name]
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

          if !types.any? { |t| SUPPORTED_TYPES.include?(t) }
            raise Vagrant::Errors::VirtualBoxDisksNoSupportedControllers, supported_types: SUPPORTED_TYPES
          end

          ide_controller = get_controller(storage_bus: IDE_TYPE)
          if ide_controller && ide_controller.attachments.any? { |a| hdd?(a) }
            controller = ide_controller
          else
            controller = get_controller(storage_bus: SATA_TYPE)
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
          controller = nil

          if types.include?(IDE_TYPE)
            controller = get_controller(storage_bus: IDE_TYPE)
          elsif types.include?(SATA_TYPE)
            controller = get_controller(storage_bus: SATA_TYPE)
          else
            raise Vagrant::Errors::VirtualBoxDisksNoSupportedControllers, supported_types: SUPPORTED_TYPES
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

        # List of storage controller types.
        #
        # @return [Array<String>] types
        def types
          map { |c| c.storage_bus }
        end
      end
    end
  end
end
