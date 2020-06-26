module VagrantPlugins
  module ProviderVirtualBox
    module Model
      # A collection of storage controllers. Includes finder methods to look
      # up a storage controller by given attributes.
      class StorageControllerArray < Array
        # Get a single controller matching the given options.
        #
        # @param [Hash] opts - A hash of attributes to match.
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
        def get_controller!(opts = {})
          controller = get_controller(opts)
          if controller.nil?
            raise Vagrant::Errors::VirtualBoxDisksControllerNotFound, name: opts[:name]
          end
          controller
        end

        # Find the controller containing the primary disk (i.e. the boot disk).
        def get_primary_controller
          primary = nil

          if length == 1
            primary = first
          else
            ide_controller = get_controller(storage_bus: "IDE")
            if ide_controller && ide_controller.attachments.any? { |a| hdd?(a) }
              primary = ide_controller
            else
              primary = get_controller!(storage_bus: "SATA")
            end
          end

          primary
        end

        private

        def hdd?(attachment)
          ext = File.extname(attachment[:location])
          # TODO: hook into ValidateDiskExt capability
          [".vdi", ".vmdk", ".vhd"].include?(ext)
        end
      end
    end
  end
end
