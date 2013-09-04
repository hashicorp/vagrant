require "i18n"
require "vagrant"

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
      attr_accessor :run_highstate
      attr_accessor :always_install
      attr_accessor :bootstrap_script
      attr_accessor :verbose
      attr_accessor :seed_master
      attr_reader   :pillar_data

      ## bootstrap options
      attr_accessor :temp_config_dir
      attr_accessor :install_type
      attr_accessor :install_args
      attr_accessor :install_master
      attr_accessor :install_syndic
      attr_accessor :no_minion
      attr_accessor :bootstrap_options

      def initialize
        @minion_config = UNSET_VALUE
        @minion_key = UNSET_VALUE
        @minion_pub = UNSET_VALUE
        @master_config = UNSET_VALUE
        @master_key = UNSET_VALUE
        @master_pub = UNSET_VALUE
        @run_highstate = UNSET_VALUE
        @always_install = UNSET_VALUE
        @bootstrap_script = UNSET_VALUE
        @verbose = UNSET_VALUE
        @seed_master = UNSET_VALUE
        @pillar_data = UNSET_VALUE
        @temp_config_dir = UNSET_VALUE
        @install_type = UNSET_VALUE
        @install_args = UNSET_VALUE
        @install_master = UNSET_VALUE
        @install_syndic = UNSET_VALUE
        @no_minion = UNSET_VALUE
        @bootstrap_options = UNSET_VALUE
      end

      def finalize!
        @minion_config      = nil if @minion_config == UNSET_VALUE
        @minion_key         = nil if @minion_key == UNSET_VALUE
        @minion_pub         = nil if @minion_pub == UNSET_VALUE
        @master_config      = nil if @master_config == UNSET_VALUE
        @master_key         = nil if @master_key == UNSET_VALUE
        @master_pub         = nil if @master_pub == UNSET_VALUE
        @run_highstate      = nil if @run_highstate == UNSET_VALUE
        @always_install     = nil if @always_install == UNSET_VALUE
        @bootstrap_script   = nil if @bootstrap_script == UNSET_VALUE
        @verbose            = nil if @verbose == UNSET_VALUE
        @seed_master        = nil if @seed_master == UNSET_VALUE
        @pillar_data        = {}  if @pillar_data == UNSET_VALUE
        @temp_config_dir    = nil if @temp_config_dir == UNSET_VALUE
        @install_type       = nil if @install_type == UNSET_VALUE
        @install_args       = nil if @install_args == UNSET_VALUE
        @install_master     = nil if @install_master == UNSET_VALUE
        @install_syndic     = nil if @install_syndic == UNSET_VALUE
        @no_minion          = nil if @no_minion == UNSET_VALUE
        @bootstrap_options  = nil if @bootstrap_options == UNSET_VALUE

      end

      def pillar(data)
        @pillar_data = {} if @pillar_data == UNSET_VALUE
        @pillar_data.deep_merge!(data)
      end

      def validate(machine)
        errors = _detected_errors
        if @minion_key || @minion_pub
          if !@minion_key || !@minion_pub
            errors << @minion_pub
          end
        end

        if @master_key && @master_pub
          if !@minion_key && !@minion_pub
            errors << I18n.t("salt.missing_key")
          end
        end

        if @install_master && !@no_minion && !@seed_master && @run_highstate
          errors << I18n.t("salt.must_accept_keys")
        end

        return {"salt" => errors}
      end


    end
  end
end
