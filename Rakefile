require 'rubygems'
require 'bundler/setup'
require 'gemfury'

# Immediately sync all stdout so that tools like buildbot can
# immediately load in the output.
$stdout.sync = true
$stderr.sync = true

# Load all the rake tasks from the "tasks" folder. This folder
# allows us to nicely separate rake tasks into individual files
# based on their role, which makes development and debugging easier
# than one monolithic file.
task_dir = File.expand_path("../tasks", __FILE__)
Dir["#{task_dir}/**/*.rake"].each do |task_file|
  load task_file
end

task default: "test:unit"

namespace :gemfury do
  desc 'Deploy new gems to Gemfury'
  task :deploy do
    client = Gemfury::Client.new(:user_api_key => ENV['GEMFURY_API_TOKEN'], :account => 'crashlytics')
    gemfury_version = {}
    GEMS = FileList["**/*.gem"]
    GEMS.each do |gem|
      # slug = current full id of the gem, like this: crashlytics-gemname-gemversion
      slug = File.basename(gem, '.gem')
      name, _, local_version = slug.rpartition('-')

      begin
        gemfury_version = client.versions(name).detect { |version| version['slug'] == slug }
      rescue Gemfury::NotFound, Faraday::Error::ParsingError
        gemfury_version = nil
      end

      if gemfury_version.nil?
        File.open(gem, 'r') do |f|
          client.push_gem(f)
        end
      end
    end
  end
end

