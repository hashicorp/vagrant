require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class CloudInit < Vagrant.plugin("2", :config)

      DEFAULT_SOURCE_PATTERN = "**/**/*".freeze

      attr_accessor :iso_path
      attr_accessor :source_files_pattern
      attr_accessor :source_directory

      def initialize
        @iso_path = UNSET_VALUE
        @source_files_pattern = UNSET_VALUE
        @source_directory = UNSET_VALUE
      end

      def finalize!
        if @iso_path != UNSET_VALUE
          @iso_path = Pathname.new(@iso_path.to_s)
        else
          @iso_path = nil
        end
        if @source_files_pattern == UNSET_VALUE
          @source_files_pattern = DEFAULT_SOURCE_PATTERN
        end
        if @source_directory != UNSET_VALUE
          @source_directory = Pathname.new(@source_directory.to_s)
        else
          @source_directory = nil
        end
      end

      def validate(machine)
        errors = _detected_errors
        if @source_directory.nil? || !@source_directory.exist?
          errors << I18n.t("vagrant.config.cloud_init.invalid_source_directory",
            directory: source_directory.to_s)
        end

        {"cloud_init" => errors}
      end

      def to_s
        "CloudInit"
      end
    end
  end
end
