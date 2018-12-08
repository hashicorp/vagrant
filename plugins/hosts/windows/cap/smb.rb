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

        # Required options for mounting a share hosted on Windows
        # NOTE: Windows deprecated smb 1.0 so a minimum of 2.0 must be enabled
        def self.smb_mount_options(env)
          ["vers=2.0"]
        end

        def self.smb_validate_password(env, machine, username, password)
          script_path = File.expand_path("../../scripts/check_credentials.ps1", __FILE__)
          args = []
          args << "-username" << "'#{username.gsub("'", "''")}'"
          args << "-password" << "'#{password.gsub("'", "''")}'"

          r = Vagrant::Util::PowerShell.execute(script_path, *args)
          r.exit_code == 0
        end

        def self.smb_cleanup(env, machine, opts)
          script_path = File.expand_path("../../scripts/unset_share.ps1", __FILE__)

          m_id = machine_id(machine)
          prune_shares = existing_shares.map do |share_name, share_info|
            if share_info["Description"].to_s.start_with?("vgt-#{m_id}-")
              @@logger.info("removing smb share name=#{share_name} id=#{m_id}")
              share_name
            else
              @@logger.info("skipping smb share removal, not owned name=#{share_name}")
              @@logger.debug("smb share ID not present name=#{share_name} id=#{m_id} description=#{share_info["Description"]}")
              nil
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
          current_shares = existing_shares
          folders.each do |id, data|
            hostpath = data[:hostpath].to_s

            chksum_id = Digest::MD5.hexdigest(id)
            name = "vgt-#{machine_id(machine)}-#{chksum_id}"
            data[:smb_id] ||= name

            # Check if this name is already in use
            if share_info = current_shares[data[:smb_id]]
              exist_path = File.expand_path(share_info["Path"]).downcase
              request_path = File.expand_path(hostpath).downcase
              if !hostpath.empty? && exist_path != request_path
                raise SyncedFolderSMB::Errors::SMBNameError,
                  path: hostpath,
                  existing_path: share_info["Path"],
                  name: data[:smb_id]
              end
              @@logger.info("skip creation of existing share name=#{name} id=#{data[:smb_id]}")
              next
            end

            @@logger.info("creating new share name=#{name} id=#{data[:smb_id]}")

            shares << [
              "\"#{hostpath.gsub("/", "\\")}\"",
              name,
              data[:smb_id]
            ]
          end
          if !shares.empty?
            uac_notified = false
            shares.each_slice(10) do |s_shares|
              if !uac_notified
                machine.env.ui.warn("\n" + I18n.t("vagrant_sf_smb.uac.create_warning") + "\n")
                uac_notified = true
                sleep(UAC_PROMPT_WAIT)
              end
              result = Vagrant::Util::PowerShell.execute(script_path, *s_shares, sudo: true)
              if result.exit_code != 0
                share_path = result.stdout.to_s.sub("share path: ", "")
                raise SyncedFolderSMB::Errors::DefineShareFailed,
                  host: share_path,
                  stderr: result.stderr,
                  stdout: result.stdout
              end
            end
          end
        end

        # Generate a list of existing local smb shares
        #
        # @return [Hash]
        def self.existing_shares
          shares = get_smbshares || get_netshares
          if shares.nil?
            raise SyncedFolderSMB::Errors::SMBListFailed
          end
          @@logger.debug("local share listing: #{shares}")
          shares
        end

        # Get current SMB share list using Get-SmbShare
        #
        # @return [Hash]
        def self.get_smbshares
          result = Vagrant::Util::PowerShell.execute_cmd("Get-SmbShare|Format-List|Out-String -Width 4096")
          if result.nil?
            return nil
          end
          share_data = result.strip.lines
          shares = {}
          name = nil
          until share_data.empty?
            content = share_data.take_while{|line| !line.strip.empty? }
            share_name = content[0].strip.split(":", 2).last.strip
            shares[share_name] = {
              "Path" => content[-2].strip.split(":", 2).last.strip,
              "Description" => content[-1].strip.split(":", 2).last.strip
            }
            share_data.slice!(0, content.length + 1)
          end
          shares
        end

        # Get current SMB share list using net.exe
        #
        # @return [Hash]
        def self.get_netshares
          result = Vagrant::Util::PowerShell.execute_cmd("net share | Out-String -Width 4096")
          if result.nil?
            return nil
          end
          share_data = result.strip.lines
          # Remove header information
          share_data.slice!(0, 2)
          # Remove footer information
          share_data.slice!(share_data.size - 1, share_data.size)
          share_names = share_data.map do |line|
            line.strip.split(/\s+/).first.strip
          end
          shares = {}
          share_names.each do |share_name|
            result = Vagrant::Util::PowerShell.execute_cmd("net share #{share_name} |  Out-String -Width 4096")
            next if result.nil?
            result.strip!
            share_info = result.lines
            shares[share_name] = {
              "Path" => share_info[1].split(/\s+/, 2).last.strip,
              "Description" => share_info[2].split(/\s+/, 2).last.strip
            }
          end
          shares
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
