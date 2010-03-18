module Vagrant
  module Actions
    module VM
      class Up < Base
        def prepare
          # If the dotfile is not a file, raise error
          if File.exist?(Env.dotfile_path) && !File.file?(Env.dotfile_path)
            raise ActionException.new(:dotfile_error)
          end

          # Up is a "meta-action" so it really just queues up a bunch
          # of other actions in its place:
          steps = [Import, Customize, ForwardPorts, SharedFolders, Boot]
          steps << Provision if !Vagrant.config.vm.provisioner.nil?
          steps.insert(0, MoveHardDrive) if Vagrant.config.vm.hd_location

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
          Env.persist_vm(@runner)
        end

        def setup_mac_address
          logger.info "Matching MAC addresses..."
          @runner.vm.nics.first.macaddress = Vagrant.config[:vm][:base_mac]
          @runner.vm.save(true)
        end
      end
    end
  end
end
