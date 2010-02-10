require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "hobo"
    gemspec.summary = "Create virtualized development environments"
    gemspec.description = "Create virtualized development environments"
    gemspec.email = "todo@todo.com"
    gemspec.homepage = "http://github.com/mitchellh/hobo"
    gemspec.authors = ["Mitchell Hashimoto", "John Bender"]

    gemspec.add_dependency('virtualbox', '>= 0.4.3')
    gemspec.add_dependency('net-ssh', '>= 2.0.19')
    gemspec.add_dependency('net-scp', '>= 1.0.2')
    gemspec.add_dependency('json', '>= 1.2.0')
    gemspec.add_dependency('jashmenn-git-style-binaries', '>= 0.1.10')
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
