# First, load the various libs which Vagrant requires
%w{tempfile json pathname logger virtualbox net/ssh archive/tar/minitar
  net/scp fileutils mario}.each do |lib|
  require lib
end

module Vagrant
  class << self
    # The source root is the path to the root directory of
    # the Vagrant gem.
    def source_root
      File.expand_path('../../', __FILE__)
    end
  end
end

# Then load the glob loader, which will handle loading everything else
require "vagrant/util/glob_loader"

# Load them up
libdir = File.expand_path("lib/vagrant", Vagrant.source_root)
Vagrant::GlobLoader.glob_require(libdir, %w{util util/stacked_proc_runner
  downloaders/base config provisioners/base provisioners/chef systems/base
  commands/base commands/box action/exception_catcher hosts/base})

# Initialize the built-in actions
Vagrant::Action.builtin!
