libdir = File.dirname(__FILE__)
PROJECT_ROOT = File.join(libdir, '..') unless defined?(PROJECT_ROOT)

# The libs which must be loaded prior to the rest
%w{tempfile open-uri json pathname logger uri net/http virtualbox net/ssh archive/tar/minitar
  net/scp fileutils mario}.each do |lib|
  require lib
end

# The vagrant specific files which must be loaded prior to the rest
%w{vagrant/util vagrant/util/stacked_proc_runner vagrant/util/progress_meter vagrant/actions/base vagrant/downloaders/base vagrant/actions/collection
  vagrant/actions/runner vagrant/config vagrant/provisioners/base vagrant/provisioners/chef vagrant/commands/base vagrant/commands/box}.each do |f|
  require File.expand_path(f, libdir)
end

# Glob require the rest
Dir[File.join(libdir, "vagrant", "**", "*.rb")].each do |f|
  require File.expand_path(f)
end
