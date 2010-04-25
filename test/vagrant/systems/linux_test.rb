require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class LinuxSystemTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Systems::Linux

    @vm = mock("vm")
    @vm.stubs(:env).returns(mock_environment)
    @instance = @klass.new(@vm)
  end

  context "mounting shared folders" do
    setup do
      @ssh = mock("ssh")
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

  #-------------------------------------------------------------------
  # "Private" methods tests
  #-------------------------------------------------------------------
  context "mounting the main folder" do
    setup do
      @ssh = mock("ssh")
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
      @ssh.expects(:exec!).with("sudo mount -t vboxsf -o uid=#{@vm.env.config.ssh.username},gid=#{@vm.env.config.ssh.username} #{@name} #{@guestpath}").returns(@success_return)
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

      assert_raises(Vagrant::Actions::ActionException) {
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
      env = mock_environment do |config|
        config.vm.shared_folder_uid = uid
        config.vm.shared_folder_gid = gid
      end

      @vm.stubs(:env).returns(env)

      @ssh.expects(:exec!).with("sudo mount -t vboxsf -o uid=#{uid},gid=#{gid} #{@name} #{@guestpath}").returns(@success_return)
      mount_folder
    end
  end
end
