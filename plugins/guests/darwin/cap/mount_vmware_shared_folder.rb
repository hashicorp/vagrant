module VagrantPlugins
  module GuestDarwin
    module Cap
      class MountVmwareSharedFolder

        # we seem to be unable to ask 'mount -t vmhgfs' to mount the roots
        # of specific shares, so instead we symlink from what is already
        # mounted by the guest tools 
        # (ie. the behaviour of the VMware_fusion provider prior to 0.8.x)

        def self.mount_vmware_shared_folder(machine, name, guestpath, options)
          machine.communicate.tap do |comm|
            # clear prior symlink
            if comm.test("test -L \"#{guestpath}\"", sudo: true)
              comm.sudo("rm -f \"#{guestpath}\"")
            end

            # clear prior directory if exists
            if comm.test("test -d \"#{guestpath}\"", sudo: true)
              comm.sudo("rm -Rf \"#{guestpath}\"")
            end

            # create intermediate directories if needed
            intermediate_dir = File.dirname(guestpath)
            if !comm.test("test -d \"#{intermediate_dir}\"", sudo: true)
              comm.sudo("mkdir -p \"#{intermediate_dir}\"")
            end

            # finally make the symlink
            comm.sudo("ln -s \"/Volumes/VMware Shared Folders/#{name}\" \"#{guestpath}\"")
          end
        end
      end
    end
  end
end
