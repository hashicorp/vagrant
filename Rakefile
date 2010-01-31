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
