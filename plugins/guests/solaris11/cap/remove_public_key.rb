require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestSolaris11
    module Cap
      class RemovePublicKey
        def self.remove_public_key(machine, contents)
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            if comm.test("test -f ~/.ssh/authorized_keys")
              comm.execute(
                "sed -i '/^.*#{contents}.*$/d' ~/.ssh/authorized_keys")
            end
          end
        end
      end
    end
  end
end
