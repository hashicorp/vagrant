source :gemcutter
source "http://gems.github.com"

# Gems required for the lib to even run
gem "virtualbox", ">= 0.4.3"
gem "net-ssh", ">= 2.0.19"
gem "jashmenn-git-style-binaries", ">= 0.1.10"

# Gems required for testing only. To install run
# gem bundle test
group :test do
  gem "contest", ">= 0.1.2"
  gem "mocha"
  gem "ruby-debug", ">= 0.10.3" if RUBY_VERSION < '1.9'
end