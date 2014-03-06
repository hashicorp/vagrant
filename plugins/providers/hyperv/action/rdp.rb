require "log4r"
require "pathname"
require "vagrant/util/powershell"

module VagrantPlugins
  module HyperV
    module Action
      # This action generates a .rdp file into the root path of the project.
      # and establishes a RDP session with necessary resource sharing
      class Rdp
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::hyperv::connection")
        end

        def call(env)
          if env[:machine].provider_config.guest != :windows
            raise Errors::WindowsVmRequired,
              guest: env[:machine].provider_config.guest
          end
          @env = env
          generate_rdp_file
          command = ["mstsc", "machine.rdp"]
          Vagrant::Util::PowerShell.execute(*command)
        end

        def generate_rdp_file
          ssh_info = @env[:machine].ssh_info
          rdp_options = {
            "drivestoredirect:s" => "*",
            "username:s" => ssh_info[:username],
            "prompt for credentials:i" => "1",
            "full address:s" => ssh_info[:host]
          }
          file = File.open("machine.rdp", "w")
            rdp_options.each do |key, value|
              file.puts "#{key}:#{value}"
          end
          file.close
        end
      end
    end
  end
end
