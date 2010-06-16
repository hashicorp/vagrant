module Vagrant
  module Actions
    module VM
      class Up < Base
        def prepare
          # If the dotfile is not a file, raise error
          if File.exist?(@runner.env.dotfile_path) && !File.file?(@runner.env.dotfile_path)
            raise ActionException.new(:dotfile_error, :env => @runner.env)
          end

          # Up is a "meta-action" so it really just queues up a bunch
          # of other actions in its place:
          steps = [Import, Start]
          steps.insert(0, MoveHardDrive) if @runner.env.config.vm.hd_location

          steps.each do |action_klass|
            @runner.add_action(action_klass, options)
          end
        end

        def after_import
          update_dotfile
          setup_mac_address
          check_guest_additions
        end

        def update_dotfile
          logger.info "Persisting the VM UUID (#{@runner.uuid})..."
          @runner.env.update_dotfile
        end

        def setup_mac_address
          logger.info "Matching MAC addresses..."
          @runner.vm.network_adapters.first.mac_address = @runner.env.config.vm.base_mac
          @runner.vm.save
        end

        def check_guest_additions
          # Use the raw interface for now, while the virtualbox gem
          # doesn't support guest properties (due to cross platform issues)
          version = @runner.vm.interface.get_guest_property_value("/VirtualBox/GuestAdd/Version")
          if version.empty?
            logger.error Translator.t(:vm_additions_not_detected)
          elsif version != VirtualBox.version
            logger.error Translator.t(:vm_additions_version_mismatch,
                                     :guest_additions_version => version,
                                     :virtualbox_version => VirtualBox.version)
          end
        end
      end
    end
  end
end
