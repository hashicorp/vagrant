require "vagrant/util/template_renderer"
require "base64"

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
          machine.communicate.execute("cmdkey /add:#{options[:smb_host]} /user:#{options[:smb_username]} /pass:#{options[:smb_password]}", {shell: :powershell, elevated: true})
          mount_shared_folder(machine, name, guestpath, "\\\\#{options[:smb_host]}\\")
        end

        protected

        def self.mount_shared_folder(machine, name, guestpath, vm_provider_unc_base)
          name = name.gsub(/[\/\/]/,'_').sub(/^_/, '')

          path = File.expand_path("../../scripts/mount_volume.ps1", __FILE__)
          script = Vagrant::Util::TemplateRenderer.render(path, options: {
            mount_point: guestpath,
            share_name: name,
            vm_provider_unc_path: vm_provider_unc_base + name,
          })

          if machine.config.vm.communicator == :winrm || machine.config.vm.communicator == :winssh
            machine.communicate.execute(script, shell: :powershell)
          else
            # Convert script to double byte unicode string then base64 encode
            # just like PowerShell -EncodedCommand expects.
            # Suppress the progress stream from leaking to stderr.
            wrapped_encoded_command = Base64.strict_encode64(
              "$ProgressPreference='SilentlyContinue'; #{script}; exit $LASTEXITCODE".encode('UTF-16LE', 'UTF-8'))
            # Execute encoded PowerShell script via OpenSSH shell
            machine.communicate.execute("powershell.exe -noprofile -executionpolicy bypass " +
              "-encodedcommand '#{wrapped_encoded_command}'", shell: "sh")
          end
        end
      end
    end
  end
end
