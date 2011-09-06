require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
Bundler::GemHelper.install_tasks

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test/unit"
  t.pattern = 'test/unit/**/*_test.rb'
end
