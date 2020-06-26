module VagrantPlugins
  module ProviderVirtualBox
    module Model
      # Represents a storage controller for VirtualBox. Storage controllers
      # have a type, a name, and can have hard disks or optical drives attached.
      class StorageController
        SATA_CONTROLLER_TYPES = ["IntelAhci"].map(&:freeze).freeze
        IDE_CONTROLLER_TYPES = ["PIIX4", "PIIX3", "ICH6"].map(&:freeze).freeze

        # The name of the storage controller.
        #
        # @return [String]
        attr_reader :name

        # The specific type of controller.
        #
        # @return [String]
        attr_reader :type

        # The storage bus associated with the storage controller, which can be
        # inferred from its specific type.
        #
        # @return [String]
        attr_reader :storage_bus

        # The maximum number of avilable ports for the storage controller.
        #
        # @return [Integer]
        attr_reader :maxportcount

        # The maximum number of individual disks that can be attached to the
        # storage controller. For SATA controllers, this equals the maximum
        # number of ports. For IDE controllers, this will be twice the max
        # number of ports (primary/secondary).
        #
        # @return [Integer]
        attr_reader :limit

        # The list of disks/ISOs attached to each storage controller.
        #
        # @return [Array<Hash>]
        attr_reader :attachments

        def initialize(name, type, maxportcount, attachments)
          @name = name
          @type = type

          if SATA_CONTROLLER_TYPES.include?(@type)
            @storage_bus = "SATA"
          elsif IDE_CONTROLLER_TYPES.include?(@type)
            @storage_bus = "IDE"
          else
            @storage_bus = "Unknown"
          end

          @maxportcount = maxportcount.to_i
          if @storage_bus == "IDE"
            @limit = @maxportcount * 2
          else
            @limit = @maxportcount
          end

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
      end
    end
  end
end
