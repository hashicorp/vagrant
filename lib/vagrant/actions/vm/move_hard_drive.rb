module Vagrant
  module Actions
    module VM
      class MoveHardDrive < Base
        def execute!
          unless @runner.powered_off?
            error_and_exit(<<-error)
The virtual machine must be powered off to move its disk.
error
            return
          end

          destroy_drive_after { clone_and_attach }
        end

        def hard_drive
          @hard_drive ||= find_hard_drive
        end

        # TODO won't work if the first disk is not the boot disk or even if there are multiple disks
        def find_hard_drive
          @runner.storage_controllers.each do |sc|
            sc.devices.each do |d|
              return d if d.image.is_a?(VirtualBox::HardDrive)
            end
          end
        end

        def clone_and_attach
          logger.info "Cloning current VM Disk to new location (#{new_image_path})..."
          hard_drive.image = hard_drive.image.clone(new_image_path, Vagrant.config.vm.disk_image_format, true)

          logger.info "Attaching new disk to VM ..."
          @runner.vm.save
        end

        def destroy_drive_after
          old_image = hard_drive.image

          yield

          logger.info "Destroying old VM Disk (#{old_image.filename})..."
          old_image.destroy(true)
        end

        # Returns the path to the new location for the hard drive
        def new_image_path
          File.join(Vagrant.config.vm.hd_location, hard_drive.image.filename)
        end
      end
    end
  end
end
