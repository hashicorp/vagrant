require "digest/md5"

require "vagrant/util/powershell"

module VagrantPlugins
  module HostWindows
    module Cap
      class SMB
        def self.create_smb_share(env, machine, id, data)
          script_path = File.expand_path("../../scripts/set_share.ps1", __FILE__)

          hostpath = data[:hostpath]

          data[:smb_id] ||= Digest::MD5.hexdigest(
            "#{machine.id}-#{id.gsub("/", "-")}")

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
