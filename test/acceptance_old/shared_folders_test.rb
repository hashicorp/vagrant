require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "vagrant shared folders" do
  include_context "acceptance"

  # This creates an initial environment that is ready for a "vagrant up"
  def initialize_valid_environment
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
  end

  it "should have a '/vagrant' shared folder" do
    initialize_valid_environment

    # This is the file that will be created from the VM,
    # but should then exist on the host machine
    foofile = environment.workdir.join("foo")

    assert_execute("vagrant", "up")
    foofile.exist?.should_not be,
        "'foo' should not exist yet."

    assert_execute("vagrant", "ssh", "-c", "touch /vagrant/foo")
    foofile.exist?.should be, "'foo' should exist since it was touched in the shared folder"
  end

  it "should create a shared folder if the :create flag is set" do
    initialize_valid_environment

    # Setup the custom Vagrantfile
    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.write(<<-VF)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.share_folder "v-root", "/vagrant", "./data", :create => true
end
VF
    end

    data_dir = environment.workdir.join("data")

    # Verify the directory doesn't exist prior, for sanity
    data_dir.exist?.should_not be

    # Bring up the VM
    assert_execute("vagrant", "up")

    # Verify the directory exists
    data_dir.should be_directory

    # Touch a file and verify it is shared
    assert_execute("vagrant", "ssh", "-c", "touch /vagrant/foo")
    data_dir.join("foo").exist?.should be
  end

  it "should properly shell expand relative directories on the guest" do
    initialize_valid_environment

    # Setup the custom Vagrantfile
    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.write(<<-VF)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.share_folder "v-root", "~/data", "."
end
VF
    end

    # Sanity
    foo_file = environment.workdir.join("foo")
    foo_file.exist?.should_not be

    # Bring up the VM
    assert_execute("vagrant", "up")

    # Touch a file in the shared folder we expect and verify
    # it is shared.
    assert_execute("vagrant", "ssh", "-c", "touch ~/data/foo")
    foo_file.exist?.should be
  end
end
