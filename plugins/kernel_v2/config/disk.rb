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

      FILE_CHAR_REGEX = /[^-a-z0-9_]/i.freeze

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

      # Type of disk extension to create. Defaults to `vdi`
      #
      # @return [String]
      attr_accessor :disk_ext

      # Size of disk to create
      #
      # @return [Integer,String]
      attr_accessor :size

      # Path to the location of the disk file (Optional for `:disk` type,
      # required for `:dvd` type.)
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
        @disk_ext = UNSET_VALUE

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
        if current
          @provider_config = current
        else
          @provider_config = {}
        end
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

        if @name.is_a?(String) && @name.match(FILE_CHAR_REGEX)
            @logger.warn("Vagrant will remove detected invalid characters in '#{@name}' and convert the disk name into something usable for a file")
            @name.gsub!(FILE_CHAR_REGEX, "_")
        elsif @name == UNSET_VALUE
          if @primary
            @name = "vagrant_primary"
          else
            @name = nil
          end
        end
      end

      # @return [Array] array of strings of error messages from config option validation
      def validate(machine)
        errors = _detected_errors
        # validate type with list of known disk types

        if !DEFAULT_DISK_TYPES.include?(@type)
          errors << I18n.t("vagrant.config.disk.invalid_type", type: @type,
                           types: DEFAULT_DISK_TYPES.join(', '))
        end

        if @disk_ext == UNSET_VALUE
          if machine.provider.capability?(:set_default_disk_ext)
            @disk_ext = machine.provider.capability(:set_default_disk_ext)
          else
            @logger.warn("No provider capability defined to set default 'disk_ext' type. Will use 'vdi' for disk extension.")
            @disk_ext = "vdi"
          end
        elsif @disk_ext
          @disk_ext = @disk_ext.downcase

          if machine.provider.capability?(:validate_disk_ext)
            if !machine.provider.capability(:validate_disk_ext, @disk_ext)
              if machine.provider.capability?(:default_disk_exts)
                disk_exts = machine.provider.capability(:default_disk_exts).join(', ')
              else
                disk_exts = "not found"
              end
              errors << I18n.t("vagrant.config.disk.invalid_ext", ext: @disk_ext,
                               name: @name,
                               exts: disk_exts)
            end
          else
            @logger.warn("No provider capability defined to validate 'disk_ext' type")
          end
        end

        if @size && !@size.is_a?(Integer)
          if @size.is_a?(String)
            @size = Vagrant::Util::Numeric.string_to_bytes(@size)
          end
        end

        if !@size && type == :disk
          errors << I18n.t("vagrant.config.disk.invalid_size", name: @name, machine: machine.name)
        end

        if @type == :dvd && !@file
          errors << I18n.t("vagrant.config.disk.dvd_type_file_required", name: @name, machine: machine.name)
        end

        if @type == :dvd && @primary
          errors << I18n.t("vagrant.config.disk.dvd_type_primary", name: @name, machine: machine.name)
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
          if !@provider_config.empty?
            if !@provider_config.key?(machine.provider_name)
              machine.env.ui.warn(I18n.t("vagrant.config.disk.missing_provider",
                                         machine: machine.name,
                                         provider_name: machine.provider_name))
            end
          end
        end

        if !@name
          errors << I18n.t("vagrant.config.disk.no_name_set", machine: machine.name)
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
