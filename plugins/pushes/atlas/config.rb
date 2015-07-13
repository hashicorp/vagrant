module VagrantPlugins
  module AtlasPush
    class Config < Vagrant.plugin("2", :config)
      # The address of the Atlas server to upload to. By default this will
      # be the public Atlas server.
      #
      # @return [String]
      attr_accessor :address

      # The Atlas token to use. If the user has run `vagrant login`, this will
      # use that token. If the environment variable `ATLAS_TOKEN` is set, the
      # uploader will use this value. By default, this is nil.
      #
      # @return [String, nil]
      attr_accessor :token

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
      attr_accessor :includes
      attr_accessor :excludes

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
        @address = UNSET_VALUE
        @token = UNSET_VALUE
        @app = UNSET_VALUE
        @dir = UNSET_VALUE
        @vcs = UNSET_VALUE
        @includes = []
        @excludes = []
        @uploader_path = UNSET_VALUE
      end

      def merge(other)
        super.tap do |result|
          result.includes = self.includes.dup.concat(other.includes).uniq
          result.excludes = self.excludes.dup.concat(other.excludes).uniq
        end
      end

      def finalize!
        @address = nil if @address == UNSET_VALUE
        @token = nil if @token == UNSET_VALUE
        @token = ENV["ATLAS_TOKEN"] if !@token && ENV["ATLAS_TOKEN"] != ""
        @app = nil if @app == UNSET_VALUE
        @dir = "." if @dir == UNSET_VALUE
        @uploader_path = nil if @uploader_path == UNSET_VALUE
        @vcs = true if @vcs == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        if missing?(@token)
          token = token_from_vagrant_login(machine.env)
          if missing?(token)
            errors << I18n.t("atlas_push.errors.missing_token")
          else
            @token = token
          end
        end

        if missing?(@app)
          errors << I18n.t("atlas_push.errors.missing_attribute",
            attribute: "app",
          )
        end

        if missing?(@dir)
          errors << I18n.t("atlas_push.errors.missing_attribute",
            attribute: "dir",
          )
        end

        { "Atlas push" => errors }
      end

      # Add the filepath to the list of includes
      # @param [String] filepath
      def include(filepath)
        @includes << filepath
      end
      alias_method :include=, :include

      # Add the filepath to the list of excludes
      # @param [String] filepath
      def exclude(filepath)
        @excludes << filepath
      end
      alias_method :exclude=, :exclude

      private

      # Determine if the given string is "missing" (blank)
      # @return [true, false]
      def missing?(obj)
        obj.to_s.strip.empty?
      end

      # Attempt to load the token from disk using the vagrant-login plugin. If
      # the constant is not defined, that means the user is operating in some
      # bespoke and unsupported Ruby environment.
      #
      # @param [Vagrant::Environment] env
      #
      # @return [String, nil]
      #   the token, or nil if it does not exist
      def token_from_vagrant_login(env)
        client = VagrantPlugins::LoginCommand::Client.new(env)
        client.token
      end
    end
  end
end
