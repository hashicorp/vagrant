require "rbconfig"
platform = RbConfig::CONFIG["host_os"].downcase

source "http://rubygems.org"

gem "vagrant", :path => '.'

# Use the following gems straight from git, since Vagrant dev
# typically coincides with it
gem "virtualbox", :git => "git://github.com/mitchellh/virtualbox.git"

if platform.include?("mingw") || platform.include?("mswin")
  gem "jruby-openssl", "~> 0.7.4", :platforms => :jruby
  gem "jruby-win32ole", "~> 0.8.5", :platforms => :jruby
end

group :test do
  gem "rake"
  gem "contest", ">= 0.1.2"
  gem "mocha"
end
