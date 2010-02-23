libdir = File.dirname(__FILE__)
$:.unshift(libdir)
PROJECT_ROOT = File.join(libdir, '..') unless defined?(PROJECT_ROOT)

# The libs which must be loaded prior to the rest
%w{tempfile open-uri ftools json pathname logger virtualbox net/ssh tarruby
  net/scp fileutils vagrant/util vagrant/actions/base}.each do |f|
  require f
end

# Glob require the rest
Dir[File.join(PROJECT_ROOT, "lib", "vagrant", "**", "*.rb")].each do |f|
  require f
end
