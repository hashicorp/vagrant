source "http://rubygems.org"

gem "vagrant", :path => '.'

# Use the following gems straight from git, since Vagrant dev
# typically coincides with it
gem "virtualbox", :git => "git://github.com/mitchellh/virtualbox.git"
gem "radar", :git => "git://github.com/mitchellh/radar.git"

# Gems required for testing only. To install run
# gem bundle test
group :test do
  gem "rake"
  gem "contest", ">= 0.1.2"
  gem "mocha"
  gem "yard"
  gem "ruby-debug", ">= 0.10.3" if RUBY_VERSION < '1.9'
end
