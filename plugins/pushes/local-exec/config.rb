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

      # The arguments to provide when executing the script.
      # @return [Array<String>]
      attr_accessor :args

      def initialize
        @script = UNSET_VALUE
        @inline = UNSET_VALUE
        @args   = UNSET_VALUE
      end

      def finalize!
        @script = nil if @script == UNSET_VALUE
        @inline = nil if @inline == UNSET_VALUE
        @args   = nil if @args == UNSET_VALUE

        if @args && args_valid?
          @args = @args.is_a?(Array) ? @args.map { |a| a.to_s } : @args.to_s
        end
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

        if !args_valid?
          errors << I18n.t("local_exec_push.errors.args_bad_type")
        end

        { "Local Exec push" => errors }
      end

      private

      # Determine if the given string is "missing" (blank)
      # @return [true, false]
      def missing?(obj)
        obj.to_s.strip.empty?
      end

      # Args are optional, but if they're provided we only support them as a
      # string or as an array.
      def args_valid?
        return true if !args
        return true if args.is_a?(String)
        return true if args.is_a?(Integer)
        if args.is_a?(Array)
          args.each do |a|
            return false if !a.kind_of?(String) && !a.kind_of?(Integer)
          end

          return true
        end
      end
    end
  end
end
