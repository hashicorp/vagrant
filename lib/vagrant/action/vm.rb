module Vagrant
  class Action
    module VM
      autoload :Boot,                'vagrant/action/vm/boot'
      autoload :CheckAccessible,     'vagrant/action/vm/check_accessible'
      autoload :CheckBox,            'vagrant/action/vm/check_box'
      autoload :CheckGuestAdditions, 'vagrant/action/vm/check_guest_additions'
      autoload :CleanMachineFolder,  'vagrant/action/vm/clean_machine_folder'
      autoload :ClearForwardedPorts, 'vagrant/action/vm/clear_forwarded_ports'
      autoload :ClearNFSExports,     'vagrant/action/vm/clear_nfs_exports'
      autoload :ClearSharedFolders,  'vagrant/action/vm/clear_shared_folders'
      autoload :Customize,           'vagrant/action/vm/customize'
      autoload :Destroy,             'vagrant/action/vm/destroy'
      autoload :DestroyUnusedNetworkInterfaces, 'vagrant/action/vm/destroy_unused_network_interfaces'
      autoload :DiscardState,        'vagrant/action/vm/discard_state'
      autoload :Export,              'vagrant/action/vm/export'
      autoload :ForwardPorts,        'vagrant/action/vm/forward_ports'
      autoload :Halt,                'vagrant/action/vm/halt'
      autoload :HostName,            'vagrant/action/vm/host_name'
      autoload :Import,              'vagrant/action/vm/import'
      autoload :MatchMACAddress,     'vagrant/action/vm/match_mac_address'
      autoload :Modify,              'vagrant/action/vm/modify'
      autoload :Network,             'vagrant/action/vm/network'
      autoload :NFS,                 'vagrant/action/vm/nfs'
      autoload :Package,             'vagrant/action/vm/package'
      autoload :PackageVagrantfile,  'vagrant/action/vm/package_vagrantfile'
      autoload :Provision,           'vagrant/action/vm/provision'
      autoload :ProvisionerCleanup,  'vagrant/action/vm/provisioner_cleanup'
      autoload :Resume,              'vagrant/action/vm/resume'
      autoload :ShareFolders,        'vagrant/action/vm/share_folders'
      autoload :Suspend,             'vagrant/action/vm/suspend'
    end
  end
end
