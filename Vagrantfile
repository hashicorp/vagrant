# This Vagrantfile can be used to develop Vagrant. Note that VirtualBox
# doesn't run in VirtualBox so you can't actually _run_ Vagrant within
# the VM created by this Vagrantfile, but you can use it to develop the
# Ruby, run unit tests, etc.

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"

  ["vmware_fusion", "vmware_workstation", "virtualbox"].each do |provider|
    config.vm.provider provider do |v, override|
      v.memory = "1024"
    end
  end

  config.vm.provision "shell", inline: $shell

  config.push.define "www", strategy: "local-exec" do |push|
    push.script = "scripts/website_push_www.sh"
  end

  config.push.define "docs", strategy: "local-exec" do |push|
    push.script = "scripts/website_push_docs.sh"
  end
end

$shell = <<-CONTENTS
MARKER_FILE="/usr/local/etc/vagrant_provision_marker"

# Only provision once
if [ -f "${MARKER_FILE}" ]; then
  exit 0
fi

# Update apt
apt-get update

# Install basic dependencies
apt-get install -y build-essential bsdtar curl

# Install RVM
su -l -c 'curl -L https://get.rvm.io | bash -s stable' vagrant

# Add the vagrant user to the RVM group
#usermod -a -G rvm vagrant

# Install some Rubies
su -l -c 'rvm install 2.1.1' vagrant
su -l -c 'rvm --default use 2.1.1' vagrant

# Output the Ruby version (for sanity)
su -l -c 'ruby --version' vagrant

# Install Git
apt-get install -y git

# Automatically move into the shared folder, but only add the command
# if it's not already there.
grep -q 'cd /vagrant' /home/vagrant/.bash_profile || echo 'cd /vagrant' >> /home/vagrant/.bash_profile

# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
CONTENTS
