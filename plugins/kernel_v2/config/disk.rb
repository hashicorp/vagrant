require "log4r"
require "securerandom"

module VagrantPlugins
  module Kernel_V2
    class VagrantConfigDisk < Vagrant.plugin("2", :config)
      #-------------------------------------------------------------------
      # Config class for a given Disk
      #-------------------------------------------------------------------

      DEFAULT_DISK_TYPES = [:disk, :dvd, :floppy].freeze

      # Note: This value is for internal use only
      #
      # @return [String]
      attr_reader :id

      # File name for the given disk. Defaults to nil.
      #
      # TODO: Should probably default to a string+short integer id in the finalize method
      #
      # Sometihng like:
      #
      # - `vagrant_short_id`
      #
      # Where short_id is calculated from the disks ID
      #
      # Finalize method in `Config#VM` might need to ensure there aren't colliding disk names?
      # It might also depend on the provider
      #
      # @return [String]
      attr_accessor :name

      # Type of disk to create. Defaults to `:disk`
      #
      # @return [Symbol]
      attr_accessor :type

      # Size of disk to create
      #
      # TODO: Should we have shortcuts for GB???
      #
      # @return [Integer]
      attr_accessor :size

      # Determines if this disk is the _main_ disk, or an attachment.
      # Defaults to true.
      #
      # @return [Boolean]
      attr_accessor :primary

      # Provider specific options
      #
      # This should work similar to how a "Provisioner" class works:
      #
      # - This class is the base class where as this options value is actually a
      #   provider specific class for the given options for that provider, if required
      #
      # - Hopefully in general the top-scope disk options are enough for the general
      #   case that most people won't need provider specific options except for very specific cases
      #
      # @return [Object]
      attr_accessor :config

      def initialize(type)
        @logger = Log4r::Logger.new("vagrant::config::vm::trigger::config")

        @type = type

        @name = UNSET_VALUE
        @provider_type = UNSET_VALUE
        @size = UNSET_VALUE
        @primary = UNSET_VALUE
        @config = nil
        @invalid = false

        # Internal options
        @id = SecureRandom.uuid

        # find disk provider plugin
        # Need to pass in provider or figure out provider here
        @config_class = nil
        # @invalid = true if provider not found
        if !@config_class
          @logger.info(
            "Disk config for '#{@provider_type}' not found. Ignoring config.")
          @config_class = Vagrant::Config::V2::DummyConfig
        end
      end

      def add_config(**options, &block)
        return if invalid?

        current = @config_class.new
        current.set_options(options) if options
        block.call(current) if block
        current = @config.merge(current) if @config
        @config = current
      end

      # Returns true or false if disk provider is found
      #
      # @return [Bool]
      def invalid?
        @invalid
      end

      def finalize!
        # Ensure all config options are set to nil or default value if untouched
        # by user
        @type = :disk if @type == UNSET_VALUE
        @size = nil if @size == UNSET_VALUE
        @primary = true if @primary == UNSET_VALUE

        # Give the disk a default name if unset
        # TODO: Name not required if primray?
        @name = "vagrant_#{@type.to_s}_#{@id.split("-").last}" if @name == UNSET_VALUE

        @config = nil if @config == UNSET_VALUE
      end

      # @return [Array] array of strings of error messages from config option validation
      def validate(machine)
        errors = _detected_errors

        # validate type with list of known disk types

        if !DEFAULT_DISK_TYPES.include?(@type)
          errors << "Disk type '#{@type}' is not a valid type. Please pick one of the following supported disk types: #{DEFAULT_DISK_TYPES.join(', ')}"
        end

        # TODO: Convert a string to int here?
        if !@size.is_a?(Integer)
          errors << "Config option size for disk is not an integer"
        end

        errors
      end

      # The String representation of this Disk.
      #
      # @return [String]
      def to_s
        "disk config"
      end
    end
  end
end
