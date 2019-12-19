require "securerandom"

module VagrantPlugins
  module GuestDarwin
    module Cap
      class MountVmwareSharedFolder

        # we seem to be unable to ask 'mount -t vmhgfs' to mount the roots
        # of specific shares, so instead we symlink from what is already
        # mounted by the guest tools
        # (ie. the behaviour of the VMware_fusion provider prior to 0.8.x)

        def self.mount_vmware_shared_folder(machine, name, guestpath, options)
          # Use this variable to determine which machines
          # have been registered with after hook
          @apply_firmlinks ||= Hash.new{ |h, k| h[k] = {bootstrap: false, content: []} }

          machine.communicate.tap do |comm|
            # check if we are dealing with an APFS root container
            if comm.test("test -d /System/Volumes/Data")
              parts = Pathname.new(guestpath).descend.to_a
              firmlink = parts[1].to_s
              firmlink.slice!(0, 1) if firmlink.start_with?("/")
              if parts.size > 2
                guestpath = File.join("/System/Volumes/Data", guestpath)
              else
                guestpath = nil
              end
            end

            # Remove existing symlink or directory if defined
            if guestpath
              if comm.test("test -L \"#{guestpath}\"")
                comm.sudo("rm -f \"#{guestpath}\"")
              elsif comm.test("test -d \"#{guestpath}\"")
                comm.sudo("rm -Rf \"#{guestpath}\"")
              end

              # create intermediate directories if needed
              intermediate_dir = File.dirname(guestpath)
              if intermediate_dir != "/"
                comm.sudo("mkdir -p \"#{intermediate_dir}\"")
              end

              comm.sudo("ln -s \"/Volumes/VMware Shared Folders/#{name}\" \"#{guestpath}\"")
            end

            if firmlink && !system_firmlink?(firmlink)
              if guestpath.nil?
                guestpath = "/Volumes/VMware Shared Folders/#{name}"
              else
                guestpath = File.join("/System/Volumes/Data", firmlink)
              end

              share_line = "#{firmlink}\t#{guestpath}"

              # Check if the line is already defined. If so, bail since we are done
              if !comm.test("[[ \"$(</etc/synthetic.conf)\" = *\"#{share_line}\"* ]]")
                @apply_firmlinks[machine.id][:bootstrap] = true
              end

              # If we haven't already added our hook to apply firmlinks, do it now
              if @apply_firmlinks[machine.id][:content].empty?
                Plugin.action_hook(:apfs_firmlinks, :after_synced_folders) do |hook|
                  action = proc { |*_|
                    content = @apply_firmlinks[machine.id][:content].join("\n")
                    # Write out the synthetic file
                    comm.sudo("echo -e #{content.inspect} > /etc/synthetic.conf")
                    if @apply_firmlinks[:bootstrap]
                      # Re-bootstrap the root container to pick up firmlink updates
                      comm.sudo("/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B")
                    end
                  }
                  hook.prepend(action)
                end
              end
              @apply_firmlinks[machine.id][:content] << share_line
            end
          end
        end

        # Check if firmlink is provided by the system
        #
        # @param [String] firmlink Firmlink path
        # @return [Boolean]
        def self.system_firmlink?(firmlink)
          if !@_firmlinks
            if File.exist?("/usr/share/firmlinks")
              @_firmlinks = File.readlines("/usr/share/firmlinks").map do |line|
                line.split.first
              end
            else
              @_firmlinks = []
            end
          end
          firmlink = "/#{firmlink}" if !firmlink.start_with?("/")
          @_firmlinks.include?(firmlink)
        end

        # @private
        # Reset the cached values for capability. This is not considered a public
        # API and should only be used for testing.
        def self.reset!
          instance_variables.each(&method(:remove_instance_variable))
        end
      end
    end
  end
end
