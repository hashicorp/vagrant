require "tempfile"

require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestLinux
    module Cap
      class PublicKey
        def self.insert_public_key(machine, contents)
          comm = machine.communicate
          contents = contents.strip << "\n"

          remote_path = "/tmp/vagrant-insert-pubkey-#{Time.now.to_i}"
          Tempfile.open("vagrant-linux-insert-public-key") do |f|
            f.binmode
            f.write(contents)
            f.fsync
            f.close
            comm.upload(f.path, remote_path)
          end

          # Use execute (not sudo) because we want to execute this as the SSH
          # user (which is "vagrant" by default).
          comm.execute <<-EOH.gsub(/^ {12}/, "")
            set -e

            mkdir -p ~/.ssh
            chmod 0700 ~/.ssh
            cat '#{remote_path}' >> ~/.ssh/authorized_keys
            chmod 0600 ~/.ssh/authorized_keys

            rm -f '#{remote_path}'
          EOH
        end

        def self.remove_public_key(machine, contents)
          comm = machine.communicate
          contents = contents.strip << "\n"

          remote_path = "/tmp/vagrant-remove-pubkey-#{Time.now.to_i}"
          Tempfile.open("vagrant-linux-remove-public-key") do |f|
            f.binmode
            f.write(contents)
            f.fsync
            f.close
            comm.upload(f.path, remote_path)
          end

          # Use execute (not sudo) because we want to execute this as the SSH
          # user (which is "vagrant" by default).
          comm.execute <<-EOH.sub(/^ {12}/, "")
            set -e

            if test -f ~/.ssh/authorized_keys; then
              grep -v -x -f '#{remote_path}' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp
              mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys
              chmod 0600 ~/.ssh/authorized_keys
            fi

            rm -f '#{remote_path}'
          EOH
        end
      end
    end
  end
end
