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
            shell_arg << "#{$1}='#{$2}'"
          else
            shell_arg << arg
          end
        end

        shell_command += shell_arg.join(' ')
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