require "tempfile"

module VagrantPlugins
  module GuestWindows
    module Cap
      class PublicKey
        def self.insert_public_key(machine, contents)
          if machine.communicate.is_a?(CommunicatorWinSSH::Communicator)
            winssh_insert_public_key(machine, contents)
          else
            raise Vagrant::Errors::SSHInsertKeyUnsupported
          end
        end

        def self.remove_public_key(machine, contents)
          if machine.communicate.is_a?(CommunicatorWinSSH::Communicator)
            winssh_remove_public_key(machine, contents)
          else
            raise Vagrant::Errors::SSHInsertKeyUnsupported
          end
        end

        def self.winssh_insert_public_key(machine, contents)
          comm = machine.communicate
          contents = contents.strip

          directories = fetch_guest_paths(comm)
          home_dir = directories[:home]
          temp_dir = directories[:temp]

          # Ensure the user's ssh directory exists
          remote_ssh_dir = "#{home_dir}\\.ssh"
          comm.execute("dir \"#{remote_ssh_dir}\"\n if errorlevel 1 (mkdir \"#{remote_ssh_dir}\")", shell: "cmd")
          remote_upload_path = "#{temp_dir}\\vagrant-insert-pubkey-#{Time.now.to_i}"
          remote_authkeys_path = "#{remote_ssh_dir}\\authorized_keys"

          keys_file = Tempfile.new("vagrant-windows-insert-public-key")
          keys_file.close
          # Check if an authorized_keys file already exists
          result = comm.execute("dir \"#{remote_authkeys_path}\"", shell: "cmd", error_check: false)
          if result == 0
            comm.download(remote_authkeys_path, keys_file.path)
            current_content = File.read(keys_file.path).split(/[\r\n]+/)
            if !current_content.include?(contents)
              current_content << contents
            end
            File.write(keys_file.path, current_content.join("\r\n") + "\r\n")
          else
            File.write(keys_file.path, contents + "\r\n")
          end
          comm.upload(keys_file.path, remote_upload_path)
          keys_file.delete
          comm.execute("Set-Acl \"#{remote_upload_path}\" (Get-Acl \"#{remote_authkeys_path}\")", shell: "powershell")
          comm.execute("move /y \"#{remote_upload_path}\" \"#{remote_authkeys_path}\"", shell: "cmd")
        end

        def self.winssh_remove_public_key(machine, contents)
          comm = machine.communicate

          directories = fetch_guest_paths(comm)
          home_dir = directories[:home]
          temp_dir = directories[:temp]

          remote_ssh_dir = "#{home_dir}\\.ssh"
          remote_upload_path = "#{temp_dir}\\vagrant-remove-pubkey-#{Time.now.to_i}"
          remote_authkeys_path = "#{remote_ssh_dir}\\authorized_keys"

          # Check if an authorized_keys file already exists
          result = comm.execute("dir \"#{remote_authkeys_path}\"", shell: "cmd", error_check: false)
          if result == 0
            keys_file = Tempfile.new("vagrant-windows-remove-public-key")
            keys_file.close
            comm.download(remote_authkeys_path, keys_file.path)
            current_content = File.read(keys_file.path).split(/[\r\n]+/)
            current_content.delete(contents)
            File.write(keys_file.path, current_content.join("\r\n") + "\r\n")
            comm.upload(keys_file.path, remote_upload_path)
            keys_file.delete
            comm.execute("Set-Acl \"#{remote_upload_path}\" (Get-Acl \"#{remote_authkeys_path}\")", shell: "powershell")
            comm.execute("move /y \"#{remote_upload_path}\" \"#{remote_authkeys_path}\"", shell: "cmd")
          end
        end

        # Fetch user's temporary and home directory paths from the Windows guest
        #
        # @param [Communicator]
        # @return [Hash] {:temp, :home}
        def self.fetch_guest_paths(communicator)
          output = ""
          communicator.execute("echo %TEMP%\necho %USERPROFILE%", shell: "cmd") do |type, data|
            if type == :stdout
              output << data
            end
          end
          temp_dir, home_dir = output.strip.split(/[\r\n]+/)
          if temp_dir.nil? || home_dir.nil?
            raise Errors::PublicKeyDirectoryFailure
          end
          {temp: temp_dir, home: home_dir}
        end
      end
    end
  end
end
