require "pathname"
require "tmpdir"

require "vagrant/util/safe_exec"

module VagrantPlugins
  module HostWindows
    module Cap
      class PS
        def self.ps_client(env, ps_info)
          logger = Log4r::Logger.new("vagrant::hosts::windows")

          command = <<-EOS
            $plain_password = "#{ps_info[:password]}"
            $username = "#{ps_info[:username]}"
            $port = "#{ps_info[:port]}"
            $hostname = "#{ps_info[:host]}"
            $password = ConvertTo-SecureString $plain_password -asplaintext -force
            $creds = New-Object System.Management.Automation.PSCredential ("$hostname\\$username", $password)
            function prompt { kill $PID }
            Enter-PSSession -ComputerName $hostname -Credential $creds -Port $port
          EOS

          logger.debug("Starting remote powershell with command:\n#{command}")

          args = ["-NoProfile"]
          args << "-ExecutionPolicy"
          args << "Bypass"
          args << "-NoExit"
          args << "-EncodedCommand"
          args << ::WinRM::PowershellScript.new(command).encoded
          if ps_info[:extra_args]
            args << ps_info[:extra_args]
          end

          # Launch it
          Vagrant::Util::SafeExec.exec("powershell", *args)
        end
      end
    end
  end
end
