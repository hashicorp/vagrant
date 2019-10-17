require "log4r"
require "securerandom"

module VagrantPlugins
  module Kernel_V2
    class VagrantConfigDisk < Vagrant.plugin("2", :config)
      #-------------------------------------------------------------------
      # Config class for a given Disk
      #-------------------------------------------------------------------

      # Note: This value is for internal use only
      #
      # @return [String]
      attr_reader :id

      # File name for the given disk. Defaults to nil.
      #
      # TODO: Should probably default to a string+short integer id in the finalize method
      #
      # @return [String]
      attr_accessor :name

      # Type of disk to create
      #
      # @return [Symbol]
      attr_accessor :type

      # Size of disk to create
      #
      # @return [Integer]
      attr_accessor :size

      # Provider specific options
      #
      # TODO: INTERNAL??
      #
      # @return [Hash]
      attr_accessor :options

      def initialize(type)
        @logger = Log4r::Logger.new("vagrant::config::vm::trigger::config")

        @name = UNSET_VALUE
        @type = UNSET_VALUE
        @size = UNSET_VALUE
        @options = UNSET_VALUE

        # Internal options
        @id = SecureRandom.uuid
      end

      def finalize!
        # Ensure all config options are set to nil or default value if untouched
        # by user
        @name = nil if @name == UNSET_VALUE
        @type = nil if @type == UNSET_VALUE
        @size = nil if @size == UNSET_VALUE

        @options = nil if @options == UNSET_VALUE
      end

      # @return [Array] array of strings of error messages from config option validation
      def validate(machine)
        errors = _detected_errors

        # validate type with list of known disk types

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
