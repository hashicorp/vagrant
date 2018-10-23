require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Driver::Version_5_0 do
  include_context "virtualbox"

  let(:vbox_version) { "5.0.0" }

  subject { VagrantPlugins::ProviderVirtualBox::Driver::Version_5_0.new(uuid) }

  it_behaves_like "a version 4.x virtualbox driver"

  describe "#shared_folders" do
    let(:folders) { [{:name=>"folder",
                     :hostpath=>"/Users/brian/vagrant-folder",
                     :transient=>false,
                     :SharedFoldersEnableSymlinksCreate=>true}]}

    let(:folders_automount) { [{:name=>"folder",
                     :hostpath=>"/Users/brian/vagrant-folder",
                     :transient=>false,
                     :automount=>true,
                     :SharedFoldersEnableSymlinksCreate=>true}]}

    let(:folders_disabled) { [{:name=>"folder",
                     :hostpath=>"/Users/brian/vagrant-folder",
                     :transient=>false,
                     :SharedFoldersEnableSymlinksCreate=>false}]}

    it "enables SharedFoldersEnableSymlinksCreate if true" do
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "setextradata", anything, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/folder", "1", {:notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))

      expect(subprocess).to receive(:execute).
        with("VBoxManage", "sharedfolder", "add", anything, "--name", "folder", "--hostpath", "/Users/brian/vagrant-folder", {:notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))
      subject.share_folders(folders)

    end

    it "enables automount if option is true" do
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "setextradata", anything, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/folder", "1", {:notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))

      expect(subprocess).to receive(:execute).
        with("VBoxManage", "sharedfolder", "add", anything, "--name", "folder", "--hostpath", "/Users/brian/vagrant-folder", "--automount", {:notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))
      subject.share_folders(folders_automount)

    end


    it "disables SharedFoldersEnableSymlinksCreate if false" do
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "sharedfolder", "add", anything, "--name", "folder", "--hostpath", "/Users/brian/vagrant-folder", {:notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))
      subject.share_folders(folders_disabled)

    end
  end

  describe "#set_mac_address" do
    let(:mac) { "00:00:00:00:00:00" }

    after { subject.set_mac_address(mac) }

    it "should modify vm and set mac address" do
      expect(subprocess).to receive(:execute).with("VBoxManage", "modifyvm", anything, "--macaddress1", mac, anything).
        and_return(subprocess_result(exit_code: 0))
    end

    context "when mac address is falsey" do
      let(:mac) { nil }

      it "should modify vm and set mac address to automatic value" do
        expect(subprocess).to receive(:execute).with("VBoxManage", "modifyvm", anything, "--macaddress1", "auto", anything).
          and_return(subprocess_result(exit_code: 0))
      end
    end
  end
end
