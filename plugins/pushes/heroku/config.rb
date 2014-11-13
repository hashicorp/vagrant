module VagrantPlugins
  module HerokuPush
    class Config < Vagrant.plugin("2", :config)
      # The name of the Heroku application to push to.
      # @return [String]
      attr_accessor :app

      # The base directory with file contents to upload. By default this
      # is the same directory as the Vagrantfile, but you can specify this
      # if you have a `src` folder or `bin` folder or some other folder
      # you want to upload. This directory must be a git repository.
      # @return [String]
      attr_accessor :dir

      # The path to the git binary to shell out to. This usually is only set for
      # debugging/development. If not set, the git bin will be searched for
      # in the PATH.
      # @return [String]
      attr_accessor :git_bin

      # The Git remote to push to (default: "heroku").
      # @return [String]
      attr_accessor :remote

      def initialize
        @app = UNSET_VALUE
        @dir = UNSET_VALUE

        @git_bin = UNSET_VALUE
        @remote = UNSET_VALUE
      end

      def finalize!
        @app = nil if @app == UNSET_VALUE
        @dir = "." if @dir == UNSET_VALUE

        @git_bin = "git" if @git_bin == UNSET_VALUE
        @remote = "heroku" if @remote == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        if missing?(@dir)
          errors << I18n.t("heroku_push.errors.missing_attribute",
            attribute: "dir",
          )
        end

        if missing?(@git_bin)
          errors << I18n.t("heroku_push.errors.missing_attribute",
            attribute: "git_bin",
          )
        end

        if missing?(@remote)
          errors << I18n.t("heroku_push.errors.missing_attribute",
            attribute: "remote",
          )
        end

        { "Heroku push" => errors }
      end

      private

      # Determine if the given string is "missing" (blank)
      # @return [true, false]
      def missing?(obj)
        obj.to_s.strip.empty?
      end
    end
  end
end
