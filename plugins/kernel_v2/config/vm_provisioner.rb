require 'log4r'

module VagrantPlugins
  module Kernel_V2
    # Represents a single configured provisioner for a VM.
    class VagrantConfigProvisioner < Vagrant.plugin("2", :config)
      # Defaults
      VALID_BEFORE_AFTER_TYPES = [:each, :all].freeze

      # Unique name for this provisioner
      #
      # Accepts a string, but is ultimately forced into a symbol in the top level method inside
      # #Config::VM.provision method while being parsed from a Vagrantfile
      #
      # @return [Symbol]
      attr_reader :name

      # Internal unique name for this provisioner
      # Set to the given :name if exists, otherwise
      # it's set as a UUID.
      #
      # Note: This is for internal use only.
      #
      # @return [String]
      attr_reader :id

      # The type of the provisioner that should be registered
      # as a plugin.
      #
      # @return [Symbol]
      attr_reader :type

      # The configuration associated with the provisioner, if there is any.
      #
      # @return [Object]
      attr_accessor :config

      # When to run this provisioner. Either "once", "always", or "never"
      #
      # @return [String]
      attr_accessor :run

      # Whether or not to preserve the order when merging this with a
      # parent scope.
      #
      # @return [Boolean]
      attr_accessor :preserve_order

      # The name of a provisioner to run before it has started
      #
      # @return [String, Symbol]
      attr_accessor :before

      # The name of a provisioner to run after it is finished
      #
      # @return [String, Symbol]
      attr_accessor :after

      # Boolean, when true signifies that some communicator must
      # be available in order for the provisioner to run.
      #
      # @return [Boolean]
      attr_accessor :communicator_required

      def initialize(name, type, **options)
        @logger = Log4r::Logger.new("vagrant::config::vm::provisioner")
        @logger.debug("Provisioner defined: #{name}")

        @id = name || SecureRandom.uuid
        @config  = nil
        @invalid = false
        @name    = name
        @preserve_order = false
        @run     = nil
        @type    = type
        @before  = options[:before]
        @after   = options[:after]
        @communicator_required = options.fetch(:communicator_required, true)

        # Attempt to find the provisioner...
        if !Vagrant.plugin("2").manager.provisioners[type]
          @logger.warn("Provisioner '#{type}' not found.")
          @invalid = true
        end

        # Attempt to find the configuration class for this provider
        # if it exists and load the configuration.
        @config_class = Vagrant.plugin("2").manager.
          provisioner_configs[@type]
        if !@config_class
          @logger.info(
            "Provisioner config for '#{@type}' not found. Ignoring config.")
          @config_class = Vagrant::Config::V2::DummyConfig
        end
      end

      def initialize_copy(orig)
        super
        @config = @config.dup if @config
      end

      def add_config(**options, &block)
        return if invalid?

        current = @config_class.new
        current.set_options(options) if options
        block.call(current) if block
        current = @config.merge(current) if @config
        @config = current
      end

      def finalize!
        return if invalid?

        @config.finalize!
      end

      # Validates the before/after options
      #
      # @param [Vagrant::Machine] machine - machine to validate against
      # @param [Array] provisioners - Array of defined provisioners for the guest machine
      # @return [Array] array of strings of error messages from config option validation
      def validate(machine, provisioners)
        errors = _detected_errors

        provisioner_names = provisioners.map { |i| i.name.to_s if i.name != name }.compact

        if ![TrueClass, FalseClass].include?(@communicator_required.class)
          errors << I18n.t("vagrant.provisioners.base.wrong_type", opt: "communicator_required", type: "boolean")
        end

        if @before && @after
          errors << I18n.t("vagrant.provisioners.base.both_before_after_set")
        end

        if @before
          if !VALID_BEFORE_AFTER_TYPES.include?(@before)
            if @before.is_a?(Symbol) && !VALID_BEFORE_AFTER_TYPES.include?(@before)
              errors << I18n.t("vagrant.provisioners.base.invalid_alias_value", opt: "before", alias: VALID_BEFORE_AFTER_TYPES.join(", "))
            elsif !@before.is_a?(String) && !VALID_BEFORE_AFTER_TYPES.include?(@before)
              errors << I18n.t("vagrant.provisioners.base.wrong_type", opt: "before", type: "string")
            end

            if !provisioner_names.include?(@before)
              errors << I18n.t("vagrant.provisioners.base.missing_provisioner_name",
                               name: @before,
                               machine_name: machine.name,
                               action: "before",
                               provisioner_name: @name)
            end

            dep_prov = provisioners.find_all { |i| i.name.to_s == @before && (i.before || i.after) }

            if !dep_prov.empty?
              errors << I18n.t("vagrant.provisioners.base.dependency_provisioner_dependency",
                               name: @name,
                               dep_name: dep_prov.first.name.to_s)
            end
          end
        end

        if @after
          if !VALID_BEFORE_AFTER_TYPES.include?(@after)
            if @after.is_a?(Symbol)
              errors << I18n.t("vagrant.provisioners.base.invalid_alias_value", opt: "after", alias: VALID_BEFORE_AFTER_TYPES.join(", "))
            elsif !@after.is_a?(String)
              errors << I18n.t("vagrant.provisioners.base.wrong_type", opt: "after", type: "string")
            end

            if !provisioner_names.include?(@after)
              errors << I18n.t("vagrant.provisioners.base.missing_provisioner_name",
                               name: @after,
                               machine_name: machine.name,
                               action: "after",
                               provisioner_name: @name)
            end

            dep_prov = provisioners.find_all { |i| i.name.to_s == @after && (i.before || i.after) }

            if !dep_prov.empty?
              errors << I18n.t("vagrant.provisioners.base.dependency_provisioner_dependency",
                               name: @name,
                               dep_name: dep_prov.first.name.to_s)
            end
          end
        end

        {"provisioner" => errors}
      end

      # Returns whether the provisioner used was invalid or not. A provisioner
      # is invalid if it can't be found.
      #
      # @return [Boolean]
      def invalid?
        @invalid
      end
    end
  end
end
