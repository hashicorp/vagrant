module VagrantPlugins
  module LocalExecPush
    class Config < Vagrant.plugin("2", :config)
      # The command (as a string) to execute.
      # @return [String]
      attr_accessor :command

      def initialize
        @command = UNSET_VALUE
      end

      def finalize!
        @command = nil if @command == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        if missing?(@command)
          errors << I18n.t("local_exec_push.errors.missing_attribute",
            attribute: "command",
          )
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
