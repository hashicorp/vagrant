module VagrantPlugins
  module HostWindows
    module Cap
      class SMB
        @@logger = Log4r::Logger.new("vagrant::windows_host::capabilities::smb")
        
        def self.smb_installed(env)
          if !Vagrant::Util::Platform.windows_admin?
            raise Errors::WindowsAdminRequired if raise_error
            return false
          end

          psv = Vagrant::Util::PowerShell.version.to_i
          if psv < 3
            if raise_error
              raise Errors::PowershellVersion,
                version: psv.to_s
            end
            return false
          end
          return true
        end

        def self.smb_share(env, folders, machine_id)
          script_path = File.expand_path("../scripts/set_share.ps1", __FILE__)

          folders.each do |id, data|
            hostpath = data[:hostpath]

            data[:smb_id] ||= Digest::MD5.hexdigest(
              "#{machine_id}-#{id.gsub("/", "-")}")

            args = []
            args << "-path" << "\"#{hostpath.gsub("/", "\\")}\""
            args << "-share_name" << data[:smb_id]

            r = Vagrant::Util::PowerShell.execute(script_path, *args)
            if r.exit_code != 0
              raise Errors::DefineShareFailed,
                host: hostpath.to_s,
                stderr: r.stderr,
                stdout: r.stdout
            end
          end
        end
      end
    end
  end
end
