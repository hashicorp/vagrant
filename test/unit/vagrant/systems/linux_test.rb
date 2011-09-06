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
      @owner = "owner"
      @group = "group"
    end

    should "create the dir, mount the folder, then set permissions" do
      mount_seq = sequence("mount_seq")
      @ssh.expects(:exec!).with("sudo mkdir -p #{@guestpath}").in_sequence(mount_seq)
      @instance.expects(:mount_folder).with(@ssh, @name, @guestpath, @owner, @group).in_sequence(mount_seq)
      @ssh.expects(:exec!).with("sudo chown `id -u #{@owner}`:`id -g #{@group}` #{@guestpath}").in_sequence(mount_seq)

      @instance.mount_shared_folder(@ssh, @name, @guestpath, @owner, @group)
    end
  end

  #-------------------------------------------------------------------
  # "Private" methods tests
  #-------------------------------------------------------------------
  context "mounting the main folder" do
    setup do
      @name = "foo"
      @guestpath = "bar"
      @owner = "owner"
      @group = "group"
      @sleeptime = 0
      @limit = 10

      @success_return = false
    end

    def mount_folder
      @instance.mount_folder(@ssh, @name, @guestpath, @owner, @group, @sleeptime)
    end

    should "execute the proper mount command" do
      @ssh.expects(:exec!).with("sudo mount -t vboxsf -o uid=`id -u #{@owner}`,gid=`id -g #{@group}` #{@name} #{@guestpath}").returns(@success_return)
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
  end
end
