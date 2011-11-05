require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
Bundler::GemHelper.install_tasks

task :default => "test:unit"

namespace :test do
  Rake::TestTask.new do |t|
    t.name = "unit"
    t.libs << "test/unit"
    t.pattern = "test/unit/**/*_test.rb"
  end

  Rake::TestTask.new do |t|
    t.name = "acceptance"
    t.libs << "test/acceptance"
    t.pattern = "test/acceptance/**/*_test.rb"
  end
end

namespace :acceptance do
  desc "Generates the configuration for acceptance tests from current source."
  task :config do
    require 'yaml'
    require 'posix-spawn'

    require File.expand_path("../lib/vagrant/version", __FILE__)
    require File.expand_path('../test/acceptance/helpers/tempdir', __FILE__)

    # Generate the binstubs for the Vagrant binary
    tempdir = Tempdir.new
    pid, stdin, stdout, stderr =
      POSIX::Spawn.popen4("bundle", "install", "--binstubs", tempdir.path)
    pid, status = Process.waitpid2(pid)
    if status.exitstatus != 0
      # Bundle install failed...
      puts "Bundle install failed! Error:"
      puts stderr.read
      exit 1
    end

    # Generate the actual configuration
    config = {
      "vagrant_path" => File.join(tempdir.path, "vagrant"),
      "vagrant_version" => Vagrant::VERSION,
      "env" => {
        "BUNDLE_GEMFILE" => File.expand_path("../Gemfile", __FILE__)
      }
    }

    File.open("acceptance_config.yml", "w+") do |f|
      f.write(YAML.dump(config))
    end

    puts <<-OUTPUT
Acceptance test configuration is now in this directory in
"acceptance_config.yml." Set your ACCEPTANCE_CONFIG environmental
variable to this file and run any of the acceptance tests now.
OUTPUT
  end
end
