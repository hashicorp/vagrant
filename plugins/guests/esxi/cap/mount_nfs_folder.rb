module VagrantPlugins
  module GuestEsxi
    module Cap
      class MountNFSFolder
        extend Vagrant::Util::Retryable

        def self.mount_nfs_folder(machine, ip, folders)
          folders.each do |name, opts|
            guestpath = opts[:guestpath]
            volume = guestpath.gsub("/", "_")
            machine.communicate.tap do |comm|
              if comm.test("localcli storage nfs list | grep '^#{volume}'")
                comm.execute("localcli storage nfs remove -v #{volume}")
              end
              mount_command = "localcli storage nfs add -H #{ip} -s '#{opts[:hostpath]}' -v '#{volume}'"
              retryable(on: Vagrant::Errors::LinuxNFSMountFailed, tries: 5, sleep: 2) do
                comm.execute(mount_command,
                             error_class: Vagrant::Errors::LinuxNFSMountFailed)
              end

              # symlink vmfs volume to :guestpath
              if comm.test("test -L '#{guestpath}'")
                comm.execute("rm -f '#{guestpath}'")
              end
              if comm.test("test -d '#{guestpath}'")
                comm.execute("rmdir '#{guestpath}'")
              end
              dir = File.dirname(guestpath)
              if !comm.test("test -d '#{dir}'")
                comm.execute("mkdir -p '#{dir}'")
              end

              comm.execute("ln -s '/vmfs/volumes/#{volume}' '#{guestpath}'")
            end
          end
        end
      end
    end
  end
end
