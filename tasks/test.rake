require 'rake/testtask'
require 'rspec/core/rake_task'

namespace :test do
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "test/unit/**/*_test.rb"
    t.rspec_opts = "--color"
  end
end
