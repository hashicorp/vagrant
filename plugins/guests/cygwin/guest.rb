require "vagrant"

module VagrantPlugins
  module GuestCygwin
    # A general Vagrant system implementation for "cygwin" on Windows.
    #  Requires setup of cygwin on gues OS and configuration of openssh.
    #     Notes on setup: https://groups.google.com/forum/?fromgroups=#!topic/vagrant-up/TSpQFb2ixB0
    #
    # Contributed by Edward Raigosa <edward.raigosa@gmail.com>
    class Guest < Vagrant.plugin("2", :guest)
      # Here for whenever it may be used.
      class CygwinError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.guest.cygwin")
      end
      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::guest::cygwin")
      end
      # http://support.microsoft.com/?kbid=257748
      # 
      # Configure the static ip's
      # To change to a static address, type the following command:
      #     netsh interface ip set address "Local Area Connection" static ipaddr subnetmask gateway metric 
      #     netsh interface ip set address "Local Area Connection" static 192.168.0.10 255.255.255.0 192.168.0.1 1
      #
      # To switch the specified adapter from a static address to DHCP, type the following command:
      #     netsh interface ip set address "Local Area Connection" dhcp
      #
      # Debugging , show network interfaces with : 
      #     netsh interface ip show config
      # networks looks like:
      # {
      #   :type      => :static,
      #   :ip        => "192.168.33.10",
      #   :netmask   => "255.255.255.0",
      #   :interface => 1
      # }
      
      def configure_networks(networks)
        networks.each do |network|
          device = "#{vm.config.cygwin.device}" 
          device += " #{network[:interface]}" if (network[:interface] != 1) #  Try to set the device to the correct interface
                                                 
          su_cmd = "#{vm.config.cygwin.suexec_cmd}"   #  I'm not sure if we'll need this, but just in case, we're leaving it.
                                                      #  might come in handy in case we want to run runas /user:Administrator /pass...
          su_cmd += " " if ! su_cmd.empty?                                     
          ifconfig_cmd = "#{su_cmd}netsh interface ip set address \"#{device}\""

         
          if network[:type].to_sym == :static
            #     netsh interface ip set address "Local Area Connection" static ipaddr subnetmask gateway metric 
            #     netsh interface ip set address "Local Area Connection" static 192.168.0.10 255.255.255.0 192.168.0.1 1
            # Question, for static ip's what about the gateway and metric???  Is it defaulted?  Need to test.
            # This doesn't seem to work well on windows, so it needs more testing.  I'm not sure if you have to allocate 
            #  a local ip address first...I'm going to commit it till I can figure it out or someone smarter than me can.
            #  NAT configuration with static ip results in an unreachable machine and breaks vagrant.
            @logger.info("Network re-configure to #{network[:ip]}")
            #vm.communicate.execute("#{ifconfig_cmd} static #{network[:ip]} #{network[:netmask]}")
            warn_notimp_msg = "Static ip address with config.vm.network is not implemented. ignoring configuration option." 
            @logger.warn(warn_notimp_msg)
            # TODO: need a way to show this message above.  No idea how to get an env object at this level.
            # @env[:ui].warn warn_notimp_msg
          elsif network[:type].to_sym == :dhcp
            # sample Vagrantfile configuration for testing:
            # config.vm.network :public_network, bridge: "Intel(R) Centrino(R) Advanced-N 6205"
            # If you don't specify the interface then vagrant wants to prompt you for input.
            # On cygwin there is a known issue where TTY is not being recognized by Ruby.   I'm hoping this is fixed one day.
            @logger.info("Network re-configure to dhcp")
            script_network  = "set -x -v;"
            script_network += "return=\"$(#{ifconfig_cmd} dhcp)\";"
            script_network += "save_error=$?;"
            script_network += "[ $(echo $return|grep \"already enabled on this interface\"|wc -l) > 1 ] && exit 0;"
            script_network += "exit $save_error;"
            vm.communicate.execute("#{script_network}")
          end
          # NOTE:
          # Host file updates is not implemented... windows deals with it.  
            
        end
      end

      def change_host_name(name)
        su_cmd = vm.config.cygwin.suexec_cmd
        su_cmd += " " if ! su_cmd.empty? 
        # Only do this if the hostname is not already set
        # What else should we worry about on windows with hostname change?  hosts file? nope, windows doesn't need it.
        # 
        if !vm.communicate.test("#{su_cmd} hostname | grep '#{name}'")
          @logger.info("Changing hostname to #{name}")
          vm.communicate.execute("#{su_cmd}cmd /c \"wmic computersystem where name='%COMPUTERNAME%' call rename name='#{name}'\"")
          # we need to reboot...(Is this ok?? What about provisioning, is there a way to disable it?)
          @logger.debug("Start reload machine : #{vm.name}" )
          vm.action("reload")
          @logger.debug("Finished reload machine : #{vm.name}" )   
        end
      end

      # There should be an exception raised if the line
      #
      #     vagrant::::profiles=Primary Administrator
      #    This one requires cygwin shutdown package to be installed:
      #         cyg-get shutdown 
      #    
      def halt
        begin
          
          # how can i check something like cygcheck -l shutdown|grep shutdown.exe ??
          # I'd like to show a message like:   You do not have a proper shutdown for cygwin installed, please install shutdown.
          # Don't use windows shutdown, wasn't cutting it for me.  We need cyg-get shutdown!!  Don't have cyg-get, install it with cinst cyg-get
          su_cmd = vm.config.cygwin.suexec_cmd
          su_cmd += " " if ! su_cmd.empty? 
          @logger.info("Cygwin shutdown -s -f now")
          vm.communicate.execute("#{su_cmd}shutdown -s -f now")
        rescue IOError
          # Ignore, this probably means connection closed because it
          # shut down.
        end
      end

      # Run the mount commands to mount virtual box shares...
      # I'm a little confused why this is here, but here we go.  Why not part of a provider? 
      # Do we need to check providers being used? 
      def mount_shared_folder(name, guestpath, options)
        # These are just far easier to use than the full options syntax
        owner = options[:owner]
        group = options[:group]
        mount_options += "#{options[:extra]}" if options[:extra]
        
        su_cmd = vm.config.cygwin.suexec_cmd
        su_cmd += " " if ! su_cmd.empty? 

        # Create the shared folder
        #vm.communicate.execute("#{su_cmd}mkdir -p #{guestpath}")
        @logger.debug("Attempting to mount cygwin folders...")
        @logger.debug("name          : #{name}")
        @logger.debug("guestpath     : #{guestpath}")
        @logger.debug("mount_optiosn : #{mount_options}")
        @logger.debug("owner         : #{owner}")
        @logger.debug("group         : #{group}")
        
        #  cleanup old mounts
        #       cleanup folders if they exist
        check_for_drive="export mounteddrive=\"$(net use |grep '\\\\\\\\vboxsvr\\\\#{name}'|tr -d 'Unavailable' | head -1 |awk '{print $1}')\""
        unmount_drive="net use /d ${mounteddrive}"
        unmount_script  = "set -x -v;"
        unmount_script += "#{check_for_drive};"
        unmount_script += "while [ ! \"${mounteddrive}\" == \"\"  ];"
        unmount_script += " do echo removing old mount ${mounteddrive};"
        unmount_script += "#{unmount_drive};"
        unmount_script += "#{check_for_drive};"
        unmount_script += " done"
        @logger.debug("running umount command : #{unmount_script}")
        vm.communicate.execute("#{unmount_script}", :error_check => false) # skip error checking since we just use the next drive letter anyway
        
        # Mount the folder with the proper owner/group
        # mount the vbox file system (virtual box.... only??)
        # net use \* \\\\vboxsvr\\e:/workspace
        # #{name} #{guestpath} 
        
        mount_command = "#{su_cmd}net use \\* \\\\\\\\vboxsvr\\\\#{name} #{mount_options}"
        @logger.debug("mount : #{mount_command}")
        vm.communicate.execute("#{mount_command}")


        # create windows link to mounted file system so we can use it as if it were a real path
        # note: if the guestpath is there, i wonder if we should check before removing it to reset... 
        #     do we do something special with :create option???
        #  For configuration:
        # config.vm.synced_folder "workspace", "e:/workspace", :create => true
        #
        #  Expect something like:   
        # cmd /c \"mklink /d \"$(mkdir -p e:/workspace;cygpath -w e:/workspace;rm -rf e:/workspace)\" \"$(net use |grep e:/workspace |awk '{print $1}' ) 
        # there is a problem with mounting guestpath = /vagrant   
        # We have to open up permissions to c:\\Cygwin\\ to allow vagrant to have access, but
        #  I've not found a good way to run a command as root.   Tried experimenting with ShellExecute but had no luck.
        #  As a workaround lets ignore errors for /vagrant   (other folders should have error checking since they were intentional)
        
        # TODO : Warn users that they can't mount /vagrant unless they fix the permissions for C:\Cygwin so that either Administrators or vagrant has full control of the folder.  Done automatically if Cygwin is installed as vagrant user.
        vm.communicate.execute("cmd /c \"mklink /d \"$([ ! -d '#{guestpath}' ] && mkdir -p '#{guestpath}';cygpath -w '#{guestpath}';rm -rf '#{guestpath}')\" \"$(net use |grep '#{name}' |awk '{print $1}')\"\"", :error_check => (guestpath != "/vagrant"))
        # chown the folder to the proper owner/group
        #  Not sure this is even needed....(windows inherits).... vm.communicate.execute("#{su_cmd}chown #{owner} #{guestpath}")
      end
    end
  end
end
