require "pathname"
require "tmpdir"
require "readline"

module VagrantPlugins
  module HostWindows
    module Cap
      class PS
        def self.ps_client(env, ps_info)
          logger = Log4r::Logger.new("vagrant::hosts::windows")

          logger.debug("Starting remote powershell")

          options = {}
          options[:user] = ps_info[:username]
          options[:password] = ps_info[:password]
          options[:endpoint] = "http://#{ps_info[:host]}:#{ps_info[:port]}/wsman"
          options[:transport] = :plaintext
          options[:basic_auth_only] = true
          options[:operation_timeout] = 3600

          shell = nil

          client = WinRM::Connection.new(options)
          shell = client.shell(:powershell)
          prompt = "[#{options[:user]}@#{URI.parse(options[:endpoint]).host}]: PS> "

          while (buf = Readline.readline(prompt, true))
            if buf =~ /^exit/
              break
            else
              shell.run(buf) do |stdout, stderr|
                $stdout.write stdout
                $stderr.write stderr
              end
            end
          end
        ensure
          shell.close unless shell.nil?
        end

        def self.encoded(script)
          encoded_script = script.encode("UTF-16LE", "UTF-8")
          Base64.strict_encode64(encoded_script)
        end
      end
    end
  end
end
