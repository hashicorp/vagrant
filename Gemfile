source :gemcutter

# Gems required for the lib to even run
gem "virtualbox", :git => "git://github.com/mitchellh/virtualbox.git"
gem "net-ssh", ">= 2.0.19"
gem "net-scp", ">= 1.0.2"
gem "json", ">= 1.2.4"
gem "archive-tar-minitar", "= 0.5.2"
gem "mario", "~> 0.0.6"
gem "jeweler", "~> 1.4.0"

# Gems required for testing only. To install run
# gem bundle test
group :test do
  gem "contest", ">= 0.1.2"
  gem "mocha"
  gem "ruby-debug", ">= 0.10.3" if RUBY_VERSION < '1.9'
end
