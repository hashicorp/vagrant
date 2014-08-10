require "pathname"
require "tmpdir"

require "vagrant/util/subprocess"

module VagrantPlugins
  module HostWindows
    module Cap
      class PS
        def self.rdp_client(env, ps_info)
          command = <<-EOS
            $plain_password = "#{ps_info[:password]}"
            $username = "#{ps_info[:username]}"
            $port = "#{ps_info[:port]}"
            $host = "#{ps_info[:host]}"
            $password = ConvertTo-SecureString $plain_password -asplaintext -force
            $creds = New-Object System.Management.Automation.PSCredential ("$host\\$username", $password)
            Enter-PSSession -ComputerName $host -Credential $creds -Port $port
          EOS

          command = command.chars.to_a.join("\x00").chomp
          command << "\x00" unless command[-1].eql? "\x00"
          if(defined?(command.encode))
            command = command.encode('ASCII-8BIT')
            command = Base64.strict_encode64(command)
          else
            command = Base64.encode64(command).chomp
          end

          # Build up the args to mstsc
          args = ["-NoProfile"]
          args << "-ExecutionPolicy"
          args << "Bypass"
          args << "-EncodedCommand"
          args << command
          if ps_info[:extra_args]
            args << ps_info[:extra_args]
          end

          # Launch it
          Vagrant::Util::Subprocess.execute("powershell", *args)
        end
      end
    end
  end
end
