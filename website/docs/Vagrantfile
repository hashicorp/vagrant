# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
sudo apt-get -y update
sudo apt-get -y install curl
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
. ~/.bashrc
. ~/.bash_profile
rvm install 2.0.0
rvm --default use 2.0.0
gem install bundler
cd /vagrant
bundle
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = "hashicorp/precise64"
  config.vm.network "private_network", ip: "33.33.33.10"
  config.vm.provision "shell", inline: $script, privileged: false
  config.vm.synced_folder ".", "/vagrant", type: "rsync"
end
