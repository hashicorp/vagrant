module Vagrant
  module Actions
    module VM
      class SharedFolders < Base
        def shared_folders
          @runner.env.config.vm.shared_folders.inject([]) do |acc, data|
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

          @runner.env.ssh.execute do |ssh|
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
            folder.host_path = hostpath
            @runner.vm.shared_folders << folder
          end

          @runner.vm.save
        end

        def mount_folder(ssh, name, guestpath, sleeptime=5)
          # Note: This method seems pretty OS-specific and could also use
          # some configuration options. For now its duct tape and "works"
          # but should be looked at in the future.

          # Determine the permission string to attach to the mount command
          perms = []
          perms << "uid=#{@runner.env.config.vm.shared_folder_uid}"
          perms << "gid=#{@runner.env.config.vm.shared_folder_gid}"
          perms = " -o #{perms.join(",")}" if !perms.empty?

          attempts = 0
          while true
            result = ssh.exec!("sudo mount -t vboxsf#{perms} #{name} #{guestpath}") do |ch, type, data|
              # net/ssh returns the value in ch[:result] (based on looking at source)
              ch[:result] = !!(type == :stderr && data =~ /No such device/i)
            end

            break unless result

            attempts += 1
            raise ActionException.new(:vm_mount_fail) if attempts >= 10
            sleep sleeptime
          end
        end
      end
    end
  end
end