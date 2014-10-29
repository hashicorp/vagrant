module VagrantPlugins
  module HarmonyPush
    class Config < Vagrant.plugin("2", :config)
      # The name of the application to push to. This will be created (with
      # user confirmation) if it doesn't already exist.
      #
      # @return [String]
      attr_accessor :app

      # The base directory with file contents to upload. By default this
      # is the same directory as the Vagrantfile, but you can specify this
      # if you have a `src` folder or `bin` folder or some other folder
      # you want to upload.
      #
      # @return [String]
      attr_accessor :dir

      # Lists of files to include/exclude in what is uploaded. Exclude is
      # always the last run filter, so if a file is matched in both include
      # and exclude, it will be excluded.
      #
      # The value of the array elements should be a simple file glob relative
      # to the directory being packaged.
      #
      # @return [Array<String>]
      attr_accessor :include
      attr_accessor :exclude

      # If set to true, Vagrant will automatically use VCS data to determine
      # the files to upload. As a caveat: uncommitted changes will not be
      # deployed.
      #
      # @return [Boolean]
      attr_accessor :vcs

      # The path to the uploader binary to shell out to. This usually
      # is only set for debugging/development. If not set, the uploader
      # will be looked for within the Vagrant installer dir followed by
      # the PATH.
      #
      # @return [String]
      attr_accessor :uploader_path

      def initialize
        @app = UNSET_VALUE
        @dir = UNSET_VALUE
        @vcs = UNSET_VALUE
        @include = []
        @exclude = []
        @uploader_path = UNSET_VALUE
      end

      def merge(other)
        super.tap do |result|
          inc = self.include.dup
          inc.concat(other.include)
          result.include = inc

          exc = self.exclude.dup
          exc.concat(other.exclude)
          result.exclude = exc
        end
      end

      def finalize!
        @app = nil if @app == UNSET_VALUE
        @dir = "." if @dir == UNSET_VALUE
        @uploader_path = nil if @uploader_path == UNSET_VALUE
        @vcs = true if @vcs == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        if @app.to_s.strip.empty?
          errors << I18n.t("push_harmony.errors.config.app_required")
        end

        { "Harmony push" => errors }
      end
    end
  end
end
