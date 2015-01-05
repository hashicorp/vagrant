module VagrantPlugins
  module FTPPush
    class Config < Vagrant.plugin("2", :config)
      # The (S)FTP host to use.
      # @return [String]
      attr_accessor :host

      # The username to use for authentication with the (S)FTP server.
      # @return [String]
      attr_accessor :username

      # The password to use for authentication with the (S)FTP server.
      # @return [String]
      attr_accessor :password

      # Use passive FTP (default is true).
      # @return [true, false]
      attr_accessor :passive

      # Use secure (SFTP) (default is false).
      # @return [true, false]
      attr_accessor :secure

      # The root destination on the target system to sync the files (default is
      # /).
      # @return [String]
      attr_accessor :destination

      # Lists of files to include/exclude in what is uploaded. Exclude is
      # always the last run filter, so if a file is matched in both include
      # and exclude, it will be excluded.
      #
      # The value of the array elements should be a simple file glob relative
      # to the directory being packaged.
      # @return [Array<String>]
      attr_accessor :includes
      attr_accessor :excludes

      # The base directory with file contents to upload. By default this
      # is the same directory as the Vagrantfile, but you can specify this
      # if you have a `src` folder or `bin` folder or some other folder
      # you want to upload.
      # @return [String]
      attr_accessor :dir

      def initialize
        @host = UNSET_VALUE
        @username = UNSET_VALUE
        @password = UNSET_VALUE
        @passive = UNSET_VALUE
        @secure = UNSET_VALUE
        @destination = UNSET_VALUE

        @includes = []
        @excludes = []

        @dir = UNSET_VALUE
      end

      def merge(other)
        super.tap do |result|
          result.includes = self.includes.dup.concat(other.includes).uniq
          result.excludes = self.excludes.dup.concat(other.excludes).uniq
        end
      end

      def finalize!
        @host = nil if @host == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @password = nil if @password == UNSET_VALUE
        @passive = true if @passive == UNSET_VALUE
        @secure = false if @secure == UNSET_VALUE
        @destination = "/" if @destination == UNSET_VALUE
        @dir = "." if @dir == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        if missing?(@host)
          errors << I18n.t("ftp_push.errors.missing_attribute",
            attribute: "host",
          )
        end

        if missing?(@username)
          errors << I18n.t("ftp_push.errors.missing_attribute",
            attribute: "username",
          )
        end

        if missing?(@destination)
          errors << I18n.t("ftp_push.errors.missing_attribute",
            attribute: "destination",
          )
        end

        if missing?(@dir)
          errors << I18n.t("ftp_push.errors.missing_attribute",
            attribute: "dir",
          )
        end

        { "FTP push" => errors }
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
    end
  end
end
