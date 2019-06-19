require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/helper")

describe VagrantPlugins::HyperV::SyncHelper do
  subject { described_class }

  def random_name
    (0...8).map { ('a'..'z').to_a[rand(26)] }.join
  end

  def generate_random_file(files, path, separator, is_directory: true)
    prefix = is_directory ? "dir" : "file"
    fn = [path, "#{prefix}_#{random_name}"].join(separator)
    files << fn
    allow(VagrantPlugins::HyperV::SyncHelper).to receive(:directory?).with(fn).and_return(is_directory)
    fn
  end

  describe "#expand_excludes" do
    let(:hostpath) { 'vagrant' }
    let(:expanded_hostpaths) do
      { Windows: 'C:\vagrant', WSL: "/vagrant" }
    end
    let(:exclude) { [".git/"] }
    let(:exclude_dirs) { %w[.vagrant/ .git/] }
    let(:separators) { { Windows: '\\', WSL: "/" } }

    %i[Windows WSL].map do |host_type|
      context "in #{host_type} environment" do
        let(:host_type) { host_type }
        let(:is_windows) { host_type == :Windows }
        let(:separator) { separators[host_type] }
        let(:expanded_hostpath) { expanded_hostpaths[host_type] }

        before do
          allow(Vagrant::Util::Platform).to receive(:wsl?).and_return(!is_windows)
          allow(subject).to receive(:expand_path).with(hostpath).and_return(expanded_hostpath)
        end

        it "expands excludes into file and dir list" do
          files = []
          dirs = []
          exclude_dirs.map do |dir|
            fullpath = [expanded_hostpath, dir[0..-2]].join(separator)
            allow(subject).to receive(:platform_join).
              with(expanded_hostpath, dir, is_windows: is_windows).and_return(fullpath)

            ignore_paths = []
            allow(described_class).to receive(:directory?).with(fullpath).and_return(true)
            ignore_paths << fullpath
            dirs << fullpath

            file = generate_random_file(ignore_paths, fullpath, separator, is_directory: false)
            files << file

            subDir = generate_random_file(ignore_paths, fullpath, separator, is_directory: true)
            dirs << subDir

            subDirFile = generate_random_file(ignore_paths, subDir, separator, is_directory: false)
            files << subDirFile

            allow(Dir).to receive(:glob).with(fullpath) do |arg, &proc|
              ignore_paths.each do |path|
                proc.call path
              end
            end
          end
          excludes = subject.expand_excludes(hostpath, exclude)
          expect(excludes[:dirs]).to eq(dirs)
          expect(excludes[:files]).to eq(files)
        end
      end
    end
  end

  describe "#platform_join" do
    it "produces Windows-style path" do
      expect(subject.platform_join("C:", "vagrant", ".vagrant", "", is_windows: true)).to eq("C:\\vagrant\\.vagrant\\")
    end

    it "produces Unix-style path in WSL" do
      expect(subject.platform_join("/mnt", "vagrant", ".vagrant", "", is_windows: false)).to eq("/mnt/vagrant/.vagrant/")
    end
  end

  describe "#sync_single" do
    let(:machine) { double("machine", provider: provider) }
    let(:provider) { double("provider") }
    let(:ssh_info) { { username: "vagrant" } }
    let(:folder_opts) do
      { hostpath: 'vagrant',
        guestpath: 'C:\vagrant',
        owner: "vagrant",
        group: "vagrant",
        exclude: [".git/"] }
    end

    after { subject.sync_single(machine, ssh_info, folder_opts) }

    it "calls provider capability to sync single folder" do
      expect(provider).to receive(:capability).
        with(:sync_folder, folder_opts)
    end
  end
end
