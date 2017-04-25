module Vagrant
  module Util
    # Automatically add deprecation notices to commands
    module CommandDeprecation

      # @return [String] generated name of command
      def deprecation_command_name
        name_parts = self.class.name.split("::")
        [
          name_parts[1].sub('Command', ''),
          name_parts[3]
        ].compact.map(&:downcase).join(" ")
      end

      def self.included(klass)
        klass.class_eval do
          class << self
            if method_defined?(:synopsis)
              alias_method :non_deprecated_synopsis, :synopsis

              def synopsis
                if !non_deprecated_synopsis.to_s.empty?
                  "#{non_deprecated_synopsis} [DEPRECATED]"
                else
                  non_deprecated_synopsis
                end
              end
            end
          end
          alias_method :non_deprecated_execute, :execute

          def execute(*args, &block)
            @env[:ui].warn(I18n.t("vagrant.commands.deprecated",
              name: deprecation_command_name
            ) + "\n")
            non_deprecated_execute(*args, &block)
          end
        end
      end

      # Mark command deprecation complete and fully disable
      # the command's functionality
      module Complete
        def self.included(klass)
          klass.include(CommandDeprecation)
          klass.class_eval do
            def execute(*_)
              raise Vagrant::Errors::CommandDeprecated,
                name: deprecation_command_name
            end
          end
        end
      end
    end
  end
end
