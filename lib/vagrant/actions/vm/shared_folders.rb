module Vagrant
  module Actions
    module VM
      class SharedFolders < Base
        def shared_folders
          Vagrant.config.vm.shared_folders.inject([]) do |acc, data|
            name, value = data
            acc << [name, File.expand_path(value[:hostpath]), value[:guestpath]]
          end
        end

        def before_boot
          clear_shared_folders
          create_metadata
        end

        def after_boot
          logger.info "Mounting shared folders..."

          Vagrant::SSH.execute do |ssh|
            shared_folders.each do |name, hostpath, guestpath|
              logger.info "-- #{name}: #{guestpath}"
              ssh.exec!("sudo mkdir -p #{guestpath}")
              mount_folder(ssh, name, guestpath)
              ssh.exec!("sudo chown #{Vagrant.config.ssh.username} #{guestpath}")
            end
          end
        end

        def clear_shared_folders
          logger.info "Clearing previously set shared folders..."

          @runner.vm.shared_folders.each do |shared_folder|
            shared_folder.destroy
          end

          @runner.reload!
        end

        def create_metadata
          logger.info "Creating shared folders metadata..."

          shared_folders.each do |name, hostpath, guestpath|
            folder = VirtualBox::SharedFolder.new
            folder.name = name
            folder.hostpath = hostpath
            @runner.vm.shared_folders << folder
          end

          @runner.vm.save(true)
        end

        def mount_folder(ssh, name, guestpath, sleeptime=5)
          # Note: This method seems pretty OS-specific and could also use
          # some configuration options. For now its duct tape and "works"
          # but should be looked at in the future.
          attempts = 0

          while true
            result = ssh.exec!("sudo mount -t vboxsf #{name} #{guestpath}") do |ch, type, data|
              # net/ssh returns the value in ch[:result] (based on looking at source)
              ch[:result] = !!(type == :stderr && data =~ /No such device/i)
            end

            break unless result

            attempts += 1
            raise ActionException.new("Failed to mount shared folders. vboxsf was not available.") if attempts >= 10
            sleep sleeptime
          end
        end
      end
    end
  end
end