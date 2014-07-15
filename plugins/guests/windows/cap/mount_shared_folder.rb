require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestWindows
    module Cap
      class MountSharedFolder
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\vboxsrv\\")
        end

        def self.mount_vmware_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\vmware-host\\Shared Folders\\")
        end

        def self.mount_parallels_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\psf\\")
        end

        def self.mount_smb_shared_folder(machine, name, guestpath, options)
          mount_shared_folder(machine, name, guestpath, "\\\\#{options[:smb_host]}\\", options)
        end

        protected

        def self.mount_shared_folder(machine, name, guestpath, vm_provider_unc_base, options = {})
          name = name.gsub(/[\/\/]/,'_').sub(/^_/, '')

          path = File.expand_path("../../scripts/mount_volume.ps1", __FILE__)
          script = Vagrant::Util::TemplateRenderer.render(path, options: {
            mount_point: guestpath,
            share_name: name,
            host_share_username: options[:smb_username],
            host_share_password: options[:smb_password],
            vm_provider_unc_path: vm_provider_unc_base + name,
          })

          machine.communicate.execute(script, shell: :powershell)
        end
      end
    end
  end
end
