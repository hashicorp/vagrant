module VagrantPlugins
  module ProviderVirtualBox
    module Model
      # Represents a storage controller for VirtualBox. Storage controllers
      # have a type, a name, and can have hard disks or optical drives attached.
      class StorageController
        IDE_CONTROLLER_TYPES = ["PIIX4", "PIIX3", "ICH6"].map(&:freeze).freeze
        SATA_CONTROLLER_TYPES = ["IntelAhci"].map(&:freeze).freeze
        SCSI_CONTROLLER_TYPES = [ "LsiLogic", "BusLogic"].map(&:freeze).freeze

        IDE_DEVICES_PER_PORT = 2.freeze
        SATA_DEVICES_PER_PORT = 1.freeze
        SCSI_DEVICES_PER_PORT = 1.freeze

        IDE_BOOT_PRIORITY = 1.freeze
        SATA_BOOT_PRIORITY = 2.freeze
        SCSI_BOOT_PRIORITY = 3.freeze

        # The name of the storage controller.
        #
        # @return [String]
        attr_reader :name

        # The specific type of controller.
        #
        # @return [String]
        attr_reader :type

        # The maximum number of avilable ports for the storage controller.
        #
        # @return [Integer]
        attr_reader :maxportcount

        # The number of devices that can be attached to each port. For SATA
        # controllers, this will usually be 1, and for IDE controllers this
        # will usually be 2.
        # @return [Integer]
        attr_reader :devices_per_port

        # The maximum number of individual disks that can be attached to the
        # storage controller. For SATA controllers, this equals the maximum
        # number of ports. For IDE controllers, this will be twice the max
        # number of ports (primary/secondary).
        #
        # @return [Integer]
        attr_reader :limit

        # The boot priority of the storage controller. This does not seem to
        # depend on the controller number returned by `showvminfo`.
        # Experimentation has determined that VirtualBox will try to boot from
        # the first controller it finds with a hard disk, in this order:
        #   IDE, SATA, SCSI
        #
        # @return [Integer]
        attr_reader :boot_priority

        # The list of disks/ISOs attached to each storage controller.
        #
        # @return [Array<Hash>]
        attr_reader :attachments

        def initialize(name, type, maxportcount, attachments)
          @name = name
          @type = type

          @maxportcount = maxportcount.to_i

          if IDE_CONTROLLER_TYPES.include?(@type)
            @storage_bus = :ide
            @devices_per_port = IDE_DEVICES_PER_PORT
            @boot_priority = IDE_BOOT_PRIORITY
          elsif SATA_CONTROLLER_TYPES.include?(@type)
            @storage_bus = :sata
            @devices_per_port = SATA_DEVICES_PER_PORT
            @boot_priority = SATA_BOOT_PRIORITY
          elsif SCSI_CONTROLLER_TYPES.include?(@type)
            @storage_bus = :scsi
            @devices_per_port = SCSI_DEVICES_PER_PORT
            @boot_priority = SCSI_BOOT_PRIORITY
          else
            @storage_bus = :unknown
            @devices_per_port = 1
          end

          @limit = @maxportcount * @devices_per_port

          attachments ||= []
          @attachments = attachments
        end

        # Get a single storage device, either by port/device address or by
        # UUID.
        #
        # @param [Hash] opts - A hash of options to match
        # @return [Hash] attachment - Attachment information
        def get_attachment(opts = {})
          if opts[:port] && opts[:device]
            @attachments.detect { |a| a[:port] == opts[:port] &&
                                      a[:device] == opts[:device] }
          elsif opts[:uuid]
            @attachments.detect { |a| a[:uuid] == opts[:uuid] }
          end
        end

        # Returns true if the storage controller has a supported type.
        #
        # @return [Boolean]
        def supported?
          [:ide, :sata, :scsi].include?(@storage_bus)
        end

        # Returns true if the storage controller is a IDE type controller.
        #
        # @return [Boolean]
        def ide?
          @storage_bus == :ide
        end

        # Returns true if the storage controller is a SATA type controller.
        #
        # @return [Boolean]
        def sata?
          @storage_bus == :sata
        end

        # Returns true if the storage controller is a SCSI type controller.
        #
        # @return [Boolean]
        def scsi?
          @storage_bus == :scsi
        end
      end
    end
  end
end
