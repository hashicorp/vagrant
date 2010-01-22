begin
  require File.join(File.dirname(__FILE__), 'vendor', 'gems', 'environment')
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

require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = 'test/*_test.rb'
end