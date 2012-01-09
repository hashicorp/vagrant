require 'digest/sha1'
require 'net/http'
require 'pathname'
require 'uri'
require 'yaml'

require 'childprocess'

require 'vagrant/util/file_checksum'

namespace :acceptance do
  desc "Downloads the boxes required for running the acceptance tests."
  task :boxes, :directory do |t, args|
    # Create the directory where the boxes will be downloaded
    box_dir = Pathname.new(args[:directory] || File.expand_path("../../boxes", __FILE__))
    box_dir.mkpath
    puts "Boxes will be placed in: #{box_dir}"

    # Load the required boxes
    boxes = YAML.load_file(File.expand_path("../../test/config/acceptance_boxes.yml", __FILE__))

    boxes.each do |box|
      puts "Box: #{box["name"]}"
      box_file = box_dir.join("#{box["name"]}.box")
      checksum = FileChecksum.new(box_file, Digest::SHA1)

      # If the box exists, we need to check the checksum and determine if we need
      # to redownload the file.
      if box_file.exist?
        print "Box exists, checking SHA1 sum... "
        if checksum.checksum == box["checksum"]
          print "OK\n"
          next
        else
          print "FAIL\n"
        end
      end

      # Download the file. Note that this has no error checking and just uses
      # pure net/http. There could be a better way.
      puts "Downloading: #{box["url"]}"
      destination = box_file.open("wb")
      uri = URI.parse(box["url"])
      Net::HTTP.new(uri.host, uri.port).start do |http|
        http.request_get(uri.request_uri) do |response|
          total = response.content_length
          progress = 0
          count = 0

          response.read_body do |segment|
            # Really elementary progress meter
            progress += segment.length
            count += 1
            puts "Progress: #{(progress.to_f / total.to_f) * 100}%" if count % 300 == 0

            # Write out to the destination file
            destination.write(segment)
          end
        end
      end

      destination.close

      # Check the checksum of the new file to verify that it
      # downloaded properly. This shouldn't happen, but it can!
      if checksum.checksum != box["checksum"]
        puts "Checksum didn't match! Download was corrupt!"
        abort
      end
    end
  end

  desc "Generates the configuration for acceptance tests from current source."
  task :config, :box_dir do |t, args|
    require File.expand_path("../../lib/vagrant/version", __FILE__)
    require File.expand_path('../../test/support/tempdir', __FILE__)

    # Get the directory for the boxes
    box_dir = Pathname.new(args[:box_dir] || File.expand_path("../../boxes", __FILE__))

    # Generate the binstubs for the Vagrant binary
    tempdir = Tempdir.new
    process = ChildProcess.build("bundle", "install", "--binstubs", tempdir.path)
    process.io.inherit!
    process.start
    process.poll_for_exit(64000)
    if process.exit_code != 0
      # Bundle install failed...
      puts "Bundle install failed!"
      abort
    end

    # Generate the actual configuration
    config = {
      "vagrant_path" => File.join(tempdir.path, "vagrant"),
      "vagrant_version" => Vagrant::VERSION,
      "env" => {
        "BUNDLE_GEMFILE" => File.expand_path("../../Gemfile", __FILE__)
      },
      "box_directory" => box_dir.to_s
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
