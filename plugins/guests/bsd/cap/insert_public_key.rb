require "tempfile"

module VagrantPlugins
  module GuestBSD
    module Cap
      class InsertPublicKey
        def self.insert_public_key(machine, contents)
          comm = machine.communicate
          contents = contents.strip << "\n"

          remote_path = "/tmp/vagrant-authorized-keys-#{Time.now.to_i}"
          Tempfile.open("vagrant-bsd-insert-public-key") do |f|
            f.binmode
            f.write(contents)
            f.fsync
            f.close
            comm.upload(f.path, remote_path)
          end

          # Use execute (not sudo) because we want to execute this as the SSH
          # user (which is "vagrant" by default).
          comm.execute <<-EOH.gsub(/^ {12}/, '')
            set -e
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
