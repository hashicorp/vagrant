module VagrantPlugins
  module HostDarwin
    module Cap
      class Path
        @@logger = Log4r::Logger.new("vagrant::host::darwin::path")

        FIRMLINK_DEFS = "/usr/share/firmlinks".freeze
        FIRMLINK_DATA_PATH = "/System/Volumes/Data".freeze

        # Resolve the given host path to the actual
        # usable system path by detecting firmlinks
        # if available on the current system
        #
        # @param [String] path Host system path
        # @return [String] resolved path
        def self.resolve_host_path(env, path)
          path = File.expand_path(path)
          firmlink = firmlink_map.detect do |mount_path, data_path|
            path.start_with?(mount_path)
          end
          return path if firmlink.nil?
          current_prefix, new_suffix = firmlink
          new_prefix = File.join(FIRMLINK_DATA_PATH, new_suffix)
          new_path = path.sub(current_prefix, new_prefix)
          @@logger.debug("Resolved given path `#{path}` to `#{new_path}`")
          new_path
        end

        # Generate mapping of firmlinks if available on the host
        #
        # @return [Hash<String,String>]
        def self.firmlink_map
          if !@firmlink_map
            return @firmlink_map = {} if !File.exist?(FIRMLINK_DEFS)
            begin
              @firmlink_map = Hash[
                File.readlines(FIRMLINK_DEFS).map { |d|
                  d.strip.split(/\s+/, 2)
                }
              ]
            rescue => err
              @@logger.warn("Failed to parse firmlink definitions: #{err}")
              @firmlink_map = {}
            end
          end
          @firmlink_map
        end

        # @private
        # Reset the cached values for capability. This is not considered a public
        # API and should only be used for testing.
        def self.reset!
          instance_variables.each(&method(:remove_instance_variable))
        end
      end
    end
  end
end
