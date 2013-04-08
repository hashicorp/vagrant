require "vagrant"

module VagrantPlugins
  module CFEngine
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :install
      attr_accessor :deb_repo_file
      attr_accessor :deb_repo_line
      attr_accessor :repo_gpg_key_url

      def initialize
        @deb_repo_file = UNSET_VALUE
        @deb_repo_line = UNSET_VALUE
        @install = UNSET_VALUE
        @repo_gpg_key_url = UNSET_VALUE
      end

      def finalize!
        if @deb_repo_file == UNSET_VALUE
          @deb_repo_file = "/etc/apt/sources.list.d/cfengine-community.list"
        end

        if @deb_repo_line == UNSET_VALUE
          @deb_repo_line = "deb http://cfengine.com/pub/apt $(lsb_release -cs) main"
        end

        @install = true if @install == UNSET_VALUE
        @install = @install.to_sym if @install.respond_to?(:to_sym)

        if @repo_gpg_key_url == UNSET_VALUE
          @repo_gpg_key_url = "http://cfengine.com/pub/gpg.key"
        end
      end
    end
  end
end
