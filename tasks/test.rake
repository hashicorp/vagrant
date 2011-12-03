require 'rake/testtask'
require 'rspec/core/rake_task'

namespace :test do
  Rake::TestTask.new do |t|
    t.name = "unit"
    t.libs << "test/unit_legacy"
    t.pattern = "test/unit_legacy/**/*_test.rb"
  end

  RSpec::Core::RakeTask.new do |t|
    t.name = "acceptance"
    t.pattern = "test/acceptance/**/*_test.rb"
  end
end
