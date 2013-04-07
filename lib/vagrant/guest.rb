module Vagrant
  module Guest
    autoload :Base, 'vagrant/guest/base'

    # Specific guests
    autoload :Arch,    'vagrant/guest/arch'
    autoload :Debian,  'vagrant/guest/debian'
    autoload :Fedora,  'vagrant/guest/fedora'
    autoload :FreeBSD, 'vagrant/guest/freebsd'
    autoload :Gentoo,  'vagrant/guest/gentoo'
    autoload :Linux,   'vagrant/guest/linux'
    autoload :OpenBSD, 'vagrant/guest/openbsd'
    autoload :Redhat,  'vagrant/guest/redhat'
    autoload :Solaris, 'vagrant/guest/solaris'
    autoload :Suse,    'vagrant/guest/suse'
    autoload :Ubuntu,  'vagrant/guest/ubuntu'
    autoload :Windows, 'vagrant/guest/windows'
  end
end
