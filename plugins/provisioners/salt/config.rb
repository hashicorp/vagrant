require "vagrant"
require "vagrant/util/deep_merge"

module VagrantPlugins
  module Salt
    class Config < Vagrant.plugin("2", :config)

      ## salty-vagrant options
      attr_accessor :minion_config
      attr_accessor :minion_key
      attr_accessor :minion_pub
      attr_accessor :master_config
      attr_accessor :master_key
      attr_accessor :master_pub
      attr_accessor :grains_config
      attr_accessor :run_highstate
      attr_accessor :run_overstate
      attr_accessor :orchestrations
      attr_accessor :always_install
      attr_accessor :bootstrap_script
      attr_accessor :verbose
      attr_accessor :seed_master
      attr_accessor :config_dir
      attr_reader   :pillar_data
      attr_accessor :colorize
      attr_accessor :log_level
      attr_accessor :masterless
      attr_accessor :minion_id

      ## bootstrap options
      attr_accessor :temp_config_dir
      attr_accessor :install_type
      attr_accessor :install_args
      attr_accessor :install_master
      attr_accessor :install_syndic
      attr_accessor :install_command
      attr_accessor :no_minion
      attr_accessor :bootstrap_options
      attr_accessor :version
      attr_accessor :run_service
      attr_accessor :master_id

      def initialize
        @minion_config = UNSET_VALUE
        @minion_key = UNSET_VALUE
        @minion_pub = UNSET_VALUE
        @master_config = UNSET_VALUE
        @master_key = UNSET_VALUE
        @master_pub = UNSET_VALUE
        @grains_config = UNSET_VALUE
        @run_highstate = UNSET_VALUE
        @run_overstate = UNSET_VALUE
        @always_install = UNSET_VALUE
        @bootstrap_script = UNSET_VALUE
        @verbose = UNSET_VALUE
        @seed_master = UNSET_VALUE
        @pillar_data = UNSET_VALUE
        @colorize = UNSET_VALUE
        @log_level = UNSET_VALUE
        @temp_config_dir = UNSET_VALUE
        @install_type = UNSET_VALUE
        @install_args = UNSET_VALUE
        @install_master = UNSET_VALUE
        @install_syndic = UNSET_VALUE
        @install_command = UNSET_VALUE
        @no_minion = UNSET_VALUE
        @bootstrap_options = UNSET_VALUE
        @config_dir = UNSET_VALUE
        @masterless = UNSET_VALUE
        @minion_id = UNSET_VALUE
        @version = UNSET_VALUE
        @run_service = UNSET_VALUE
        @master_id = UNSET_VALUE
      end

      def finalize!
        @minion_config      = nil if @minion_config == UNSET_VALUE
        @minion_key         = nil if @minion_key == UNSET_VALUE
        @minion_pub         = nil if @minion_pub == UNSET_VALUE
        @master_config      = nil if @master_config == UNSET_VALUE
        @master_key         = nil if @master_key == UNSET_VALUE
        @master_pub         = nil if @master_pub == UNSET_VALUE
        @grains_config      = nil if @grains_config == UNSET_VALUE
        @run_highstate      = nil if @run_highstate == UNSET_VALUE
        @run_overstate      = nil if @run_overstate == UNSET_VALUE
        @always_install     = nil if @always_install == UNSET_VALUE
        @bootstrap_script   = nil if @bootstrap_script == UNSET_VALUE
        @verbose            = nil if @verbose == UNSET_VALUE
        @seed_master        = nil if @seed_master == UNSET_VALUE
        @pillar_data        = {}  if @pillar_data == UNSET_VALUE
        @colorize           = nil if @colorize == UNSET_VALUE
        @log_level          = nil if @log_level == UNSET_VALUE
        @temp_config_dir    = nil if @temp_config_dir == UNSET_VALUE
        @install_type       = nil if @install_type == UNSET_VALUE
        @install_args       = nil if @install_args == UNSET_VALUE
        @install_master     = nil if @install_master == UNSET_VALUE
        @install_syndic     = nil if @install_syndic == UNSET_VALUE
        @install_command    = nil if @install_command == UNSET_VALUE
        @no_minion          = nil if @no_minion == UNSET_VALUE
        @bootstrap_options  = nil if @bootstrap_options == UNSET_VALUE
        @config_dir         = nil if @config_dir == UNSET_VALUE
        @masterless         = false if @masterless == UNSET_VALUE
        @minion_id          = nil if @minion_id == UNSET_VALUE
        @version            = nil if @version == UNSET_VALUE
        @run_service        = nil if @run_service == UNSET_VALUE
        @master_id          = nil if @master_id == UNSET_VALUE
      end

      def pillar(data)
        @pillar_data = {} if @pillar_data == UNSET_VALUE
        @pillar_data = Vagrant::Util::DeepMerge.deep_merge(@pillar_data, data)
      end

      def default_config_dir(machine)
        guest_type = machine.config.vm.guest || :linux

        # FIXME: there should be a way to do that a bit smarter
        if guest_type == :windows
          return "C:\\salt\\conf"
        else
          return "/etc/salt"
        end
      end

      def validate(machine)
        errors = _detected_errors
        if @minion_config
          expanded = Pathname.new(@minion_config).expand_path(machine.env.root_path)
          if !expanded.file?
            errors << I18n.t("vagrant.provisioners.salt.minion_config_nonexist", missing_config_file: expanded)
          end
        end

        if @master_config
          expanded = Pathname.new(@master_config).expand_path(machine.env.root_path)
          if !expanded.file?
            errors << I18n.t("vagrant.provisioners.salt.master_config_nonexist",  missing_config_file: expanded)
          end
        end

        if @minion_key || @minion_pub
          if !@minion_key || !@minion_pub
            errors << I18n.t("vagrant.provisioners.salt.missing_key")
          end
        end

        if @master_key || @master_pub
          if !@master_key || !@master_pub
            errors << I18n.t("vagrant.provisioners.salt.missing_key")
          end
        end

        if @grains_config
          expanded = Pathname.new(@grains_config).expand_path(machine.env.root_path)
          if !expanded.file?
            errors << I18n.t("vagrant.provisioners.salt.grains_config_nonexist")
          end
        end

        if @install_master && !@no_minion && !@seed_master && @run_highstate
          errors << I18n.t("vagrant.provisioners.salt.must_accept_keys")
        end

        if @config_dir.nil?
          @config_dir = default_config_dir(machine)
        end

        return {"salt provisioner" => errors}
      end
    end
  end
end
