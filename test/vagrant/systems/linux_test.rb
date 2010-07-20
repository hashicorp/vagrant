require "test_helper"

class LinuxSystemTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Systems::Linux
    @ssh = mock("ssh")
    @mock_env = mock_environment
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

  context "preparing unison" do
    setup do
      @ssh.stubs(:exec!)
      @ssh.stubs(:upload!)
      @vm.stubs(:ssh).returns(@ssh)
    end

    should "upload the script" do
      @vm.ssh.expects(:upload!).with do |script, path|
        assert_equal @mock_env.config.unison.script, path
        true
      end

      @instance.prepare_unison(@ssh)
    end

    should "make the script executable" do
      @ssh.expects(:exec!).with("sudo chmod +x #{@mock_env.config.unison.script}").once
      @instance.prepare_unison(@ssh)
    end

    should "remove old crontab entry file" do
      @ssh.expects(:exec!).with("sudo rm #{@mock_env.config.unison.crontab_entry_file}", :error_check => false).once
      @instance.prepare_unison(@ssh)
    end
  end

  context "creating unison entry" do
    setup do
      @ssh.stubs(:exec!)
      @options = {
        :guestpath => "foo",
        :original => { :guestpath => "bar!" }
      }
    end

    should "render the crontab entry with proper variables" do
      variables = {
        :from => @options[:guestpath],
        :to => @options[:original][:guestpath],
        :options => @mock_env.config.unison.options,
        :script => @mock_env.config.unison.script,
        :log_file => @mock_env.config.unison.log_file % "bar-"
      }
      Vagrant::Util::TemplateRenderer.expects(:render).with('/unison/crontab_entry',
                                                            variables).once
      @instance.create_unison(@ssh, @options)
    end

    should "remove the .unison directory" do
      @ssh.expects(:exec!).with("sudo rm -rf ~/.unison")
      @instance.create_unison(@ssh, @options)
    end

    should "remove the original guestpath" do
      @ssh.expects(:exec!).with("sudo rm -rf #{@options[:original][:guestpath]}")
      @instance.create_unison(@ssh, @options)
    end

    should "enable the crontab file" do
      @ssh.expects(:exec!).with("crontab #{@mock_env.config.unison.crontab_entry_file}")
      @instance.create_unison(@ssh, @options)
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

      assert_raises(Vagrant::Action::ActionException) {
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
