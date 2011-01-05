require "test_helper"

class LinuxSystemTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Systems::Linux
    @ssh = mock("ssh")
    @mock_env = vagrant_env
    @vm = mock("vm")
    @vm.stubs(:env).returns(@mock_env)
    @instance = @klass.new(@vm)
  end

  context "halting" do
    setup do
      @ssh_session = mock("ssh_session")
      @ssh.stubs(:execute).yields(@ssh_session)
      @vm.stubs(:ssh).returns(@ssh)

      @real_vm = mock("real_vm")
      @real_vm.stubs(:state).returns(:powered_off)
      @vm.stubs(:vm).returns(@real_vm)
    end

    should "execute halt via SSH" do
      @ssh_session.expects(:exec!).with("sudo halt").once
      @instance.halt
    end
  end

  context "mounting shared folders" do
    setup do
      @name = "foo"
      @guestpath = "/bar"
    end

    should "create the dir, mount the folder, then set permissions" do
      mount_seq = sequence("mount_seq")
      @ssh.expects(:exec!).with("sudo mkdir -p #{@guestpath}").in_sequence(mount_seq)
      @instance.expects(:mount_folder).with(@ssh, @name, @guestpath).in_sequence(mount_seq)
      @ssh.expects(:exec!).with("sudo chown #{@vm.env.config.ssh.username} #{@guestpath}").in_sequence(mount_seq)

      @instance.mount_shared_folder(@ssh, @name, @guestpath)
    end
  end

  context "prepare host only network" do
    setup do
      @ssh_session = mock("ssh_session")
      @ssh.stubs(:execute).yields(@ssh_session)
      @vm.stubs(:ssh).returns(@ssh)
    end

    should "determin distribution debian, clear out any previous entries for adapter, then create interfaces" do
      prepare_seq = sequence("prepare_seq")
      @instance.expects(:distribution).returns(:debian).in_sequence(prepare_seq)
      @ssh_session.expects(:exec!).with("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces").in_sequence(prepare_seq)
      @ssh_session.expects(:exec!).with("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'").in_sequence(prepare_seq)
      @instance.prepare_host_only_network({})
    end

    should "determin distribution redhat, clear out any previous entries for adapter, then create interfaces" do
      prepare_seq = sequence("prepare_seq")
      @instance.expects(:distribution).returns(:redhat).in_sequence(prepare_seq)
      @ssh_session.expects(:exec!).with("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/sysconfig/network-scripts/ifcfg-eth1 > /tmp/vagrant-ifcfg-eth1").in_sequence(prepare_seq)
      @ssh_session.expects(:exec!).with("sudo su -c 'cat /tmp/vagrant-ifcfg-eth1 > /etc/sysconfig/network-scripts/ifcfg-eth1'").in_sequence(prepare_seq)
      @instance.prepare_host_only_network({:adapter => 1})
    end

    should "determin distribution not supported" do
      @instance.expects(:distribution).raises(Vagrant::Systems::Linux::LinuxError)
      assert_raises(Vagrant::Systems::Linux::LinuxError) {
        @instance.prepare_host_only_network({})
      }
    end
  end

  #-------------------------------------------------------------------
  # "Private" methods tests
  #-------------------------------------------------------------------
  context "mounting the main folder" do
    setup do
      @name = "foo"
      @guestpath = "bar"
      @sleeptime = 0
      @limit = 10

      @success_return = false
    end

    def mount_folder
      @instance.mount_folder(@ssh, @name, @guestpath, @sleeptime)
    end

    should "execute the proper mount command" do
      @ssh.expects(:exec!).with("sudo mount -t vboxsf -o uid=`id -u #{@vm.env.config.ssh.username}`,gid=`id -g #{@vm.env.config.ssh.username}` #{@name} #{@guestpath}").returns(@success_return)
      mount_folder
    end

    should "test type of text and text string to detect error" do
      data = mock("data")
      data.expects(:[]=).with(:result, !@success_return)

      @ssh.expects(:exec!).yields(data, :stderr, "No such device").returns(@success_return)
      mount_folder
    end

    should "test type of text and test string to detect success" do
      data = mock("data")
      data.expects(:[]=).with(:result, @success_return)

      @ssh.expects(:exec!).yields(data, :stdout, "Nothing such device").returns(@success_return)
      mount_folder
    end

    should "raise an ActionException if the command fails constantly" do
      @ssh.expects(:exec!).times(@limit).returns(!@success_return)

      assert_raises(Vagrant::Systems::Linux::LinuxError) {
        mount_folder
      }
    end

    should "not raise any exception if the command succeeded" do
      @ssh.expects(:exec!).once.returns(@success_return)

      assert_nothing_raised {
        mount_folder
      }
    end

    should "add uid AND gid to mount" do
      uid = "foo"
      gid = "bar"
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.shared_folder_uid = "#{uid}"
        config.vm.shared_folder_gid = "#{gid}"
      vf

      @vm.stubs(:env).returns(env)

      @ssh.expects(:exec!).with("sudo mount -t vboxsf -o uid=`id -u #{uid}`,gid=`id -g #{gid}` #{@name} #{@guestpath}").returns(@success_return)
      mount_folder
    end
  end

  context "determine distribution" do
    setup do
      @debian_test_command = "test -e /etc/debian_version"
      @redhat_test_command = "test -e /etc/redhat-release"
    end

    should "is debian" do
      @ssh.expects(:exec!).with(@debian_test_command).yields(nil, :exit_status, 0)
      assert_equal true, @instance.debian?(@ssh)
    end

    should "is not debian" do
      @ssh.expects(:exec!).with(@debian_test_command).yields(nil, :exit_status, 1)
      assert_equal false, @instance.debian?(@ssh)
    end

    should "is redhat" do
      @ssh.expects(:exec!).with(@redhat_test_command).yields(nil, :exit_status, 0)
      assert_equal true, @instance.redhat?(@ssh)
    end

    should "is not redhat" do
      @ssh.expects(:exec!).with(@redhat_test_command).yields(nil, :exit_status, 1)
      assert_equal false, @instance.redhat?(@ssh)
    end

    should "debian selected" do
      @instance.expects(:debian?).returns(true)
      @instance.expects(:redhat?).never()
      assert_equal :debian, @instance.distribution(@ssh)
    end

    should "redhat selected" do
      check_seq = sequence("check_seq")
      @instance.expects(:debian?).returns(false).in_sequence(check_seq)
      @instance.expects(:redhat?).returns(true).in_sequence(check_seq)
      assert_equal :redhat, @instance.distribution(@ssh)
    end

    should "not supported" do
      check_seq = sequence("check_seq")
      @instance.expects(:debian?).returns(false).in_sequence(check_seq)
      @instance.expects(:redhat?).returns(false).in_sequence(check_seq)
      assert_raises(Vagrant::Systems::Linux::LinuxError) {
          @instance.distribution(@ssh)
      }
    end
  end

end
