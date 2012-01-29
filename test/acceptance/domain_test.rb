require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "edit hosts file" do
  include_context "acceptance"

  # This creates an initial environment that is ready for a "vagrant up"
  def initialize_valid_environment
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
  end

  it "should add defined domain to /etc/hosts" do
    initialize_valid_environment
    # Setup the custom Vagrantfile
    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.write(<<-VF)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.network :hostonly, "10.20.30.40"
  config.vm.domains = 'domain1.com domain2.com domain3.com'
end
VF
    end
    # Bring up the VM
    assert_execute("vagrant", "up")

    # /etc/hosts should have string
    # 10.20.30.40 domain1.com domain2.com domain3.com

    `grep '10.20.30.40 domain1.com domain2.com domain3.com' /etc/hosts`.should match('10.20.30.40 domain1.com domain2.com domain3.com')
  end
end
