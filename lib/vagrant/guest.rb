module Vagrant
  module Guest
    autoload :Base, 'vagrant/guest/base'

    # Specific guests
    autoload :Arch,    'vagrant/guest/arch'
    autoload :Debian,  'vagrant/guest/debian'
    autoload :FreeBSD, 'vagrant/guest/freebsd'
    autoload :Gentoo,  'vagrant/guest/gentoo'
    autoload :Linux,   'vagrant/guest/linux'
    autoload :Redhat,  'vagrant/guest/redhat'
    autoload :Fedora,  'vagrant/guest/fedora'
    autoload :Solaris, 'vagrant/guest/solaris'
    autoload :Suse,    'vagrant/guest/suse'
    autoload :Ubuntu,  'vagrant/guest/ubuntu'
  end
end
