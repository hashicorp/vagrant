require "pathname"

require "vagrant"

module VagrantPlugins
  module FileUpload
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :source
      attr_accessor :destination

      def validate(machine)
        errors = _detected_errors
        if !source
          errors << I18n.t("vagrant.provisioners.file.no_source_file")
        end
        if !destination
          errors << I18n.t("vagrant.provisioners.file.no_dest_file")
        end
        if source
          s = Pathname.new(source).expand_path(machine.env.root_path)
          if !s.exist?
            errors << I18n.t("vagrant.provisioners.file.path_invalid",
                              path: s.to_s)
          end
        end

        { "File provisioner" => errors }
      end
    end
  end
end
