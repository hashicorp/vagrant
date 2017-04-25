require "tempfile"

require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestEsxi
    module Cap
      class PublicKey
      
        def self.insert_public_key(machine, contents)
          comm = machine.communicate
          contents = contents.strip << "\n"

          remote_path = "/tmp/vagrant-insert-pubkey-#{Time.now.to_i}"
          Tempfile.open("vagrant-esxi-insert-public-key") do |f|
            f.binmode
            f.write(contents)
            f.fsync
            f.close
            comm.upload(f.path, remote_path)
          end

          comm.execute <<-EOH.gsub(/^ {12}/, "")
            set -e
            SSH_DIR="$(grep -q '^AuthorizedKeysFile\s*\/etc\/ssh\/keys-%u\/authorized_keys$' /etc/ssh/sshd_config && echo -n /etc/ssh/keys-${USER} || echo -n ~/.ssh)"
            mkdir -p "${SSH_DIR}"
            chmod 0700 "${SSH_DIR}"
            cat '#{remote_path}' >> "${SSH_DIR}/authorized_keys"
            chmod 0600 "${SSH_DIR}/authorized_keys"
            rm -f '#{remote_path}'
          EOH
        end

        def self.remove_public_key(machine, contents)
          comm = machine.communicate
          contents = contents.strip << "\n"

          remote_path = "/tmp/vagrant-remove-pubkey-#{Time.now.to_i}"
          Tempfile.open("vagrant-esxi-remove-public-key") do |f|
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
            SSH_DIR="$(grep -q '^AuthorizedKeysFile\s*\/etc\/ssh\/keys-%u\/authorized_keys$' /etc/ssh/sshd_config && echo -n /etc/ssh/keys-${USER} || echo -n ~/.ssh)"
            if test -f "${SSH_DIR}/authorized_keys"; then
              grep -v -x -f '#{remote_path}' "${SSH_DIR}/authorized_keys" > "${SSH_DIR}/authorized_keys.tmp"
              mv "${SSH_DIR}/authorized_keys.tmp" "${SSH_DIR}/authorized_keys"
              chmod 0600 "${SSH_DIR}/authorized_keys"
            fi
            rm -f '#{remote_path}'
          EOH
        end
      end
    end
  end
end
