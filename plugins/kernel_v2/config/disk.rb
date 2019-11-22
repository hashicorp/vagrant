require "log4r"
require "securerandom"

require "vagrant/util/numeric"

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

      # File name for the given disk. Defaults to a generated name that is:
      #
      #  vagrant_<disk_type>_<short_uuid>
      #
      # @return [String]
      attr_accessor :name

      # Type of disk to create. Defaults to `:disk`
      #
      # @return [Symbol]
      attr_accessor :type

      # Size of disk to create
      #
      # @return [Integer,String]
      attr_accessor :size

      # Path to the location of the disk file (Optional)
      #
      # @return [String]
      attr_accessor :file

      # Determines if this disk is the _main_ disk, or an attachment.
      # Defaults to true.
      #
      # @return [Boolean]
      attr_accessor :primary

      # Provider specific options
      #
      # @return [Hash]
      attr_accessor :provider_config

      def initialize(type)
        @logger = Log4r::Logger.new("vagrant::config::vm::disk")

        @type = type
        @provider_config = {}

        @name = UNSET_VALUE
        @provider_type = UNSET_VALUE
        @size = UNSET_VALUE
        @primary = UNSET_VALUE
        @file = UNSET_VALUE

        # Internal options
        @id = SecureRandom.uuid
      end

      # Helper method for storing provider specific config options
      #
      # Expected format is:
      #
      # - `provider__diskoption: value`
      # - `{provider: {diskoption: value, otherdiskoption: value, ...}`
      #
      # Duplicates will be overriden
      #
      # @param [Hash] options
      def add_provider_config(**options, &block)
        current = {}
        options.each do |k,v|
          opts = k.to_s.split("__")

          if opts.size == 2
            current[opts[0].to_sym] = {opts[1].to_sym => v}
          elsif v.is_a?(Hash)
            current[k] = v
          else
            @logger.warn("Disk option '#{k}' found that does not match expected provider disk config schema.")
          end
        end

        current = @provider_config.merge(current) if !@provider_config.empty?
        @provider_config = current
      end

      def finalize!
        # Ensure all config options are set to nil or default value if untouched
        # by user
        @type = :disk if @type == UNSET_VALUE
        @size = nil if @size == UNSET_VALUE
        @file = nil if @file == UNSET_VALUE

        if @primary == UNSET_VALUE
          @primary = false
        end

        if @name == UNSET_VALUE
          if @primary
            @name = "vagrant_primary"
          else
            @name = "name_#{@type.to_s}_#{@id.split("-").last}"
          end
        end

        @provider_config = nil if @provider_config == {}
      end

      # @return [Array] array of strings of error messages from config option validation
      def validate(machine)
        errors = _detected_errors

        # validate type with list of known disk types

        if !DEFAULT_DISK_TYPES.include?(@type)
          errors << I18n.t("vagrant.config.disk.invalid_type", type: @type,
                           types: DEFAULT_DISK_TYPES.join(', '))
        end

        if @size && !@size.is_a?(Integer)
          if @size.is_a?(String)
            @size = Vagrant::Util::Numeric.string_to_bytes(@size)
          end

          if !@size
            errors << I18n.t("vagrant.config.disk.invalid_size", name: @name, machine: machine.name)
          end
        end

        if @file
          if !@file.is_a?(String)
            errors << I18n.t("vagrant.config.disk.invalid_file_type", file: @file, machine: machine.name)
          elsif !File.file?(@file)
            errors << I18n.t("vagrant.config.disk.missing_file", file_path: @file,
                             name: @name, machine: machine.name)
          end
        end

        if @provider_config
          if !@provider_config.keys.include?(machine.provider_name)
            machine.env.ui.warn(I18n.t("vagrant.config.disk.missing_provider",
                                       machine: machine.name,
                                       provider_name: machine.provider_name))
          end
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
