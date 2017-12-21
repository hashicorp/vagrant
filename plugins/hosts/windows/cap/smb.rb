module VagrantPlugins
  module HostWindows
    module Cap
      class SMB

        # Number of seconds to display UAC warning to user
        UAC_PROMPT_WAIT = 4

        @@logger = Log4r::Logger.new("vagrant::host::windows::smb")

        def self.smb_installed(env)
          psv = Vagrant::Util::PowerShell.version.to_i
          if psv < 3
            return false
          end

          true
        end

        def self.smb_cleanup(env, machine, opts)
          script_path = File.expand_path("../../scripts/unset_share.ps1", __FILE__)

          m_id = machine_id(machine)
          result = Vagrant::Util::PowerShell.execute_cmd("net share")
          if result.nil?
            @@logger.warn("failed to get current share list")
            return
          end
          prune_shares = result.split("\n").map do |line|
            sections = line.split(/\s/)
            if sections.first.to_s.start_with?("vgt-#{m_id}")
              sections.first
            end
          end.compact
          @@logger.debug("shares to be removed: #{prune_shares}")

          if prune_shares.size > 0
            machine.env.ui.warn("\n" + I18n.t("vagrant_sf_smb.uac.prune_warning") + "\n")
            sleep UAC_PROMPT_WAIT
            @@logger.info("remove shares: #{prune_shares}")
            result = Vagrant::Util::PowerShell.execute(script_path, *prune_shares, sudo: true)
            if result.exit_code != 0
              failed_name = result.stdout.to_s.sub("share name: ", "")
              raise SyncedFolderSMB::Errors::PruneShareFailed,
                name: failed_name,
                stderr: result.stderr,
                stdout: result.stdout
            end
          end
        end

        def self.smb_prepare(env, machine, folders, opts)
          script_path = File.expand_path("../../scripts/set_share.ps1", __FILE__)

          shares = []
          folders.each do |id, data|
            hostpath = data[:hostpath]

            chksum_id = Digest::MD5.hexdigest(id)
            name = "vgt-#{machine_id(machine)}-#{chksum_id}"
            data[:smb_id] ||= name

            @@logger.info("creating new share name=#{name} id=#{data[:smb_id]}")

            shares << [
              "\"#{hostpath.gsub("/", "\\")}\"",
              name,
              data[:smb_id]
            ]
          end
          if !shares.empty?
            machine.env.ui.warn("\n" + I18n.t("vagrant_sf_smb.uac.create_warning") + "\n")
            sleep(UAC_PROMPT_WAIT)
            result = Vagrant::Util::PowerShell.execute(script_path, *shares, sudo: true)
            if result.exit_code != 0
              share_path = result.stdout.to_s.sub("share path: ", "")
              raise SyncedFolderSMB::Errors::DefineShareFailed,
                host: share_path,
                stderr: result.stderr,
                stdout: result.stdout
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
