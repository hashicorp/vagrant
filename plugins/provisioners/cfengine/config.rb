require "pathname"

require "vagrant"

module VagrantPlugins
  module CFEngine
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :am_policy_hub
      attr_accessor :extra_agent_args
      attr_accessor :classes
      attr_accessor :deb_repo_file
      attr_accessor :deb_repo_line
      attr_accessor :files_path
      attr_accessor :force_bootstrap
      attr_accessor :install
      attr_accessor :mode
      attr_accessor :policy_server_address
      attr_accessor :repo_gpg_key_url
      attr_accessor :run_file
      attr_accessor :upload_path
      attr_accessor :yum_repo_file
      attr_accessor :yum_repo_url
      attr_accessor :package_name

      def initialize
        @am_policy_hub    = UNSET_VALUE
        @classes          = UNSET_VALUE
        @deb_repo_file    = UNSET_VALUE
        @deb_repo_line    = UNSET_VALUE
        @extra_agent_args = UNSET_VALUE
        @files_path       = UNSET_VALUE
        @force_bootstrap  = UNSET_VALUE
        @install          = UNSET_VALUE
        @mode             = UNSET_VALUE
        @policy_server_address = UNSET_VALUE
        @repo_gpg_key_url = UNSET_VALUE
        @run_file         = UNSET_VALUE
        @upload_path      = UNSET_VALUE
        @yum_repo_file    = UNSET_VALUE
        @yum_repo_url     = UNSET_VALUE
        @package_name     = UNSET_VALUE
      end

      def finalize!
        @am_policy_hub = false if @am_policy_hub == UNSET_VALUE

        @classes = nil if @classes == UNSET_VALUE

        if @deb_repo_file == UNSET_VALUE
          @deb_repo_file = "/etc/apt/sources.list.d/cfengine-community.list"
        end

        if @deb_repo_line == UNSET_VALUE
          @deb_repo_line = "deb https://cfengine.com/pub/apt/packages stable main"
        end

        @extra_agent_args = nil if @extra_agent_args == UNSET_VALUE

        @files_path = nil if @files_path == UNSET_VALUE

        @force_bootstrap = false if @force_bootstrap == UNSET_VALUE

        @install = true if @install == UNSET_VALUE
        @install = @install.to_sym if @install.respond_to?(:to_sym)

        @mode = :bootstrap if @mode == UNSET_VALUE
        @mode = @mode.to_sym

        @run_file = nil if @run_file == UNSET_VALUE

        @policy_server_address = nil if @policy_server_address == UNSET_VALUE

        if @repo_gpg_key_url == UNSET_VALUE
          @repo_gpg_key_url = "https://cfengine.com/pub/gpg.key"
        end

        @upload_path = "/tmp/vagrant-cfengine-file" if @upload_path == UNSET_VALUE

        if @yum_repo_file == UNSET_VALUE
          @yum_repo_file = "/etc/yum.repos.d/cfengine-community.repo"
        end

        if @yum_repo_url == UNSET_VALUE
          @yum_repo_url = "https://cfengine.com/pub/yum/$basearch"
        end

        if @package_name == UNSET_VALUE
            @package_name = "cfengine-community"
        end
      end

      def validate(machine)
        errors = _detected_errors

        valid_modes = [:bootstrap, :single_run]
        errors << I18n.t("vagrant.cfengine_config.invalid_mode") if !valid_modes.include?(@mode)

        if @mode == :bootstrap
          if !@policy_server_address && !@am_policy_hub
            errors << I18n.t("vagrant.cfengine_config.policy_server_address")
          end
        end

        if @classes && !@classes.is_a?(Array)
          errors << I18n.t("vagrant.cfengine_config.classes_array")
        end

        if @files_path
          expanded = Pathname.new(@files_path).expand_path(machine.env.root_path)
          if !expanded.directory?
            errors << I18n.t("vagrant.cfengine_config.files_path_not_directory")
          end
        end

        if @run_file
          expanded = Pathname.new(@run_file).expand_path(machine.env.root_path)
          if !expanded.file?
            errors << I18n.t("vagrant.cfengine_config.run_file_not_found")
          end
        end

        { "CFEngine" => errors }
      end
    end
  end
end
