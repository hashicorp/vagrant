require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
Bundler::GemHelper.install_tasks

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = 'test/**/*_test.rb'
end
