# Gems required for the lib to even run
gem "virtualbox", ">= 0.4.2"
gem "net-ssh", ">= 2.0.19"

source "http://gems.github.com"
gem "jashmenn-git-style-binaries", ">= 0.1.10"

# Gems required for testing only. To install run
# gem bundle test
only :test do
  gem "contest", ">= 0.1.2"
  gem "mocha"
  gem "ruby-debug", ">= 0.10.3" if RUBY_VERSION < '1.9'
end

# Since hobo uses bin/, change the bin_path to something
# else...
bin_path "gembin"

# Makes sure that our code doesn't request gems outside
# of our dependency list.
disable_system_gems