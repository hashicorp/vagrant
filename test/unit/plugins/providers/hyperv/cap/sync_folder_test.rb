require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/cap/sync_folder")

describe VagrantPlugins::HyperV::Cap::SyncFolder do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:guest) { double("guest") }
  let(:driver) { double("driver") }
  let(:provider) do
    double("provider").tap do |provider|
      allow(provider).to receive(:driver).and_return(driver)
    end
  end
  let(:vm_id) { 'vm_id' }
  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      allow(m).to receive(:guest).and_return(guest)
      allow(m).to receive(:provider).and_return(provider)
      allow(m).to receive(:id).and_return(vm_id)
    end
  end
  let(:hostpath) { 'vagrant' }
  let(:exclude) { [".git/"] }
  let(:expanded_hostpaths) do
    { Windows: 'C:\vagrant', WSL: "/vagrant" }
  end
  let(:guestpaths) do
    { windows: 'C:\vagrant', linux: "/vagrant" }
  end
  let(:paths) do
    { Windows: %w[C:\vagrant C:\vagrant\.vagrant C:\vagrant\.git C:\vagrant\test],
      WSL: %w[/vagrant /vagrant/.vagrant /vagrant/.git /vagrant/test] }
  end
  let(:separators) do
    { Windows: '\\', WSL: "/" }
  end
  let(:shared_folder) do
    { hostpath: 'vagrant',
      owner: "vagrant",
      group: "vagrant",
      exclude: [".git/"] }
  end

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

  def generate_test_data(paths, separator)
    files = []
    excludes = { dirs: [], files: [] }
    includes = { dirs: [], files: [] }
    paths.map do |dir|
      files << dir
      excluded = dir.end_with?('.vagrant', '.git')
      allow(VagrantPlugins::HyperV::SyncHelper).to receive(:directory?).with(dir).and_return(true)
      (0..10).map do
        fn = generate_random_file(files, dir, separator, is_directory: false)
        if excluded
          excludes[:files] << fn
        else
          includes[:files] << fn
        end
      end

      sub_dir = generate_random_file(files, dir, separator, is_directory: true)
      if excluded
        excludes[:dirs] << dir
        excludes[:dirs] << sub_dir
      else
        includes[:dirs] << dir
        includes[:dirs] << sub_dir
      end

      (0..10).map do
        fn = generate_random_file(files, sub_dir, separator, is_directory: false)
        if excluded
          excludes[:files] << fn
        else
          includes[:files] << fn
        end
      end
    end
    { files: files,
      excludes: excludes,
      includes: includes }
  end

  def convert_path(mapping, path, host_type, guest_type, is_file: true)
    win_path = path.gsub "/vagrant", 'C:\vagrant'
    win_path.tr! "/", '\\'

    linux_path = path.gsub 'C:\vagrant', "/vagrant"
    linux_path.tr! '\\', "/"

    dir_win_path = is_file ? win_path.split("\\")[0..-2].join("\\") : win_path
    dir_win_path = dir_win_path[0..-2] if dir_win_path.end_with? '\\', '/'

    dir_linux_path = is_file ? linux_path.split("/")[0..-2].join("/") : linux_path
    dir_linux_path = dir_linux_path[0..-2] if dir_linux_path.end_with? '\\', '/'

    mapping[win_path] =
      if host_type == :WSL
        if guest_type == :linux
          dir_linux_path
        else
          dir_win_path
        end
      else
        # windows
        if guest_type == :linux
          dir_linux_path
        else
          dir_win_path
        end
      end
  end

  describe "#sync_folder" do
    %i[windows linux].map do |guest_type|
      context "syncs folders to #{guest_type} guest" do
        %i[Windows WSL].map do |host_type|
          context "in #{host_type} environment" do
            let(:host_type) { host_type }
            let(:guest_type) { guest_type }
            let(:separator) { separators[host_type] }
            let(:input_paths) { paths[host_type] }
            let(:expanded_hostpath) { expanded_hostpaths[host_type] }
            let(:expanded_hostpath_windows) { expanded_hostpaths[:Windows] }
            let(:guestpath) { guestpaths[guest_type] }
            let(:test_data) { generate_test_data input_paths, separator }
            let(:includes) { test_data[:includes] }
            let(:dir_mappings) do
              mappings = {}
              includes[:dirs].map do |dir|
                convert_path(mappings, dir, host_type, guest_type, is_file: false)
              end
              mappings
            end
            let(:files_mappings) do
              mappings = {}
              includes[:files].map do |file|
                convert_path(mappings, file, host_type, guest_type, is_file: true)
              end
              mappings
            end
            let(:opts) do
              shared_folder.dup.tap do |opts|
                opts[:guestpath] = guestpath
              end
            end

            before do
              allow(guest).to receive(:name).and_return(guest_type)
              allow(VagrantPlugins::HyperV::SyncHelper).to receive(:expand_path).
                with(hostpath).and_return(expanded_hostpath)
              allow(Vagrant::Util::Platform).to receive(:format_windows_path).
                with(expanded_hostpath, :disable_unc).and_return(expanded_hostpath_windows)
              allow(described_class).to receive(:find_includes).
                with(hostpath, exclude).and_return(includes)
              allow(guest).to receive(:capability).with(:create_directories, dir_mappings.values)
              allow(driver).to receive(:sync_files).
                with(vm_id, dir_mappings, files_mappings, is_win_guest: guest_type == :windows)
            end

            after { expect(described_class.sync_folder(machine, opts)) }

            it "expands host path to full path" do
              expect(VagrantPlugins::HyperV::SyncHelper).to receive(:expand_path).
                with(hostpath).and_return(expanded_hostpath)
            end

            it "formats expanded full path to windows path" do
              expect(Vagrant::Util::Platform).to receive(:format_windows_path).
                with(expanded_hostpath, :disable_unc).and_return(expanded_hostpath_windows)
            end

            it "finds all files included in transfer" do
              expect(described_class).to receive(:find_includes).
                with(hostpath, exclude).and_return(includes)
            end

            it "calls create_directories to make directories" do
              expect(guest).to receive(:capability).with(:create_directories, dir_mappings.values)
            end

            it "calls driver #sync_files to sync files" do
              expect(driver).to receive(:sync_files).
                with(vm_id, dir_mappings, files_mappings, is_win_guest: guest_type == :windows)
            end
          end
        end
      end
    end
  end

  describe "#find_includes" do
    %i[windows linux].map do |guest_type|
      context "#{guest_type} guest" do
        %i[Windows WSL].map do |host_type|
          context "in #{host_type} environment" do
            let(:host_type) { host_type }
            let(:separator) { separators[host_type] }
            let(:input_paths) { paths[host_type] }
            let(:expanded_hostpath) { expanded_hostpaths[host_type] }
            let(:test_data) { generate_test_data input_paths, separator }
            let(:test_files) { test_data[:files] }
            let(:test_includes) { test_data[:includes] }
            let(:test_excludes) { test_data[:excludes] }

            before do
              allow(VagrantPlugins::HyperV::SyncHelper).to receive(:expand_path).
                with(hostpath).and_return(expanded_hostpath)
              allow(VagrantPlugins::HyperV::SyncHelper).to receive(:expand_excludes).
                with(hostpath, exclude).and_return(test_excludes)
              allow(Find).to receive(:find).with(expanded_hostpath) do |arg, &proc|
                test_files.map do |file|
                  proc.call file
                end
              end
            end

            after do
              expect(described_class.send(:find_includes, hostpath, exclude)).to eq(test_includes)
            end

            it "expands host path to full path" do
              allow(VagrantPlugins::HyperV::SyncHelper).to receive(:expand_path).
                with(hostpath).and_return(expanded_hostpath)
            end

            it "expands excluded files and directories for exclusion" do
              allow(VagrantPlugins::HyperV::SyncHelper).to receive(:expand_excludes).
                with(hostpath, exclude).and_return(test_excludes)
            end

            it "locates all files in expanded host path" do
              expect(Find).to receive(:find).with(expanded_hostpath)
            end
          end
        end
      end
    end
  end
end
