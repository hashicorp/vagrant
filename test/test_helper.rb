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

# This silences logger output
ENV['HOBO_ENV'] = 'test'

# ruby-debug, not necessary, but useful if we have it
begin
  require 'ruby-debug'
rescue LoadError; end


require File.join(File.dirname(__FILE__), '..', 'lib', 'hobo')
require 'contest'
require 'mocha'

class Test::Unit::TestCase
  def hobo_mock_config
    { :ssh => 
      { 
        :uname => 'foo',
        :pass => 'bar',
        :host => 'baz',
        :port => 'bak' 
      },
      :dotfile_name => '.hobo'
    }
  end
end
