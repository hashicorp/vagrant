require File.expand_path("../../../kernel_v2/config/ssh", __FILE__)

# forward_x11 pty sudo_command

module VagrantPlugins
  module CommunicatorWinSSH
    class Config < VagrantPlugins::Kernel_V2::SSHConfig

      def finalize!
        @shell = "cmd" if @shell == UNSET_VALUE
        @sudo_command = "%c" if @sudo_command == UNSET_VALUE
        if @export_command_template == UNSET_VALUE
          if @shell == "cmd"
            @export_command_template = 'set %ENV_KEY%="%ENV_VALUE%"'
          else
            @export_command_template = '$env:%ENV_KEY%="%ENV_VALUE%"'
          end
        end
        super
      end

      def to_s
        "WINSSH"
      end
    end
  end
end
