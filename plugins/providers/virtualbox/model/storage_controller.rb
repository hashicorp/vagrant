module VagrantPlugins
  module ProviderVirtualBox
    module Model
      # Represents a storage controller for VirtualBox. Storage controllers
      # have a type, a name, and can have hard disks or optical attached.
      class StorageController

        SATA_CONTROLLER_TYPES = ["IntelAhci"].freeze
        IDE_CONTROLLER_TYPES = ["PIIX4", "PIIX3", "ICH6"].freeze

        # The name of the storage controller.
        #
        # @return [String]
        attr_reader :name

        # The specific type of controller.
        #
        # @return [String]
        attr_reader :type

        # The maximum number of avilable ports for the storage controller. For
        # SATA controllers, this indicates the number of disks that can be
        # attached. For IDE controllers, this indicates that n*2 disks can be
        # attached (primary/secondary).
        #
        # @return [Integer]
        attr_reader :maxportcount

        # The list of disks/ISOs attached to each storage controller.
        #
        # @return [Array<Hash>]
        attr_reader :attachments

        def initialize(name, type, maxportcount, attachments)
          @name         = name
          @type         = type
          @maxportcount = maxportcount.to_i

          attachments ||= []
          @attachments  = attachments
        end

        def sata_controller?
          SATA_CONTROLLER_TYPES.include?(@type)
        end

        def ide_controller?
          IDE_CONTROLLER_TYPES.include?(@type)
        end
      end
    end
  end
end
