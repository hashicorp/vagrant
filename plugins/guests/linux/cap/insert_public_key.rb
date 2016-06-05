module VagrantPlugins
  module GuestLinux
    module Cap
      class InsertPublicKey
        def self.insert_public_key(machine, contents)
          comm = machine.communicate
          contents = contents.chomp

          remote_path = "/tmp/vagrant-authorized-keys-#{Time.now.to_i}"
          Tempfile.open("vagrant-linux-insert-public-key") do |f|
            f.binmode
            f.write(contents)
            f.fsync
            f.close
            comm.upload(f.path, remote_path)
          end

          comm.execute <<-EOH.gsub(/^ {12}/, '')
            mkdir -p ~/.ssh
            chmod 0700 ~/.ssh
            cat '#{remote_path}' >> ~/.ssh/authorized_keys
            chmod 0600 ~/.ssh/authorized_keys

            # Remove the temporary file
            rm -f '#{remote_path}'
          EOH
        end
      end
    end
  end
end
