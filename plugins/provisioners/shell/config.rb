module VagrantPlugins
  module Shell
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :inline
      attr_accessor :path
      attr_accessor :upload_path
      attr_accessor :args

      def initialize
        @args        = UNSET_VALUE
        @inline      = UNSET_VALUE
        @path        = UNSET_VALUE
        @upload_path = UNSET_VALUE
      end

      def finalize!
        @args        = nil if @args == UNSET_VALUE
        @inline      = nil if @inline == UNSET_VALUE
        @path        = nil if @path == UNSET_VALUE
        @upload_path = "/tmp/vagrant-shell" if @upload_path == UNSET_VALUE
      end

      def validate(machine)
        errors = []

        # Validate that the parameters are properly set
        if path && inline
          errors << I18n.t("vagrant.provisioners.shell.path_and_inline_set")
        elsif !path && !inline
          errors << I18n.t("vagrant.provisioners.shell.no_path_or_inline")
        end

        # Validate the existence of a script to upload
        if path
          expanded_path = Pathname.new(path).expand_path(machine.env.root_path)
          if !expanded_path.file?
            errors << I18n.t("vagrant.provisioners.shell.path_invalid",
                              :path => expanded_path)
          end
        end

        # There needs to be a path to upload the script to
        if !upload_path
          errors << I18n.t("vagrant.provisioners.shell.upload_path_not_set")
        end

        # If there are args and its not a string, that is a problem
        if args && !args.is_a?(String)
          errors << I18n.t("vagrant.provisioners.shell.args_not_string")
        end

        { "shell provisioner" => errors }
      end
    end
  end
end
