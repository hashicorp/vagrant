require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestLinux
    module Cap
      class RemovePublicKey
        def self.remove_public_key(machine, contents)
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            if comm.test("test -f ~/.ssh/authorized_keys")
              comm.execute(<<SCRIPT)
sed -e '/^.*#{contents}.*$/d' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.new
mv ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys
SCRIPT
            end
          end
        end
      end
    end
  end
end
