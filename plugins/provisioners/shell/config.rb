require 'uri'

module VagrantPlugins
  module Shell
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :inline
      attr_accessor :path
      attr_accessor :md5
      attr_accessor :sha1
      attr_accessor :env
      attr_accessor :upload_path
      attr_accessor :args
      attr_accessor :privileged
      attr_accessor :binary
      attr_accessor :keep_color
      attr_accessor :name
      attr_accessor :powershell_args
      attr_accessor :powershell_elevated_interactive

      def initialize
        @args                  = UNSET_VALUE
        @inline                = UNSET_VALUE
        @path                  = UNSET_VALUE
        @md5                   = UNSET_VALUE
        @sha1                  = UNSET_VALUE
        @env                   = UNSET_VALUE
        @upload_path           = UNSET_VALUE
        @privileged            = UNSET_VALUE
        @binary                = UNSET_VALUE
        @keep_color            = UNSET_VALUE
        @name                  = UNSET_VALUE
        @powershell_args       = UNSET_VALUE
        @powershell_elevated_interactive  = UNSET_VALUE
      end

      def finalize!
        @args                 = nil if @args == UNSET_VALUE
        @inline               = nil if @inline == UNSET_VALUE
        @path                 = nil if @path == UNSET_VALUE
        @md5                  = nil if @md5 == UNSET_VALUE
        @sha1                 = nil if @sha1 == UNSET_VALUE
        @env                  = {}  if @env == UNSET_VALUE
        @upload_path          = "/tmp/vagrant-shell" if @upload_path == UNSET_VALUE
        @privileged           = true if @privileged == UNSET_VALUE
        @binary               = false if @binary == UNSET_VALUE
        @keep_color           = false if @keep_color == UNSET_VALUE
        @name                 = nil if @name == UNSET_VALUE
        @powershell_args      = "-ExecutionPolicy Bypass" if @powershell_args == UNSET_VALUE
        @powershell_elevated_interactive = false if @powershell_elevated_interactive == UNSET_VALUE

        if @args && args_valid?
          @args = @args.is_a?(Array) ? @args.map { |a| a.to_s } : @args.to_s
        end
      end

      def validate(machine)
        errors = _detected_errors

        # Validate that the parameters are properly set
        if path && inline
          errors << I18n.t("vagrant.provisioners.shell.path_and_inline_set")
        elsif !path && !inline
          errors << I18n.t("vagrant.provisioners.shell.no_path_or_inline")
        end

        # If it is not an URL, we validate the existence of a script to upload
        if path && !remote?
          expanded_path = Pathname.new(path).expand_path(machine.env.root_path)
          if !expanded_path.file?
            errors << I18n.t("vagrant.provisioners.shell.path_invalid",
                              path: expanded_path)
          else
            data = expanded_path.read(16)
            if data && !data.valid_encoding?
              errors << I18n.t(
                "vagrant.provisioners.shell.invalid_encoding",
                actual: data.encoding.to_s,
                default: Encoding.default_external.to_s,
                path: expanded_path.to_s)
            end
          end
        end

        if !env.is_a?(Hash)
          errors << I18n.t("vagrant.provisioners.shell.env_must_be_a_hash")
        end

        # There needs to be a path to upload the script to
        if !upload_path
          errors << I18n.t("vagrant.provisioners.shell.upload_path_not_set")
        end

        if !args_valid?
          errors << I18n.t("vagrant.provisioners.shell.args_bad_type")
        end

        if powershell_elevated_interactive && !privileged
          errors << I18n.t("vagrant.provisioners.shell.interactive_not_elevated")
        end

        { "shell provisioner" => errors }
      end

      # Args are optional, but if they're provided we only support them as a
      # string or as an array.
      def args_valid?
        return true if !args
        return true if args.is_a?(String)
        return true if args.is_a?(Integer)
        if args.is_a?(Array)
          args.each do |a|
            return false if !a.kind_of?(String) && !a.kind_of?(Integer)
          end

          return true
        end
      end

      def remote?
        path =~ URI.regexp(["ftp", "http", "https"])
      end
    end
  end
end
