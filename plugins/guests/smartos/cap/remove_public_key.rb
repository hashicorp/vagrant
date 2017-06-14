require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestSmartos
    module Cap
      class RemovePublicKey
        def self.remove_public_key(machine, contents)
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            comm.execute <<-EOH.sub(/^ */, '')
              if test -f /usbkey/config.inc/authorized_keys ; then
                sed -i '' '/^.*#{contents}.*$/d' /usbkey/config.inc/authorized_keys
              fi
              if test -f ~/.ssh/authorized_keys ; then
                sed -i '' '/^.*#{contents}.*$/d' ~/.ssh/authorized_keys
              fi
            EOH
          end
        end
      end
    end
  end
end
