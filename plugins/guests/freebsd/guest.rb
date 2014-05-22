require 'vagrant/util/template_renderer'

module VagrantPlugins
  module GuestFreeBSD
    # A general Vagrant system implementation for "freebsd".
    #
    # Contributed by Kenneth Vestergaard <kvs@binarysolutions.dk>
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep 'FreeBSD'", {shell: "sh"})
      end
    end
  end
end
