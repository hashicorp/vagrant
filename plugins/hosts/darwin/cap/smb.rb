require "digest/md5"
require "open3"

module VagrantPlugins
  module HostDarwin
    module Cap
      class SMB
        class << self
          private
          def sudo(command, raise_error=true)
            stdout, stderr, status = Open3.capture3("sudo -S #{command}", :stdin_data => "#{@user_password}\n")
            if status.exitstatus != 0 && raise_error
              raise Errors::SudoCommandFailed,
                command: command,
                stderr:  stderr,
                stdout:  stdout
            end
          end
        end

        def self.create_smb_share(env, machine, id, data)
          data[:smb_id] ||= Digest::MD5.hexdigest("#{machine.id}-#{id.gsub("/", "-")}")

          sudo("sharing -r #{data[:smb_id]}", false)
          sudo("PWD=$(pwd) sharing -a #{data[:hostpath]} -S #{data[:smb_id]} -s 001 -g 000 -n #{data[:smb_id]}")
        end

        def self.enable_smb_sharing(env, folders, credentials)
          # Credentials are actually enclosed in a lambda
          credentials = credentials.call

          # Determine who am I
          current_user  = `id -un`.chomp

          # For each shared folder, SMB user MUST match current user
          folders.each do |id, data|
            smb_user = data[:smb_username] || credentials[:username]
            unless smb_user == current_user
              raise Errors::WrongUser, current_user: current_user
            end
          end

          # Invalidate existing sudo session, if present
          system("sudo -k")

          # Get the user password and store it in a Class instance variable
          @user_password = folders.values.first[:smb_password] || credentials[:password]

          # Start the SMB daemon if not already running
          sudo("launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist")
          sudo("defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server EnabledServices -array disk")

          # Enable SMB sharing for the given user
          sudo("pwpolicy -u #{current_user} -sethashtypes SMB-NT on")
          sudo("dscl . -passwd /Users/#{current_user} '#{@user_password}'")
        end
      end
    end
  end
end
