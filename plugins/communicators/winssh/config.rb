require File.expand_path("../../../kernel_v2/config/ssh", __FILE__)

module VagrantPlugins
  module CommunicatorWinSSH
    class Config < VagrantPlugins::Kernel_V2::SSHConfig

      attr_accessor :upload_directory

      def initialize
        super
        @upload_directory = UNSET_VALUE
      end

      def finalize!
        @shell = "cmd" if @shell == UNSET_VALUE
        @sudo_command = "%c" if @sudo_command == UNSET_VALUE
        @upload_directory = "C:\\Windows\\Temp" if @upload_directory == UNSET_VALUE
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

      # Remove configuration options from regular SSH that are
      # not used within this communicator
      undef :forward_x11
      undef :pty
    end
  end
end
