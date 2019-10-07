module VagrantPlugins
  module FileUpload
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        @machine.communicate.tap do |comm|
          source = File.expand_path(config.source, @machine.env.cwd)
          destination = expand_guest_path(config.destination)

          # If the source is a directory determine if any path modifications
          # need to be applied to the source for upload behavior. If the original
          # source value ends with a "." or if the original source does not end
          # with a "." but the original destination ends with a file separator
          # then append a "." character to the new source. This ensures that
          # the contents of the directory are uploaded to the destination and
          # not folder itself.
          if File.directory?(source)
            if config.source.end_with?(".") ||
                (!config.destination.end_with?(File::SEPARATOR) &&
                !config.source.end_with?("#{File::SEPARATOR}."))
              source = File.join(source, ".")
            end
          end

          @machine.ui.detail(I18n.t("vagrant.actions.vm.provision.file.locations",
                                   src: config.source, dst: config.destination))
          # now upload the file
          comm.upload(source, destination)
        end
      end

      private

      # Expand the guest path if the guest has the capability
      def expand_guest_path(destination)
        if machine.guest.capability?(:shell_expand_guest_path)
          machine.guest.capability(:shell_expand_guest_path, destination)
        else
          destination
        end
      end
    end
  end
end
