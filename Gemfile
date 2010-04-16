source :gemcutter

# Gems required for the lib to even run
gem "virtualbox", "~> 0.6.0"
gem "net-ssh", ">= 2.0.19"
gem "net-scp", ">= 1.0.2"
gem "json_pure", ">= 1.2.0"
gem "archive-tar-minitar", "= 0.5.2"
gem "mario", "~> 0.0.6"

# Gems required for testing only. To install run
# gem bundle test
group :test do
  gem "contest", ">= 0.1.2"
  gem "mocha"
  gem "ruby-debug", ">= 0.10.3" if RUBY_VERSION < '1.9'
end
