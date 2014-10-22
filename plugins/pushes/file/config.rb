module VagrantPlugins
  module FileDeploy
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :destination

      def initialize
        @destination = UNSET_VALUE
      end

      def finalize!
        @destination = nil if @destination == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        # Validate that a destination was provided
        if !destination
          errors << I18n.t("vagrant.pushes.file.no_destination")
        end

        { "File push" => errors }
      end
    end
  end
end
