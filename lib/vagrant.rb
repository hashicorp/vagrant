libdir = File.join(File.dirname(__FILE__), "vagrant")
PROJECT_ROOT = File.join(libdir, '..', "..") unless defined?(PROJECT_ROOT)

# First, load the various libs which Vagrant requires
%w{tempfile json pathname logger virtualbox net/ssh archive/tar/minitar
  net/scp fileutils mario}.each do |lib|
  require lib
end

# Then load the glob loader, which will handle loading everything else
require File.expand_path("util/glob_loader", libdir)

# Load them up
Vagrant::GlobLoader.glob_require(libdir, %w{util util/stacked_proc_runner
  downloaders/base config provisioners/base provisioners/chef systems/base
  commands/base commands/box action/exception_catcher hosts/base})

# Initialize the built-in actions
Vagrant::Action.builtin!
