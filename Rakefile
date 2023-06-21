require 'rubygems'
require 'bundler/setup'
require "rake/extensiontask"

# Immediately sync all stdout so that tools like buildbot can
# immediately load in the output.
$stdout.sync = true
$stderr.sync = true

Rake::ExtensionTask.new "vagrant/vagrant_ssl" do |ext|
end

# Load all the rake tasks from the "tasks" folder. This folder
# allows us to nicely separate rake tasks into individual files
# based on their role, which makes development and debugging easier
# than one monolithic file.
task_dir = File.expand_path("../tasks", __FILE__)
Dir["#{task_dir}/**/*.rake"].each do |task_file|
  load task_file
end

task default: "test:unit"
