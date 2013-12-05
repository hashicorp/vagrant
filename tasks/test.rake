require 'rake/testtask'
require 'rspec/core/rake_task'

namespace :test do
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "test/unit/**/*_test.rb"
  end

  Rake::TestTask.new do |t|
    t.name = "unit_old"
    t.libs << "test/unit_legacy"
    t.pattern = "test/unit_legacy/**/*_test.rb"
  end
end
