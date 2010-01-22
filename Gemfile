# Gems required for the lib to even run
gem "net-ssh", ">= 2.0.19"

# Gems required for testing only. To install run
# gem bundle test
only :test do
  gem "contest", ">= 0.1.2"
  gem "mocha", ">= 0.9.8"
  gem "ruby-debug", ">= 0.10.3" if RUBY_VERSION < '1.9'
end

# Since hobo uses bin/, change the bin_path to something
# else...
bin_path "bin/gembin"

# Makes sure that our code doesn't request gems outside
# of our dependency list.
disable_system_gems