begin
  require File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'environment')
rescue LoadError
  puts <<-ENVERR
==================================================
ERROR: Gem environment file not found!

Hobo uses bundler to handle gem dependencies. To setup the
test environment, please run `gem bundle test` If you don't
have bundler, you can install that with `gem install bundler`
==================================================
ENVERR
  exit
end

# ruby-debug, not necessary, but useful if we have it
begin
  require 'ruby-debug'
rescue LoadError; end

require 'contest'