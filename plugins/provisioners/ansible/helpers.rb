require "vagrant"

module VagrantPlugins
  module Ansible
    class Helpers
      def self.stringify_ansible_playbook_command(env, command)
        shell_command = ''
        env.each_pair do |k, v|
          if k == 'ANSIBLE_SSH_ARGS'
            shell_command += "#{k}='#{v}' "
          else
            shell_command += "#{k}=#{v} "
          end
        end

        shell_arg = []
        command.each do |arg|
          if arg =~ /(--start-at-task|--limit)=(.+)/
            shell_arg << %Q(#{$1}="#{$2}")
          elsif arg =~ /(--extra-vars)=(.+)/
            shell_arg << %Q(%s="%s") % [$1, $2.gsub('\\', '\\\\\\').gsub('"', %Q(\\"))]
          else
            shell_arg << arg
          end
        end

        shell_command += shell_arg.join(' ')
      end

      def self.expand_path_in_unix_style(path, base_dir)
        # Remove the possible drive letter, which is added
        # by `File.expand_path` when running on a Windows host
        File.expand_path(path, base_dir).sub(/^[a-zA-Z]:/, "")
      end

      def self.as_list_argument(v)
        v.kind_of?(Array) ? v.join(',') : v
      end

      def self.as_array(v)
        v.kind_of?(Array) ? v : [v]
      end
   end
  end
end