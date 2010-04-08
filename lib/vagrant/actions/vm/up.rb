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
          steps = [Import, Customize, ForwardPorts, SharedFolders, Boot]
          steps << Provision if !@runner.env.config.vm.provisioner.nil?
          steps.insert(0, MoveHardDrive) if @runner.env.config.vm.hd_location

          steps.each do |action_klass|
            @runner.add_action(action_klass)
          end
        end

        def after_import
          persist
          setup_mac_address
        end

        def persist
          logger.info "Persisting the VM UUID (#{@runner.uuid})..."
          @runner.env.persist_vm
        end

        def setup_mac_address
          logger.info "Matching MAC addresses..."
          @runner.vm.network_adapters.first.mac_address = @runner.env.config.vm.base_mac
          @runner.vm.save
        end
      end
    end
  end
end
