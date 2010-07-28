require 'rake/testtask'

task :default => :test

def gemspec
  @gemspec ||= begin
    file = File.expand_path('../vagrant.gemspec', __FILE__)
    eval(File.read(file), binding, file)
  end
end

begin
  require 'rake/gempackagetask'
rescue LoadError
  task(:gem) { $stderr.puts '`gem install rake` to package gems' }
else
  Rake::GemPackageTask.new(gemspec) do |pkg|
    pkg.gem_spec = gemspec
  end
  task :gem => :gemspec
end

desc "install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version} --no-ri --no-rdoc}
end

desc "validate the gemspec"
task :gemspec do
  gemspec.validate
end

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
