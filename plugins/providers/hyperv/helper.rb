require "vagrant/util/platform"

module VagrantPlugins
  module HyperV
    class SyncHelper
      WINDOWS_SEPARATOR = "\\"
      UNIX_SEPARATOR = "/"

      # Expands glob-style exclude string
      #
      # @param [String] path Path to operate on
      # @param [String] exclude Array of glob-style exclude strings
      # @return [Hash] Excluded directories and files
      def self.expand_excludes(path, exclude)
        excludes = ['.vagrant/']
        excludes += Array(exclude).map(&:to_s) if exclude
        excludes.uniq!

        expanded_path = expand_path(path)
        excluded_dirs = []
        excluded_files = []
        excludes.map do |exclude|
          # Dir.glob accepts Unix style path only
          excluded_path = platform_join expanded_path, exclude, is_windows: false
          Dir.glob(excluded_path) do |e|
            if directory?(e)
              excluded_dirs << e
            else
              excluded_files << e
            end
          end
        end
        {dirs: excluded_dirs,
         files: excluded_files}
      end

      def self.find_includes(path, exclude)
        expanded_path = expand_path(path)
        excludes = expand_excludes(path, exclude)
        included_dirs = []
        included_files = []
        Find.find(expanded_path) do |e|
          if directory?(e)
            path = File.join e, ''
            next if excludes[:dirs].include? path
            next if excludes[:dirs].select { |x| path.start_with? x }.any?

            included_dirs << e
          else
            next if excludes[:files].include? e
            next if excludes[:dirs].select { |x| e.start_with? x }.any?

            included_files << e
          end
        end
        { dirs: included_dirs,
          files: included_files }
      end

      def self.path_mapping(host_path, guest_path, includes, is_win_guest:)
        host_path = expand_path(host_path)
        platform_host_path = platform_path host_path, is_windows: !Vagrant::Util::Platform.wsl?
        win_host_path = Vagrant::Util::Platform.windows_path(host_path, :disable_unc)
        platform_guest_path = platform_path(guest_path, is_windows: is_win_guest)

        dir_mappings = { hyperv: {}, platform: {} }
        file_mappings = { hyperv: {}, platform: {} }
        { dirs: dir_mappings,
          files: file_mappings }.map do |sym, mapping|
          includes[sym].map do |e|
            guest_rel = e.gsub(host_path, '')
            guest_rel = trim_head guest_rel
            guest_rel = to_unix_path guest_rel

            if guest_rel == ''
              file_host_path = win_host_path
              file_platform_host_path = platform_host_path
              target = platform_guest_path
            else
              file_host_path = platform_join(win_host_path, guest_rel)
              file_platform_host_path = platform_join(platform_host_path, guest_rel,
                                                      is_windows: !Vagrant::Util::Platform.wsl?)
              guest_rel = guest_rel.split(UNIX_SEPARATOR)[0..-2].join(UNIX_SEPARATOR) if sym == :files
              target = platform_join(platform_guest_path, guest_rel, is_windows: is_win_guest)
              target = trim_tail target
            end
            # make sure the dir names are Windows-style for them to pass to Hyper-V
            mapping[:hyperv][file_host_path] = target
            mapping[:platform][file_platform_host_path] = target
          end
        end
        { dirs: dir_mappings, files: file_mappings }
      end

      # Syncs single folder to guest machine
      #
      # @param [Vagrant::Machine] path Path to operate on
      # @param [Hash] ssh_info
      # @param [Hash] opts Synced folder details
      def self.sync_single(machine, ssh_info, opts)
        is_win_guest = machine.guest.name == :windows
        host_path = opts[:hostpath]
        guest_path = opts[:guestpath]

        includes = find_includes(host_path, opts[:exclude])
        if opts[:no_compression]
          # Copy file to guest directly for disk consumption saving
          guest_path_mapping = path_mapping(host_path, guest_path, includes, is_win_guest: is_win_guest)
          remove_directory machine, guest_path, is_win_guest: is_win_guest, sudo: true
          machine.guest.capability(:create_directories, guest_path_mapping[:dirs][:hyperv].values, sudo: true)
          if hyperv_copy? machine
            machine.provider.driver.sync_files(machine.id,
                                               guest_path_mapping[:dirs][:hyperv],
                                               guest_path_mapping[:files][:hyperv],
                                               is_win_guest: is_win_guest)
          else
            guest_path_mapping[:files][:platform].each do |host_path, guest_path|
              next unless file_exist? host_path

              stat = file_stat host_path
              next if stat.symlink?

              machine.communicate.upload(host_path, guest_path)
            end
          end
        else
          source_items = includes[:files]
          type = is_win_guest ? :zip : :tgz
          host_path = expand_path(host_path)
          source = send("compress_source_#{type}".to_sym, host_path, source_items)
          decompress_cap = type == :zip ? :decompress_zip : :decompress_tgz
          begin
            destination = machine.guest.capability(:create_tmp_path, extension: ".#{type}")
            upload_file(machine, source, destination, is_win_guest: is_win_guest)
            remove_directory machine, guest_path, is_win_guest: is_win_guest, sudo: true
            machine.guest.capability(decompress_cap, destination, platform_path(guest_path, is_windows: is_win_guest),
                                     type: :directory, sudo: true)
          ensure
            FileUtils.rm_f source if file_exist? source
          end
        end
      end

      # Compress path using zip into temporary file
      #
      # @param [String] path Path to compress
      # @return [String] path to compressed file
      def self.compress_source_zip(path, source_items)
        require "zip"
        zipfile = Tempfile.create(%w(vagrant .zip), format_windows_temp)
        zipfile.close
        c_dir = nil
        Zip::File.open(zipfile.path, Zip::File::CREATE) do |zip|
          source_items.each do |source_item|
            next unless file_exist? source_item
            next if directory?(source_item)

            stat = file_stat(source_item)
            next if stat.symlink?

            trim_item = source_item.sub(path, "").sub(%r{^[/\\]}, "")
            dirname = File.dirname(trim_item)
            begin
              zip.get_entry(dirname)
            rescue Errno::ENOENT
              zip.mkdir dirname if c_dir != dirname
            end
            c_dir = dirname
            zip.get_output_stream(trim_item) do |f|
              source_file = File.open(source_item, "rb")
              while data = source_file.read(2048)
                f.write(data)
              end
            end
          end
        end
        zipfile.path
      end

      # Compress path using tar and gzip into temporary file
      #
      # @param [String] path Path to compress
      # @return [String] path to compressed file
      def self.compress_source_tgz(path, source_items)
        tmp_dir = format_windows_temp
        tarfile = Tempfile.create(%w(vagrant .tar), tmp_dir)
        tarfile.close
        tarfile = File.open(tarfile.path, "wb+")
        tgzfile = Tempfile.create(%w(vagrant .tgz), tmp_dir)
        tgzfile.close
        tgzfile = File.open(tgzfile.path, "wb")
        tar = Gem::Package::TarWriter.new(tarfile)
        tgz = Zlib::GzipWriter.new(tgzfile)
        source_items.each do |item|
          next unless file_exist? item

          rel_path = item.sub(path, "")
          stat = file_stat(item)
          item_mode = stat.mode

          if directory?(item)
            tar.mkdir(rel_path, item_mode)
          elsif stat.symlink?
            tar.add_symlink(rel_path, File.readlink(item), item_mode)
          else
            tar.add_file(rel_path, item_mode) do |io|
              File.open(item, "rb") do |file|
                while bytes = file.read(4096)
                  io.write(bytes)
                end
              end
            end
          end
        end
        tar.close
        tarfile.rewind
        while bytes = tarfile.read(4096)
          tgz.write bytes
        end
        tgz.close
        tgzfile.close
        tarfile.close
        File.delete(tarfile.path)
        tgzfile.path
      end

      def self.remove_directory(machine, guestpath, is_win_guest: false, sudo: false)
        comm = machine.communicate
        if is_win_guest
          guestpath = to_windows_path guestpath
          cmd = <<-EOH.gsub(/^ {6}/, "")
            if (Test-Path(\"#{guestpath}\")) {
              Remove-Item -Path \"#{guestpath}\" -Recurse -Force
            }
          EOH
          comm.execute(cmd, shell: :powershell)
        else
          guestpath = to_unix_path guestpath
          if comm.test("test -d '#{guestpath}'")
            comm.execute("rm -rf '#{guestpath}'", sudo: sudo)
          end
        end
      end

      def self.format_windows_temp
        windows_temp = Vagrant::Util::Platform.windows_temp
        if Vagrant::Util::Platform.wsl?
          process = Vagrant::Util::Subprocess.execute(
              "wslpath", "-u", "-a", windows_temp)
          windows_temp = process.stdout.chomp if process.exit_code == 0
        end
        windows_temp
      end

      def self.upload_file(machine, source, dest, is_win_guest:)
        begin
          # try Hyper-V guest integration service first as WinRM upload is slower
          if hyperv_copy? machine
            separator = is_win_guest ? WINDOWS_SEPARATOR: UNIX_SEPARATOR
            parts = dest.split(separator)
            filename = parts[-1]
            dest_dir = parts[0..-2].join(separator)

            windows_temp = format_windows_temp
            source_copy = platform_join windows_temp, filename, is_windows: !Vagrant::Util::Platform.wsl?
            FileUtils.mv source, source_copy
            source = source_copy
            hyperv_copy machine, source, dest_dir
          else
            machine.communicate.upload(source, dest)
          end
        ensure
          FileUtils.rm_f source
        end
      end

      def self.hyperv_copy?(machine)
        machine.guest.capability?(:hyperv_daemons_running) && machine.guest.capability(:hyperv_daemons_running)
      end

      def self.hyperv_copy(machine, source, dest_dir)
        vm_id = machine.id
        ps_cmd = <<-EOH.gsub(/^ {6}/, "")
                $machine = Hyper-V\\Get-VM -Id \"#{vm_id}\"
                Hyper-V\\Copy-VMFile -VM $machine -SourcePath \"#{source}\" -DestinationPath \"#{dest_dir}\" -CreateFullPath -FileSource Host -Force
        EOH
        Vagrant::Util::PowerShell.execute_cmd(ps_cmd)
      end

      def self.platform_join(string, *smth, is_windows: true)
        joined = [string, *smth].join is_windows ? WINDOWS_SEPARATOR : UNIX_SEPARATOR
        if is_windows
          to_windows_path joined
        else
          to_unix_path joined
        end
      end

      def self.platform_path(path, is_windows: true)
        win_path = to_windows_path path
        linux_path = to_unix_path path
        is_windows ? win_path : linux_path
      end

      def self.expand_path(*path)
        # stub for unit test
        File.expand_path(*path)
      end

      def self.directory?(path)
        # stub for unit test
        File.directory? path
      end

      def self.file_exist?(path)
        # stub for unit test
        File.exist? path
      end

      def self.file_stat(path)
        # stub for unit test
        File.stat path
      end

      def self.to_windows_path(path)
        path.tr UNIX_SEPARATOR, WINDOWS_SEPARATOR
      end

      def self.to_unix_path(path)
        path.tr WINDOWS_SEPARATOR, UNIX_SEPARATOR
      end

      def self.trim_head(path)
        path.start_with?(WINDOWS_SEPARATOR, UNIX_SEPARATOR) ? path[1..-1] : path
      end

      def self.trim_tail(path)
        path.end_with?(WINDOWS_SEPARATOR, UNIX_SEPARATOR) ? path[0..-2] : path
      end
    end
  end
end
