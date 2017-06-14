require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestSmartos
    module Cap
      class InsertPublicKey
        def self.insert_public_key(machine, contents)
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            comm.execute <<-EOH.sub(/^ */, '')
              if [ -d /usbkey ] && [ "$(zonename)" == "global" ] ; then
                printf '#{contents}\\n' >> /usbkey/config.inc/authorized_keys
                cp /usbkey/config.inc/authorized_keys ~/.ssh/authorized_keys
              else
                mkdir -p ~/.ssh
                chmod 0700 ~/.ssh
                printf '#{contents}\\n' >> ~/.ssh/authorized_keys
                chmod 0600 ~/.ssh/authorized_keys
              fi
            EOH
          end
        end
      end
    end
  end
end
