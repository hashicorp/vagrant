require "log4r"
require "securerandom"

module VagrantPlugins
  module Kernel_V2
    class VagrantConfigCloudInit < Vagrant.plugin("2", :config)
      #-------------------------------------------------------------------
      # Config class for cloud-init
      #-------------------------------------------------------------------

      DEFAULT_CONTENT_TYPES = ["text/cloud-boothook", "text/cloud-config",
                               "text/cloud-config-archive", "text/jinja2",
                               "text/part-handler", "text/upstart-job",
                               "text/x-include-once-url", "text/x-include-url",
                               "text/x-shellscript"].map(&:freeze).freeze

      DEFAULT_CONFIG_TYPE = :user_data

      # @note This value is for internal use only
      #
      # @return [String]
      attr_reader :id

      # The 'type' of data being stored. If not defined,
      # will default to :user_data
      #
      # @return [Symbol]
      attr_accessor :type

      # @return [String]
      attr_accessor :content_type

      # The optional mime-part content-disposition filename.
      #
      # @return [String]
      attr_accessor :content_disposition_filename

      # @return [String]
      attr_accessor :path

      # @return [String]
      attr_accessor :inline

      def initialize(type=nil)
        @logger = Log4r::Logger.new("vagrant::config::vm::cloud_init")

        @type = type if type

        @content_type = UNSET_VALUE
        @content_disposition_filename = UNSET_VALUE
        @path = UNSET_VALUE
        @inline = UNSET_VALUE

        # Internal options
        @id = SecureRandom.uuid
      end

      def finalize!
        if !@type
          @type = DEFAULT_CONFIG_TYPE
        else
          @type = @type.to_sym
        end

        @content_type = nil if @content_type == UNSET_VALUE
        @content_disposition_filename = nil if @content_disposition_filename == UNSET_VALUE
        @path = nil if @path == UNSET_VALUE
        @inline = nil if @inline == UNSET_VALUE
      end

      # @return [Array] array of strings of error messages from config option validation
      def validate(machine)
        errors = _detected_errors

        if @type && @type != DEFAULT_CONFIG_TYPE
          errors << I18n.t("vagrant.cloud_init.incorrect_type_set",
                           type: @type,
                           machine: machine.name,
                           default_type: DEFAULT_CONFIG_TYPE)
        end

        if !@content_type
          errors << I18n.t("vagrant.cloud_init.content_type_not_set",
                           machine: machine.name,
                           accepted_types: DEFAULT_CONTENT_TYPES.join(', '))
        elsif !DEFAULT_CONTENT_TYPES.include?(@content_type)
          errors << I18n.t("vagrant.cloud_init.incorrect_content_type",
                           machine: machine.name,
                           content_type: @content_type,
                           accepted_types: DEFAULT_CONTENT_TYPES.join(', '))
        end

        if @path && @inline
          errors << I18n.t("vagrant.cloud_init.path_and_inline_set",
                           machine: machine.name)
        end

        if @path
          if !@path.is_a?(String)
            errors << I18n.t("vagrant.cloud_init.incorrect_path_type",
                              machine: machine.name,
                              path: @path,
                              type: @path.class.name)
          else
            expanded_path = Pathname.new(@path).expand_path(machine.env.root_path)
            if !expanded_path.file?
              errors << I18n.t("vagrant.cloud_init.path_invalid",
                               path: expanded_path,
                               machine: machine.name)
            end
          end
        end

        if @inline
          if !@inline.is_a?(String)
            errors << I18n.t("vagrant.cloud_init.incorrect_inline_type",
                             machine: machine.name,
                             type: @inline.class.name)
          end
        end

        errors
      end

      # The String representation of this config.
      #
      # @return [String]
      def to_s
        "cloud_init config"
      end
    end
  end
end
