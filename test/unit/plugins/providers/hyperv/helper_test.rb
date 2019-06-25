require 'find'
require 'zip'

require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/helper")

describe VagrantPlugins::HyperV::SyncHelper do
  subject { described_class }

  let(:vm_id) { "vm_id" }
  let(:guest) { double("guest") }
  let(:comm) { double("comm") }
  let(:machine) { double("machine", provider: provider, guest: guest, id: vm_id, communicate: comm) }
  let(:provider) { double("provider", driver: driver) }
  let(:driver) { double("driver") }
  let(:separators) { { Windows: '\\', WSL: "/" } }

  def random_name
    (0...8).map { ('a'..'z').to_a[rand(26)] }.join
  end

  def generate_random_file(files, path, separator, is_directory: true)
    prefix = is_directory ? "dir" : "file"
    fn = [path, "#{prefix}_#{random_name}"].join(separator)
    files << fn
    allow(subject).to receive(:directory?).with(fn).and_return(is_directory)
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

    guest_path =
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
    mapping[:hyperv][win_path] = guest_path
    mapping[:platform][host_type == :Windows ? win_path : linux_path] = guest_path
  end

  describe "#expand_excludes" do
    let(:hostpath) { 'vagrant' }
    let(:expanded_hostpaths) do
      { Windows: 'C:\vagrant', WSL: "/vagrant" }
    end
    let(:exclude) { [".git/"] }
    let(:exclude_dirs) { %w[.vagrant/ .git/] }

    %i[Windows WSL].map do |host_type|
      context "in #{host_type} environment" do
        let(:host_type) { host_type }
        let(:is_windows) { host_type == :Windows }
        let(:separator) { separators[host_type] }
        let(:expanded_hostpath) { expanded_hostpaths[host_type] }

        before do
          allow(Vagrant::Util::Platform).to receive(:wsl?).and_return(false)
          allow(subject).to receive(:expand_path).with(hostpath).and_return(expanded_hostpath)
        end

        it "expands excludes into file and dir list" do
          files = []
          dirs = []
          exclude_dirs.map do |dir|
            fullpath = [expanded_hostpath, dir[0..-2]].join(separator)
            allow(subject).to receive(:platform_join).
              with(expanded_hostpath, dir, is_windows: false).and_return(fullpath)

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

  describe "#sync_single" do
    let(:hostpath) { 'vagrant' }
    let(:expanded_hostpaths) do
      { Windows: 'C:\vagrant', WSL: "/vagrant" }
    end
    let(:guestpaths) do
      { windows: 'C:\vagrant', linux: "/vagrant" }
    end
    let(:remote_guestdirs) do
      { windows: 'C:\Windows\tmp', linux: "/tmp" }
    end
    let(:paths) do
      { Windows: %w[C:\vagrant C:\vagrant\.vagrant C:\vagrant\.git C:\vagrant\test],
        WSL: %w[/vagrant /vagrant/.vagrant /vagrant/.git /vagrant/test] }
    end
    let(:exclude) { [".git/"] }
    let(:ssh_info) { { username: "vagrant" } }
    let(:no_compression) { false }

    %i[windows linux].map do |guest_type|
      context "#{guest_type} guest" do
        let(:guest_type) { guest_type }
        let(:is_win_guest) { guest_type == :windows }
        let(:guestpath) { guestpaths[guest_type] }
        let(:remote_guestdir) { remote_guestdirs[guest_type] }

        before { allow(guest).to receive(:name).and_return(guest_type) }

        %i[Windows WSL].map do |host_type|
          let(:host_type) { host_type }
          let(:separator) { separators[host_type] }
          let(:input_paths) { paths[host_type] }
          let(:expanded_hostpath) { expanded_hostpaths[host_type] }
          let(:test_data) { generate_test_data input_paths, separator }
          let(:test_includes) { test_data[:includes] }
          let(:folder_opts) do
            h = { hostpath: hostpath,
                  guestpath: guestpath,
                  exclude: exclude }
            h = !no_compression ? h : h.dup.merge({no_compression: no_compression})
            h
          end

          before do
            allow(subject).to receive(:expand_path).
              with(hostpath).and_return(expanded_hostpath)
          end

          after { subject.sync_single(machine, ssh_info, folder_opts) }

          context "in #{host_type} environment" do
            before do
              allow(subject).to receive(:find_includes).with(hostpath, exclude).and_return(test_includes)
            end

            context "with no compression" do
              let(:no_compression) { true }
              let(:dir_mappings) do
                mappings = { hyperv: {}, platform: {} }
                test_includes[:dirs].map do |dir|
                  convert_path(mappings, dir, host_type, guest_type, is_file: false)
                end
                mappings
              end
              let(:files_mappings) do
                mappings = { hyperv: {}, platform: {} }
                test_includes[:files].map do |file|
                  convert_path(mappings, file, host_type, guest_type, is_file: true)
                end
                mappings
              end

              before do
                allow(subject).to receive(:path_mapping).
                  with(hostpath, guestpath, test_includes, is_win_guest: is_win_guest).
                  and_return({dirs: dir_mappings, files: files_mappings})
                allow(subject).to receive(:remove_directory).
                  with(machine, guestpath, is_win_guest: is_win_guest, sudo: true)
                allow(guest).to receive(:capability).
                  with(:create_directories, dir_mappings[:hyperv].values, sudo: true)
                allow(subject).to receive(:hyperv_copy?).with(machine).and_return(true)
                allow(driver).to receive(:sync_files).
                  with(machine.id, dir_mappings[:hyperv], files_mappings[:hyperv], is_win_guest: is_win_guest)
              end

              context "copy with Hyper-V daemons" do
                it "calls driver#sync_files to sync all files at once" do
                  expect(driver).to receive(:sync_files).
                    with(machine.id, dir_mappings[:hyperv], files_mappings[:hyperv], is_win_guest: is_win_guest)
                end
              end

              context "copy with WinRM" do
                let(:stat) { double("stat", symlink?: false)}

                before do
                  allow(subject).to receive(:hyperv_copy?).with(machine).and_return(false)
                  allow(subject).to receive(:file_exist?).and_return(true)
                  allow(subject).to receive(:file_stat).and_return(stat)
                  allow(comm).to receive(:upload)
                end

                it "calls WinRM to upload files" do
                  files_mappings[:platform].each do |host_path, guest_path|
                    expect(subject).to receive(:file_exist?).ordered.with(host_path).and_return(true)
                    expect(subject).to receive(:file_stat).ordered.with(host_path).and_return(stat)
                    expect(comm).to receive(:upload).ordered.with(host_path, guest_path)
                  end
                end
              end

              it "removes destination dir and creates directory structure on guest" do
                expect(subject).to receive(:remove_directory).
                  with(machine, guestpath, is_win_guest: is_win_guest, sudo: true)
                expect(guest).to receive(:capability).
                  with(:create_directories, dir_mappings[:hyperv].values, sudo: true)
              end
            end

            context "with compression" do
              let(:compression_type) { guest_type == :windows ? :zip : :tgz }
              let(:remote_guestpath) { [remote_guestdir, "remote_#{compression_type}"].join separator }
              let(:archive_name) { [expanded_hostpath, "vagrant_tmp.#{compression_type}"].join separator }

              before do
                allow(subject).to receive(:compress_source_zip).
                  with(expanded_hostpath, test_includes[:files]).and_return(archive_name)
                allow(subject).to receive(:compress_source_tgz).
                  with(expanded_hostpath, test_includes[:files]).and_return(archive_name)
                allow(guest).to receive(:capability).
                  with(:create_tmp_path, extension: ".#{compression_type}").and_return(remote_guestpath)
                allow(subject).to receive(:upload_file).
                  with(machine, archive_name, remote_guestpath, is_win_guest: is_win_guest)
                allow(subject).to receive(:remove_directory).
                  with(machine, guestpath, is_win_guest: is_win_guest, sudo: true)
                allow(guest).to receive(:capability).
                  with("decompress_#{compression_type}".to_sym, remote_guestpath, guestpath, type: :directory, sudo: true)
                allow(subject).to receive(:file_exist?).with(archive_name).and_return(true)
                allow(FileUtils).to receive(:rm_f).with(archive_name)
              end

              it "compresses the host directory to archive" do
                expect(subject).to receive("compress_source_#{compression_type}".to_sym).
                  with(expanded_hostpath, test_includes[:files]).and_return(archive_name)
              end

              it "creates temporary path on guest" do
                expect(guest).to receive(:capability).
                  with(:create_tmp_path, extension: ".#{compression_type}").and_return(remote_guestpath)
              end

              it "uploads archive file to temporary path on guest" do
                allow(subject).to receive(:upload_file).
                  with(machine, archive_name, remote_guestpath, is_win_guest: is_win_guest)
              end

              it "removes destination dir and decompresses archive file at temporary path on guest" do
                expect(subject).to receive(:remove_directory).
                  with(machine, guestpath, is_win_guest: is_win_guest, sudo: true)
                expect(guest).to receive(:capability).
                  with("decompress_#{compression_type}".to_sym, remote_guestpath, guestpath, type: :directory, sudo: true)
              end

              it "removes temporary archive file" do
                expect(FileUtils).to receive(:rm_f).with(archive_name)
              end
            end
          end
        end
      end
    end
  end

  describe "#find_includes" do
    let(:hostpath) { 'vagrant' }
    let(:expanded_hostpaths) do
      { Windows: 'C:\vagrant', WSL: "/vagrant" }
    end
    let(:exclude) { [".git/"] }
    let(:paths) do
      { Windows: %w[C:\vagrant C:\vagrant\.vagrant C:\vagrant\.git C:\vagrant\test],
        WSL: %w[/vagrant /vagrant/.vagrant /vagrant/.git /vagrant/test] }
    end

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
              allow(subject).to receive(:expand_path).
                with(hostpath).and_return(expanded_hostpath)
              allow(subject).to receive(:expand_excludes).
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
              allow(subject).to receive(:expand_path).
                with(hostpath).and_return(expanded_hostpath)
            end

            it "expands excluded files and directories for exclusion" do
              allow(subject).to receive(:expand_excludes).
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

  describe "#path_mapping" do
    let(:hostpath) { 'vagrant' }
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

    %i[windows linux].map do |guest_type|
      context "maps dirs and files for copy on #{guest_type} guest" do
        let(:guest_type) { guest_type }
        let(:is_win_guest) { guest_type == :windows }

        %i[Windows WSL].map do |host_type|
          context "in #{host_type} environment" do
            let(:is_windows) { host_type == :Windows }
            let(:host_type) { host_type }
            let(:separator) { separators[host_type] }
            let(:input_paths) { paths[host_type] }
            let(:expanded_hostpath) { expanded_hostpaths[host_type] }
            let(:expanded_hostpath_windows) { expanded_hostpaths[:Windows] }
            let(:guestpath) { guestpaths[guest_type] }
            let(:test_data) { generate_test_data input_paths, separator }
            let(:includes) { test_data[:includes] }
            let(:dir_mappings) do
              mappings = { hyperv: {}, platform: {} }
              includes[:dirs].map do |dir|
                convert_path(mappings, dir, host_type, guest_type, is_file: false)
              end
              mappings
            end
            let(:files_mappings) do
              mappings = { hyperv: {}, platform: {} }
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
              allow(subject).to receive(:expand_path).
                with(hostpath).and_return(expanded_hostpath)
              allow(Vagrant::Util::Platform).to receive(:wsl?).and_return(!is_windows)
              allow(Vagrant::Util::Platform).to receive(:windows_path).
                with(expanded_hostpath, :disable_unc).and_return(expanded_hostpath_windows)
            end

            after { expect(subject.path_mapping(hostpath, guestpath, includes, is_win_guest: is_win_guest)).to eq({ dirs: dir_mappings, files: files_mappings }) }

            it "expands host path to full path" do
              expect(subject).to receive(:expand_path).
                with(hostpath).and_return(expanded_hostpath)
            end

            it "formats expanded full path to windows path" do
              expect(Vagrant::Util::Platform).to receive(:windows_path).
                with(expanded_hostpath, :disable_unc).and_return(expanded_hostpath_windows)
            end
          end
        end
      end
    end
  end

  describe "#compress_source_zip" do
    let(:windows_temps) { { Windows: 'C:\Windows\tmp', WSL: "/mnt/c/Windows/tmp" } }
    let(:paths) do
      { Windows: 'C:\vagrant', WSL: "/vagrant" }
    end
    let(:dir_items) { { Windows: 'C:\vagrant\dir1', WSL: '/vagrant/dir1' } }
    let(:source_items) { { Windows: %w(C:\vagrant\file1 C:\vagrant\file2 C:\vagrant\dir1 C:\vagrant\dir1\file2),
                           WSL: %w(/vagrant/file1 /vagrant/file2 /vagrant/dir1 /vagrant/dir1/file2) } }

    %i[Windows WSL].map do |host_type|
      context "in #{host_type} environment" do
        let(:is_windows) { host_type == :Windows }
        let(:host_type) { host_type }
        let(:separator) { separators[host_type] }
        let(:windows_temp) { windows_temps[host_type] }
        let(:path) { paths[host_type] }
        let(:dir_item) { dir_items[host_type] }
        let(:platform_source_items) { source_items[host_type] }
        let(:zip_path) { [windows_temp, "vagrant_test_tmp.zip"].join separator }
        let(:zip_file) { double("zip_file", path: zip_path) }
        let(:zip) { double("zip") }
        let(:stat) { double("stat", symlink?: false)}
        let(:zip_output_stream) { double("zip_output_stream") }
        let(:source_file) { double("source_file") }
        let(:content) { "ABC" }

        before do
          allow(subject).to receive(:format_windows_temp).and_return(windows_temp)
          allow(Tempfile).to receive(:create).and_return(zip_file)
          allow(zip_file).to receive(:close)
          allow(Zip::File).to receive(:open).with(zip_path, Zip::File::CREATE).and_yield(zip)

          allow(subject).to receive(:file_exist?).and_return(true)
          allow(subject).to receive(:file_stat).and_return(stat)
          allow(subject).to receive(:directory?).and_return(false)
          allow(subject).to receive(:directory?).with(dir_item).and_return(true)

          allow(zip).to receive(:get_entry).with(/[\.|dir?]/).and_raise(Errno::ENOENT)
          allow(zip).to receive(:mkdir).with(/[\.|dir?]/)
          allow(zip).to receive(:get_output_stream).with(/.*file?/).and_yield(zip_output_stream)
          allow(File).to receive(:open).with(/.*/, "rb").and_return(source_file)
          allow(source_file).to receive(:read).with(2048).and_return(content, nil)
          allow(zip_output_stream).to receive(:write).with(content)
        end

        after { expect(subject.compress_source_zip(path, platform_source_items)).to eq(zip_path) }

        it "creates a temporary file for writing" do
          expect(subject).to receive(:format_windows_temp).and_return(windows_temp)
          expect(Tempfile).to receive(:create).and_return(zip_file)
          expect(Zip::File).to receive(:open).with(zip_path, Zip::File::CREATE).and_yield(zip)
        end

        it "skips directory" do
          expect(File).to receive(:open).with(dir_item, "rb").never
        end

        it "writes file content to zip archive" do
          expect(File).to receive(:open).with(/.*/, "rb").and_return(source_file)
          expect(source_file).to receive(:read).with(2048).and_return(content, nil)
          expect(zip_output_stream).to receive(:write).with(content)
        end

        it "processes all files" do
          allow(zip).to receive(:get_output_stream).with(/.*file?/).exactly(platform_source_items.length - 1).times
        end
      end
    end
  end

  describe "#compress_source_tgz" do
    let(:windows_temps) { { Windows: 'C:\Windows\tmp', WSL: "/mnt/c/Windows/tmp" } }
    let(:paths) do
      { Windows: 'C:\vagrant', WSL: "/vagrant" }
    end
    let(:dir_items) { { Windows: 'C:\vagrant\dir1', WSL: '/vagrant/dir1' } }
    let(:symlink_items) { { Windows: 'C:\vagrant\file2', WSL: '/vagrant/file2' } }
    let(:source_items) { { Windows: %w(C:\vagrant\file1 C:\vagrant\file2 C:\vagrant\dir1 C:\vagrant\dir1\file2),
                           WSL: %w(/vagrant/file1 /vagrant/file2 /vagrant/dir1 /vagrant/dir1/file2) } }

    %i[Windows WSL].map do |host_type|
      context "in #{host_type} environment" do
        let(:is_windows) { host_type == :Windows }
        let(:host_type) { host_type }
        let(:separator) { separators[host_type] }
        let(:windows_temp) { windows_temps[host_type] }
        let(:path) { paths[host_type] }
        let(:dir_item) { dir_items[host_type] }
        let(:symlink_item) { symlink_items[host_type] }
        let(:platform_source_items) { source_items[host_type] }
        let(:tar_path) { [windows_temp, "vagrant_test_tmp.tar"].join separator }
        let(:tgz_path) { [windows_temp, "vagrant_test_tmp.tgz"].join separator }
        let(:tar_file) { double("tar_file", path: tar_path) }
        let(:tgz_file) { double("tgz_file", path: tgz_path) }
        let(:tar) { double("tar") }
        let(:tgz) { double("tgz") }
        let(:file_mode) { 0744 }
        let(:stat) { double("stat", symlink?: false, mode: file_mode)}
        let(:stat_symlink) { double("stat_symlink", symlink?: true, mode: file_mode)}
        let(:tar_io) { double("tar_io") }
        let(:source_file) { double("source_file") }
        let(:content) { "ABC" }

        before do
          allow(subject).to receive(:format_windows_temp).and_return(windows_temp)
          allow(Tempfile).to receive(:create).and_return(tar_file, tgz_file)
          allow(File).to receive(:open).with(tar_path, "wb+").and_return(tar_file)
          allow(File).to receive(:open).with(tgz_path, "wb").and_return(tgz_file)
          allow(Gem::Package::TarWriter).to receive(:new).with(tar_file).and_return(tar)
          allow(Zlib::GzipWriter).to receive(:new).with(tgz_file).and_return(tgz)

          allow(File).to receive(:delete).with(tar_path)
          allow(tar_file).to receive(:close)
          allow(tar_file).to receive(:read)
          allow(tar_file).to receive(:rewind)
          allow(tgz_file).to receive(:close)

          allow(tar).to receive(:mkdir)
          allow(tar).to receive(:add_symlink)
          allow(tar).to receive(:add_file).and_yield(tar_io)
          allow(tar).to receive(:close)
          allow(tgz).to receive(:mkdir)
          allow(tgz).to receive(:write)
          allow(tgz).to receive(:close)

          allow(subject).to receive(:file_exist?).and_return(true)
          allow(subject).to receive(:file_stat).and_return(stat)
          allow(subject).to receive(:directory?).and_return(false)
          allow(subject).to receive(:directory?).with(dir_item).and_return(true)
          allow(File).to receive(:open).with(/.*/, "rb").and_yield(source_file)
          allow(source_file).to receive(:read).and_return(content, nil)
          allow(tar_io).to receive(:write)
        end

        after { expect(subject.compress_source_tgz(path, platform_source_items)).to eq(tgz_path) }

        it "creates temporary tar/tgz for writing" do
          expect(subject).to receive(:format_windows_temp).and_return(windows_temp)
          expect(Tempfile).to receive(:create).and_return(tar_file, tgz_file)
          expect(File).to receive(:open).with(tar_path, "wb+").and_return(tar_file)
          expect(File).to receive(:open).with(tgz_path, "wb").and_return(tgz_file)
          expect(Gem::Package::TarWriter).to receive(:new).with(tar_file).and_return(tar)
          expect(Zlib::GzipWriter).to receive(:new).with(tgz_file).and_return(tgz)
        end

        it "creates directories in tar" do
          expect(tar).to receive(:mkdir).with(dir_item.sub(path, ""), file_mode)
        end

        it "writes file content to tar archive" do
          expect(File).to receive(:open).with(/.*/, "rb").and_yield(source_file)
          expect(source_file).to receive(:read).and_return(content, nil)
          expect(tar_io).to receive(:write).with(content)
        end

        it "deletes tar file eventually" do
          expect(File).to receive(:delete).with(tar_path)
        end

        it "processes all files" do
          expect(tar).to receive(:add_file).with(/.*file?/, file_mode).exactly(platform_source_items.length - 1).times
        end

        it "does not treat symlink as normal file" do
          allow(subject).to receive(:file_stat).with(symlink_item).and_return(stat_symlink)
          expect(File).to receive(:readlink).with(symlink_item).and_return("/target")
          expect(tar).to receive(:add_symlink).with(/.*file?/, "/target", file_mode)
        end
      end
    end
  end

  describe "#remove_directory" do
    let(:windows_path) { 'C:\Windows\Temp' }
    let(:unix_path) { "C:/Windows/Temp" }

    [true, false].each do |sudo_flag|
      context "sudo flag: #{sudo_flag}" do
        it "calls powershell script to remove directory" do
          allow(subject).to receive(:to_windows_path).with(unix_path).and_return(windows_path)
          expect(comm).to receive(:execute).with(/.*if \(Test-Path\(\"C:\\Windows\\Temp\"\).*\n.*Remove-Item -Path \"C:\\Windows\\Temp\".*/, shell: :powershell)
          subject.remove_directory machine, unix_path, is_win_guest: true, sudo: sudo_flag
        end

        it "calls linux command to remove directory forcibly" do
          allow(subject).to receive(:to_unix_path).with(windows_path).and_return(unix_path)
          expect(comm).to receive(:test).with("test -d '#{unix_path}'").and_return(true)
          expect(comm).to receive(:execute).with("rm -rf '#{unix_path}'", sudo: sudo_flag)
          subject.remove_directory machine, windows_path, is_win_guest: false, sudo: sudo_flag
        end

        it "does not call rm when directory does not exist" do
          allow(subject).to receive(:to_unix_path).with(windows_path).and_return(unix_path)
          expect(comm).to receive(:test).with("test -d '#{unix_path}'").and_return(false)
          expect(comm).to receive(:execute).never
          subject.remove_directory machine, windows_path, is_win_guest: false, sudo: sudo_flag
        end
      end
    end
  end

  describe "#format_windows_temp" do
    let(:windows_temp) { 'C:\Windows\tmp' }
    let(:unix_temp) { "/mnt/c/Windows/tmp" }

    before { allow(Vagrant::Util::Platform).to receive(:windows_temp).and_return(windows_temp) }

    it "returns Windows style temporary directory" do
      allow(Vagrant::Util::Platform).to receive(:wsl?).and_return(false)
      expect(subject.format_windows_temp).to eq(windows_temp)
    end

    it "returns Unix style temporary directory in WSL" do
      allow(Vagrant::Util::Platform).to receive(:wsl?).and_return(true)
      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("wslpath", "-u", "-a", windows_temp).and_return(double(stdout: unix_temp, exit_code: 0))
      expect(subject.format_windows_temp).to eq(unix_temp)
    end
  end

  describe "#upload_file" do
    let(:sources) { { Windows: 'C:\vagrant\file1.zip', WSL: "/vagrant/file1.zip" } }
    let(:new_sources) { { Windows: 'C:\Windows\tmp\file2.zip', WSL: "/mnt/c/Windows/tmp/file2.zip" } }
    let(:windows_temps) { { Windows: 'C:\Windows\tmp', WSL: "/mnt/c/Windows/tmp" } }
    let(:dests) { { windows: 'C:\vagrant\file2.zip', linux: "/vagrant/file2.zip" } }
    let(:dest_dirs) { { windows: 'C:\vagrant', linux: "/vagrant" } }

    %i[windows linux].map do |guest_type|
      context "#{guest_type} guest" do
        let(:guest_type) { guest_type }
        let(:dest) { dests[guest_type] }
        let(:dest_dir) { dest_dirs[guest_type] }

        %i[Windows WSL].map do |host_type|
          context "in #{host_type} environment" do
            let(:host_type) { host_type }
            let(:is_windows) { host_type == :Windows }
            let(:source) { sources[host_type] }
            let(:new_source) { new_sources[host_type] }

            context "uploads file by Hyper-V daemons when applicable" do
              let(:windows_temp) { windows_temps[host_type] }

              before do
                allow(subject).to receive(:hyperv_copy?).with(machine).and_return(true)
                allow(subject).to receive(:format_windows_temp).and_return(windows_temp)
                allow(Vagrant::Util::Platform).to receive(:wsl?).and_return(!is_windows)
                allow(FileUtils).to receive(:rm_f)
                allow(FileUtils).to receive(:mv)
                allow(subject).to receive(:hyperv_copy)
              end

              after { subject.upload_file machine, source, dest, is_win_guest: guest_type == :windows }

              if host_type != :Windows
                it "moves the source file to new path with the destination filename" do
                  expect(FileUtils).to receive(:mv).with(source, new_source)
                  expect(FileUtils).to receive(:rm_f).with(new_source)
                end
              end

              it "calls Hyper-V cmdlet to copy file" do
                expect(subject).to receive(:hyperv_copy).with(machine, new_source, dest_dir)
              end
            end

            it "uploads file by WinRM when Hyper-V daemons are not applicable" do
              allow(subject).to receive(:hyperv_copy?).with(machine).and_return(false)
              expect(comm).to receive(:upload).with(source, dest)
              expect(subject).to receive(:hyperv_copy).never
              subject.upload_file machine, source, dest, is_win_guest: guest_type == :windows
            end
          end
        end
      end
    end
  end

  describe "#hyperv_copy?" do
    before do
      allow(guest).to receive(:capability?)
      allow(guest).to receive(:capability)
    end

    it "does not leverage Hyper-V daemons when guest does not support Hyper-V daemons" do
      allow(guest).to receive(:capability?).with(:hyperv_daemons_running).and_return(false)
      expect(guest).to receive(:capability).never
    end

    it "checks whether Hyper-V daemons are running" do
      allow(guest).to receive(:capability?).with(:hyperv_daemons_running).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_running).and_return(true)
      expect(subject.hyperv_copy?(machine)).to eq(true)
    end
  end

  describe "#hyperv_copy" do
    let(:source) { 'C:\Windows\test' }
    let(:dest_dir) { "/vagrant" }

    it "calls Copy-VMFile cmdlet to copy file to guest" do
      expect(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/.*Hyper-V\\Get-VM -Id \"vm_id\"\n.*Hyper-V\\Copy-VMFile -VM \$machine -SourcePath \"C:\\Windows\\test\" -DestinationPath \"#{dest_dir}\".*/)
      subject.hyperv_copy(machine, source, dest_dir)
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

  describe "#platform_path" do
    let(:windows_path) { 'C:\Windows\Temp' }
    let(:unix_path) { "C:/Windows/Temp" }

    it "returns Windows style path in Windows" do
      expect(subject.platform_path(unix_path, is_windows: true)).to eq(windows_path)
    end

    it "returns Unix style path in WSL" do
      expect(subject.platform_path(windows_path, is_windows: false)).to eq(unix_path)
    end
  end

  describe "#to_windows_path" do
    let(:windows_path) { 'C:\Windows\Temp' }
    let(:unix_path) { "C:/Windows/Temp" }

    it "converts path with unix separator to Windows" do
      expect(subject.to_windows_path(unix_path)).to eq(windows_path)
    end

    it "keeps the original input for Windows path" do
      expect(subject.to_windows_path(windows_path)).to eq(windows_path)
    end
  end

  describe "#to_unix_path" do
    let(:windows_path) { '\usr\bin\test' }
    let(:unix_path) { "/usr/bin/test" }

    it "converts path with Windows separator to Unix" do
      expect(subject.to_unix_path(windows_path)).to eq(unix_path)
    end

    it "keeps the original input for Unix path" do
      expect(subject.to_unix_path(unix_path)).to eq(unix_path)
    end
  end

  describe "#trim_head" do
    let(:windows_path_no_heading) { 'usr\bin\test' }
    let(:unix_path_no_heading) { "usr/bin/test" }
    let(:windows_path_with_heading) { '\usr\bin\test' }
    let(:unix_path_with_heading) { "/usr/bin/test" }

    it "keeps Windows path with no heading" do
      expect(subject.trim_head(windows_path_no_heading)).to eq(windows_path_no_heading)
    end

    it "keeps Unix path with no heading" do
      expect(subject.trim_head(unix_path_no_heading)).to eq(unix_path_no_heading)
    end

    it "removes heading separator from Windows path" do
      expect(subject.trim_head(windows_path_with_heading)).to eq(windows_path_no_heading)
    end

    it "removes heading separator from Unix path" do
      expect(subject.trim_head(unix_path_with_heading)).to eq(unix_path_no_heading)
    end
  end

  describe "#trim_tail" do
    let(:windows_path_no_tailing) { '\usr\bin\test' }
    let(:unix_path_no_tailing) { "/usr/bin/test" }
    let(:windows_path_with_tailing) { '\usr\bin\test\\' }
    let(:unix_path_with_tailing) { "/usr/bin/test/" }

    it "keeps Windows path with no tailing" do
      expect(subject.trim_tail(windows_path_no_tailing)).to eq(windows_path_no_tailing)
    end

    it "keeps Unix path with no tailing" do
      expect(subject.trim_tail(unix_path_no_tailing)).to eq(unix_path_no_tailing)
    end

    it "removes tailing separator from Windows path" do
      expect(subject.trim_tail(windows_path_with_tailing)).to eq(windows_path_no_tailing)
    end

    it "removes tailing separator from Unix path" do
      expect(subject.trim_tail(unix_path_with_tailing)).to eq(unix_path_no_tailing)
    end
  end
end
