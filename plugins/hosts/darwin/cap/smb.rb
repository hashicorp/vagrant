module VagrantPlugins
  module HostDarwin
    module Cap
      class SMB

        @@logger = Log4r::Logger.new("vagrant::host::darwin::smb")

        # If we have the sharing binary available, smb is installed
        def self.smb_installed(env)
          File.exist?("/usr/sbin/sharing")
        end

        # Check if the required SMB services are loaded and enabled. If they are
        # not, then start them up
        def self.smb_start(env)
          result = Vagrant::Util::Subprocess.execute("pwpolicy", "gethashtypes")
          if result.exit_code == 0 && !result.stdout.include?("SMB-NT")
            @@logger.error("SMB compatible password has not been stored")
            raise SyncedFolderSMB::Errors::SMBCredentialsMissing
          end
          result = Vagrant::Util::Subprocess.execute("launchctl", "list", "com.apple.smb.preferences")
          if result.exit_code != 0
            @@logger.warn("smb preferences service not enabled. enabling and starting...")
            cmd = ["/bin/launchctl", "load", "-w", "/System/Library/LaunchDaemons/com.apple.smb.preferences.plist"]
            result = Vagrant::Util::Subprocess.execute("/usr/bin/sudo", *cmd)
            if result.exit_code != 0
              raise SyncedFolderSMB::Errors::SMBStartFailed,
                command: cmd.join(" "),
                stderr: result.stderr,
                stdout: result.stdout
            end
          end
          result = Vagrant::Util::Subprocess.execute("launchctl", "list", "com.apple.smbd")
          if result.exit_code != 0
            @@logger.warn("smbd service not enabled. enabling and starting...")
            cmd = ["/bin/launchctl", "load", "-w", "/System/Library/LaunchDaemons/com.apple.smbd.plist"]
            result = Vagrant::Util::Subprocess.execute("/usr/bin/sudo", *cmd)
            if result.exit_code != 0
              raise SyncedFolderSMB::Errors::SMBStartFailed,
                command: cmd.join(" "),
                stderr: result.stderr,
                stdout: result.stdout
            end
            Vagrant::Util::Subprocess.execute("/usr/bin/sudo", "/bin/launchctl", "start", "com.apple.smbd")
          end
        end

        # Required options for mounting a share hosted
        # on macos.
        def self.smb_mount_options(env)
          ["sec=ntlmssp", "nounix", "noperm"]
        end

        def self.smb_cleanup(env, machine, opts)
          m_id = machine_id(machine)
          result = Vagrant::Util::Subprocess.execute("/usr/bin/sudo", "/usr/sbin/sharing", "-l")
          if result.exit_code != 0
            @@logger.warn("failed to locate any shares for cleanup")
          end
          shares = result.stdout.split("\n").map do |line|
            if line.start_with?("name:")
              share_name = line.sub("name:", "").strip
              share_name if share_name.start_with?("vgt-#{m_id}")
            end
          end.compact
          @@logger.debug("shares to be removed: #{shares}")
          shares.each do |share_name|
            @@logger.info("removing share name=#{share_name}")
            share_name.strip!
            result = Vagrant::Util::Subprocess.execute("/usr/bin/sudo",
              "/usr/sbin/sharing", "-r", share_name)
            if result.exit_code != 0
              # Removing always returns 0 even if there are currently
              # guests attached so if we get a non-zero value just
              # log it as unexpected
              @@logger.warn("removing share `#{share_name}` returned non-zero")
            end
          end
        end

        def self.smb_prepare(env, machine, folders, opts)
          folders.each do |id, data|
            hostpath = data[:hostpath]

            chksum_id = Digest::MD5.hexdigest(id)
            name = "vgt-#{machine_id(machine)}-#{chksum_id}"
            data[:smb_id] ||= name

            @@logger.info("creating new share name=#{name} id=#{data[:smb_id]}")

            cmd = [
              "/usr/bin/sudo",
              "/usr/sbin/sharing",
              "-a", hostpath,
              "-S", data[:smb_id],
              "-s", "001",
              "-g", "000",
              "-n", name
            ]

            r = Vagrant::Util::Subprocess.execute(*cmd)

            if r.exit_code != 0
              raise VagrantPlugins::SyncedFolderSMB::Errors::DefineShareFailed,
                host: hostpath.to_s,
                stderr: r.stderr,
                stdout: r.stdout
            end
          end
        end

        # Generates a unique identifier for the given machine
        # based on the name, provider name, and working directory
        # of the environment.
        #
        # @param [Vagrant::Machine] machine
        # @return [String]
        def self.machine_id(machine)
          @@logger.debug("generating machine ID name=#{machine.name} cwd=#{machine.env.cwd}")
          Digest::MD5.hexdigest("#{machine.name}-#{machine.provider_name}-#{machine.env.cwd}")
        end
      end
    end
  end
end
