module Vagrant
  module Actions
    module VM
      class SharedFolders < Base
        def shared_folders
          shared_folders = @vm.invoke_callback(:collect_shared_folders)

          # Basic filtering of shared folders. Basically only verifies that
          # the result is an array of 3 elements. In the future this should
          # also verify that the host path exists, the name is valid,
          # and that the guest path is valid.
          shared_folders.collect do |folder|
            if folder.is_a?(Array) && folder.length == 3
              folder
            else
              nil
            end
          end.compact
        end

        def before_boot
          logger.info "Creating shared folders metadata..."

          shared_folders.each do |name, hostpath, guestpath|
            folder = VirtualBox::SharedFolder.new
            folder.name = name
            folder.hostpath = hostpath
            @vm.vm.shared_folders << folder
          end

          @vm.vm.save(true)
        end

        def after_boot
          logger.info "Mounting shared folders..."

          Vagrant::SSH.execute do |ssh|
            shared_folders.each do |name, hostpath, guestpath|
              logger.info "-- #{name}: #{guestpath}"
              ssh.exec!("sudo mkdir -p #{guestpath}")
              ssh.exec!("sudo mount -t vboxsf #{name} #{guestpath}")
              ssh.exec!("sudo chown #{Vagrant.config.ssh.username} #{guestpath}")
            end
          end
        end
      end
    end
  end
end