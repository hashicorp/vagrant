require "pathname"
require "log4r"

module VagrantPlugins
  module HostLinux
    module Cap
      class SMB
        @@logger = Log4r::Logger.new("vagrant::linux_host::capabilities::smb")

        def self.smb_installed(env)
          !!Vagrant::Util::Which.which("smbd")
        end

        def self.smb_share(env, folders, machine_id)
          script_path = "/usr/bin/net usershare add"

          folders.each do |id, data|
            hostpath = data[:hostpath]
            @@logger.debug("Pre-hash name: #{machine_id}-#{id.gsub("/", "-")}")
            data[:smb_id] ||= "#{Digest::MD5.hexdigest(machine_id)}-#{Digest::MD5.hexdigest(id.gsub("/", "-"))}"
            command = "#{script_path} #{data[:smb_id]} #{hostpath} \"Vagrant Share\" Everyone:F"
            @@logger.debug("command: " + command)
            command_result = system(command)
            @@logger.debug ("command result: #{command_result}")
          end
        end

      end
    end
  end
end
