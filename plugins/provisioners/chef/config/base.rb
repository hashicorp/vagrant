module VagrantPlugins
  module Chef
    module Config
      class Base < Vagrant.plugin("2", :config)
        # The path to Chef's bin/ directory.
        # @return [String]
        attr_accessor :binary_path

        # Arbitrary environment variables to set before running the Chef
        # provisioner command.
        # @return [String]
        attr_accessor :binary_env

        # The name of the Chef project to install. This is "chef" for the Chef
        # Client or "chefdk" for the Chef Development Kit. Other product names
        # may be available as well.
        # @return [String]
        attr_accessor :product

        # Install Chef on the system if it does not exist. Default is true.
        # This is a trinary attribute (it can have three values):
        #
        # - true (bool) install Chef
        # - false (bool) do not install Chef
        # - "force" (string) install Chef, even if it is already installed at
        #   the proper version
        #
        # @return [true, false, String]
        attr_accessor :install

        # The Chef log level. See the Chef docs for acceptable values.
        # @return [String, Symbol]
        attr_accessor :log_level

        # The channel from which to download Chef. Currently known values are
        # "current" and "stable", but more may be added in the future. The
        # default is "current".
        # @return [String]
        attr_accessor :channel

        # The version of Chef to install. If Chef is already installed on the
        # system, the installed version is compared with the requested version.
        # If they match, no action is taken. If they do not match, version of
        # the value specified in this attribute will be installed over top of
        # the existing version (a warning will be displayed).
        #
        # You can also specify "latest" (default), which will install the latest
        # version of Chef on the system. In this case, Chef will use whatever
        # version is on the system. To force the newest version of Chef to be
        # installed on every provision, set the {#install} option to "force".
        #
        # @return [String]
        attr_accessor :version

        # The path where the Chef installer will be downloaded to. Only valid if
        # install is true or "force". It defaults to nil, which means that the
        # omnibus installer will choose the destination and you have no control
        # over it.
        #
        # @return [String]
        attr_accessor :installer_download_path

        # @deprecated
        def prerelease=(value)
          STDOUT.puts <<-EOH
[DEPRECATED] The configuration `chef.prerelease' has been deprecated. Please use
`chef.channel' instead. The default value for channel is "current", which
includes prelease versions of Chef Client and the Chef Development Kit. You can
probably just remove the `prerelease' setting from your Vagrantfile and things
will continue working as expected.
EOH
        end

        def initialize
          super

          @binary_path = UNSET_VALUE
          @binary_env  = UNSET_VALUE
          @product     = UNSET_VALUE
          @install     = UNSET_VALUE
          @log_level   = UNSET_VALUE
          @channel     = UNSET_VALUE
          @version     = UNSET_VALUE
          @installer_download_path = UNSET_VALUE
        end

        def finalize!
          @binary_path = nil       if @binary_path == UNSET_VALUE
          @binary_env  = nil       if @binary_env == UNSET_VALUE
          @product     = "chef"    if @product == UNSET_VALUE
          @install     = true      if @install == UNSET_VALUE
          @log_level   = :info     if @log_level == UNSET_VALUE
          @channel     = "current" if @channel == UNSET_VALUE
          @version     = :latest   if @version == UNSET_VALUE
          @installer_download_path = nil  if @installer_download_path == UNSET_VALUE

          # Make sure the install is a symbol if it's not a boolean
          if @install.respond_to?(:to_sym)
            @install = @install.to_sym
          end

          # Make sure the version is a symbol if it's not a boolean
          if @version.respond_to?(:to_sym)
            @version = @version.to_sym
          end

          # Make sure the log level is a symbol
          @log_level = @log_level.to_sym
        end

        # Like validate, but returns a list of errors to append.
        #
        # @return [Array<String>]
        def validate_base(machine)
          errors = _detected_errors

          if missing?(log_level)
            errors << I18n.t("vagrant.provisioners.chef.log_level_empty")
          end

          errors
        end

        # Determine if the given string is "missing" (blank)
        # @return [true, false]
        def missing?(obj)
          obj.to_s.strip.empty?
        end
      end
    end
  end
end
