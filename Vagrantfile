
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "centos7"

  config.vm.define :centos7 do |centos7|
    config.vm.network "private_network", ip: "192.168.11.3"
    config.vm.hostname = "centos7"
    # config.vm.network "public_network"
    # config.ssh.forward_agent = true
    config.vm.synced_folder "../puppet", "/puppet"

    config.vm.provider "virtualbox" do |vb|
      vb.gui = false
      # Use VBoxManage to customize the VM. For example to change memory:
      vb.customize ["modifyvm", :id, "--memory", "2048"]
    end

    config.vm.provision "puppet" do |puppet|
      puppet.environment_path = "../puppet/environments"
      puppet.environment = "testenv"
    #  puppet.manifests_path = "../puppet/manifests"
    #  puppet.manifest_file  = "site.pp"
      puppet.module_path = [ "../puppet/modules/public", "../puppet/modules/private" ]
   #   puppet.options = "--debug --verbose"
    end

    # Deprecated method:
    #puppet apply --debug --verbose --modulepath '/puppet/modules/private:/puppet/modules/public:/etc/puppet/modules' 
    #--manifestdir /tmp/vagrant-puppet-1/manifests --detailed-exitcodes /tmp/vagrant-puppet-1/manifests/site.pp 

  end
end
