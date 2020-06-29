module VagrantPlugins
  module ProviderVirtualBox
    module Model
      # A collection of storage controllers. Includes finder methods to look
      # up a storage controller by given attributes.
      class StorageControllerArray < Array
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
          if controller.nil?
            raise Vagrant::Errors::VirtualBoxDisksControllerNotFound, name: opts[:name]
          end
          controller
        end

        # Find the controller containing the primary disk (i.e. the boot
        # disk). This is used to determine which controller virtual disks
        # should be attached to.
        #
        # @return [VagrantPlugins::ProviderVirtualBox::Model::StorageController]
        def get_primary_controller
          controller = nil

          if length == 1
            controller = first
          else
            ide_controller = get_controller(storage_bus: "IDE")
            if ide_controller && ide_controller.attachments.any? { |a| hdd?(a) }
              controller = ide_controller
            else
              controller = get_controller!(storage_bus: "SATA")
            end
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

        private

        # Determine whether the given attachment is a hard disk.
        #
        # @param [Hash] attachment - Attachment information
        # @return [Boolean]
        def hdd?(attachment)
          ext = File.extname(attachment[:location].to_s).downcase
          # TODO: hook into ValidateDiskExt capability
          [".vdi", ".vmdk", ".vhd"].include?(ext)
        end
      end
    end
  end
end
