require "rbconfig"
platform = RbConfig::CONFIG["host_os"].downcase

source "http://rubygems.org"

gemspec

# Use the following gems straight from git, since Vagrant dev
# typically coincides with it
gem "virtualbox", :git => "git://github.com/mitchellh/virtualbox.git"

if platform.include?("mingw") || platform.include?("mswin")
  # JRuby requires these gems for development, but only
  # on windows.
  gem "jruby-openssl", "~> 0.7.4", :platforms => :jruby
  gem "jruby-win32ole", "~> 0.8.5", :platforms => :jruby
end
