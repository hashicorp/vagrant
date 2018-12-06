require "zip"
require "vagrant/plugin/state_file"

module Vagrant
  module GoPlugin
    class Manager
      include Util::Logger

      # @return [Manager]
      def self.instance(env=nil)
        @instance ||= self.new
        if env
          @instance.envirnoment = env
        end
        @instance
      end

      # @return [StateFile] user defined plugins
      attr_reader :user_file
      # @return [StateFile, nil] project local defined plugins
      attr_reader :local_file

      def initialize
        FileUtils.mkdir_p(INSTALL_DIRECTORY)
        FileUtils.mkdir_p(Vagrant.user_data_path.join("tmp").to_s)
        @user_file = Plugin::StateFile.new(Vagrant.user_data_path.join("plugins.json"))
      end

      # Load global plugins
      def globalize!
        Dir.glob(File.join(INSTALL_DIRECTORY, "*")).each do |entry|
          next if !File.directory?(entry)
          logger.debug("loading go plugins from directory: #{entry}")
          GoPlugin.interface.load_plugins(entry)
        end
        GoPlugin.interface.register_plugins
      end

      # Load local plugins
      def localize!
        raise NotImplementedError
      end

      # Install a go plugin
      #
      # @param [String] plugin_name Name of plugin
      # @param [String] remote_source Location of plugin for download
      # @param [Hash] options Currently unused
      def install_plugin(plugin_name, remote_source, options={})
        install_dir = File.join(INSTALL_DIRECTORY, plugin_name)
        FileUtils.mkdir_p(install_dir)
        Dir.mktmpdir("go-plugin", Vagrant.user_data_path.join("tmp").to_s) do |dir|
          dest_file = File.join(dir, "plugin.zip")
          logger.debug("downloading go plugin #{plugin_name} from #{remote_source}")
          Util::Downloader.new(remote_source, dest_file).download!
          logger.debug("extracting go plugin #{plugin_name} from #{dest_file}")
          Zip::File.open(dest_file) do |zfile|
            zfile.each do |entry|
              install_path = File.join(install_dir, entry.name)
              if File.file?(install_path)
                logger.warn("removing existing plugin path for unpacking - #{install_path}")
                File.delete(install_path)
              end
              entry.extract(install_path)
              FileUtils.chmod(0755, install_path)
            end
          end
        end
        user_file.add_go_plugin(plugin_name, source: remote_source)
      end

      # Uninstall a go plugin
      #
      # @param [String] plugin_name Name of plugin
      # @param [Hash] options Currently unused
      def uninstall_plugin(plugin_name, options={})
        plugin_path = File.join(INSTALL_DIRECTORY, plugin_name)
        if !File.directory?(plugin_path)
          logger.warn("Plugin directory does not exist for #{plugin_name} - #{plugin_path}")
        else
          logger.debug("deleting go plugin from path #{plugin_path}")
          FileUtils.rm_rf(plugin_path)
        end
        user_file.remove_go_plugin(plugin_name)
      end
    end
  end
end
