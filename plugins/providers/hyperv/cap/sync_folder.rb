require 'find'

require_relative '../helper'

module VagrantPlugins
  module HyperV
    module Cap
      module SyncFolder
        def self.sync_folder(machine, data)
          is_win_guest = machine.guest.name == :windows
          host_path = VagrantPlugins::HyperV::SyncHelper.expand_path(data[:hostpath])
          guest_path = data[:guestpath]
          win_host_path = Vagrant::Util::Platform.format_windows_path(
            host_path, :disable_unc)
          win_guest_path = guest_path.tr '/', '\\'

          includes = find_includes(data[:hostpath], data[:exclude])
          dir_mappings = {}
          file_mappings = {}
          platform_guest_path = is_win_guest ? win_guest_path : guest_path
          { dirs: dir_mappings,
            files: file_mappings }.map do |sym, mapping|
            includes[sym].map do |e|
              guest_rel = e.gsub(host_path, '')
              guest_rel = guest_rel[1..-1] if guest_rel.start_with? '\\', '/'
              guest_rel.tr! '\\', '/'

              # make sure the dir names are Windows-style for them to pass to Hyper-V
              if guest_rel == ''
                win_path = win_host_path
                target = platform_guest_path
              else
                win_path = HyperV::SyncHelper.platform_join(win_host_path, guest_rel)
                target = HyperV::SyncHelper.platform_join(platform_guest_path, guest_rel,
                                                          is_windows: is_win_guest)
              end
              mapping[win_path] = target
            end
          end
          machine.guest.capability(:create_directories, dir_mappings.values)
          machine.provider.driver.sync_files(machine.id, dir_mappings, file_mappings,
                                             is_win_guest: is_win_guest)
        end

        protected

        def self.find_includes(path, exclude)
          expanded_path = HyperV::SyncHelper.expand_path(path)
          excludes = HyperV::SyncHelper.expand_excludes(path, exclude)
          included_dirs = []
          included_files = []
          Find.find(expanded_path) do |e|
            if VagrantPlugins::HyperV::SyncHelper.directory?(e)
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
      end
    end
  end
end
