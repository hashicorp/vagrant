require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "vagrant"
    gemspec.summary = "Vagrant is a tool for building and distributing virtualized development environments."
    gemspec.description = "Vagrant is a tool for building and distributing virtualized development environments."
    gemspec.email = ["mitchell.hashimoto@gmail.com", "john.m.bender@gmail.com"]
    gemspec.homepage = "http://github.com/mitchellh/vagrant"
    gemspec.authors = ["Mitchell Hashimoto", "John Bender"]

    gemspec.add_dependency('virtualbox', '~> 0.6.0')
    gemspec.add_dependency('net-ssh', '>= 2.0.19')
    gemspec.add_dependency('net-scp', '>= 1.0.2')
    gemspec.add_dependency('json_pure', '>= 1.2.0')
    gemspec.add_dependency('archive-tar-minitar', '= 0.5.2')
    gemspec.add_dependency('mario', '~> 0.0.6')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

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
