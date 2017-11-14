cd /vagrant
vagrant plugin install ./vagrant-spec.gem

vagrant vagrant-spec $Env:VAGRANT_SPEC_ARGS /vagrant/test/vagrant-spec/configs/vagrant-spec.config.virtualbox.rb
