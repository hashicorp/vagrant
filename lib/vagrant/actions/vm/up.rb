module Vagrant
  module Actions
    module VM
      class Up < Base
        #First arg should be the ovf_file location for import
        def initialize(vm, *args)
          super vm
          @ovf_file = args[0]
        end

        def prepare
          # Up is a "meta-action" so it really just queues up a bunch
          # of other actions in its place:
          @vm.add_action(Import, @ovf_file)

          steps = [ForwardPorts, SharedFolders, Start]
          steps << Provision if Vagrant.config.chef.enabled
          steps.insert(0, MoveHardDrive) if Vagrant.config.vm.hd_location

          steps.each do |action_klass|
            @vm.add_action(action_klass)
          end
        end

        def collect_shared_folders
          # The root shared folder for the project
          ["vagrant-root", Env.root_path, Vagrant.config.vm.project_directory]
        end

        def after_import
          persist
          setup_mac_address
        end

        def persist
          logger.info "Persisting the VM UUID (#{@vm.vm.uuid})..."
          Env.persist_vm(@vm.vm)
        end

        def setup_mac_address
          logger.info "Matching MAC addresses..."
          @vm.vm.nics.first.macaddress = Vagrant.config[:vm][:base_mac]
          @vm.vm.save(true)
        end
      end
    end
  end
end
