require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
Bundler::GemHelper.install_tasks

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = 'test/**/*_test.rb'
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.options = ['--main', 'README.md', '--markup', 'markdown']
    t.options += ['--title', 'Vagrant Developer Documentation']
  end
rescue LoadError
  puts "Yard not available. Install it with: gem install yard"
  puts "if you wish to be able to generate developer documentation."
end
