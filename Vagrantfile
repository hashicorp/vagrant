# This Vagrantfile can be used to develop Vagrant. Note that VirtualBox
# doesn't run in VirtualBox so you can't actually _run_ Vagrant within
# the VM created by this Vagrantfile, but you can use it to develop the
# Ruby, run unit tests, etc.

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"
  config.vm.hostname = "vagrant"
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

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

$shell = <<-'CONTENTS'
export DEBIAN_FRONTEND=noninteractive
MARKER_FILE="/usr/local/etc/vagrant_provision_marker"
RUBY_VER_REQ=$(awk '$1 == "s.required_ruby_version" { print $4 }' /vagrant/vagrant.gemspec | tr -d '"')
BUNDLER_VER_REQ=$(awk '/s.add_dependency "bundler"/ { print $4 }' /vagrant/vagrant.gemspec | tr -d '"')

# Only provision once
if [ -f "${MARKER_FILE}" ]; then
  exit 0
fi

# Update apt
apt-get update --quiet

# Install basic dependencies
apt-get install -qy build-essential bsdtar curl

# Import the mpapis public key to verify downloaded releases
su -l -c 'gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3' vagrant

# Install RVM
su -l -c 'curl -sL https://get.rvm.io | bash -s stable' vagrant

# Add the vagrant user to the RVM group
#usermod -a -G rvm vagrant

# Install latest Ruby that complies with Vagrant's version constraint
RUBY_VER_LATEST=$(su -l -c 'rvm list known' vagrant | tr '[]-' ' ' | awk "/^ ruby  ${RUBY_VER_REQ:0:1}\./ { print \$2 }" | sort | tail -n1)
su -l -c "rvm install ${RUBY_VER_LATEST}" vagrant
su -l -c "rvm --default use ${RUBY_VER_LATEST}" vagrant

# Output the Ruby version (for sanity)
su -l -c 'ruby --version' vagrant

# Install Git
apt-get install -qy git

# Upgrade Rubygems
su -l -c "rvm ${RUBY_VER_LATEST} do gem update --system" vagrant

# Install bundler and prepare to run unit tests
su -l -c "gem install bundler -v ${BUNDLER_VER_REQ}" vagrant
su -l -c 'cd /vagrant; bundle install' vagrant

# Automatically move into the shared folder, but only add the command
# if it's not already there.
grep -q 'cd /vagrant' /home/vagrant/.bash_profile || echo 'cd /vagrant' >> /home/vagrant/.bash_profile

# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
CONTENTS
