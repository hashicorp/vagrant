require 'digest/sha1'
require 'pathname'
require 'yaml'

require 'posix-spawn'

require 'vagrant/util/file_checksum'

namespace :acceptance do
  desc "Downloads the boxes required for running the acceptance tests."
  task :boxes, :directory do |t, args|
    # Create the directory where the boxes will be downloaded
    box_dir = Pathname.new(args[:directory] || File.expand_path("../../test/tmp/boxes", __FILE__))
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
          puts "OK"
          next
        else
          puts "FAIL"
        end
      end

      # Download the file
      puts "Downloading: #{box["url"]}"

      # TODO: This isn't Windows friendly yet. Move to a OS-independent
      # download.
      pid, _stdin, stdout, stderr =
        POSIX::Spawn.popen4("wget", box["url"], "-O", box_file.to_s)
      pid, status = Process.waitpid2(pid)
      if status.exitstatus != 0
        puts "Download failed!"
        puts stdout.read
        puts stderr.read
        abort
      end

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
    require File.expand_path('../../test/acceptance/support/tempdir', __FILE__)

    # Get the directory for the boxes
    box_dir = Pathname.new(args[:directory] || File.expand_path("../../test/tmp/boxes", __FILE__))

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
