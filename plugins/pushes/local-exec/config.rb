module VagrantPlugins
  module LocalExecPush
    class Config < Vagrant.plugin("2", :config)
      # The path (relative to the machine root) to a local script that will be
      # executed.
      # @return [String]
      attr_accessor :script

      # The command (as a string) to execute.
      # @return [String]
      attr_accessor :inline

      def initialize
        @script = UNSET_VALUE
        @inline = UNSET_VALUE
      end

      def finalize!
        @script = nil if @script == UNSET_VALUE
        @inline = nil if @inline == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        if missing?(@script) && missing?(@inline)
          errors << I18n.t("local_exec_push.errors.missing_attribute",
            attribute: "script",
          )
        end

        if !missing?(@script) && !missing?(@inline)
          errors << I18n.t("local_exec_push.errors.cannot_specify_script_and_inline")
        end

        { "Local Exec push" => errors }
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
