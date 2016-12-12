require "vagrant"

module VagrantPlugins
  module Ansible
    class Helpers
      def self.expand_path_in_unix_style(path, base_dir)
        # Remove the possible drive letter, which is added
        # by `File.expand_path` when running on a Windows host
        File.expand_path(path, base_dir).sub(/^[a-zA-Z]:/, "")
      end

      def self.as_list_argument(v)
        v.kind_of?(Array) ? v.join(',') : v
      end
   end
  end
end