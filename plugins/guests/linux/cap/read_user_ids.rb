module VagrantPlugins
  module GuestLinux
    module Cap
      class ReadUserIDs
        def self.read_uid(machine)
          command = "id -u"
          result  = ""
          machine.communicate.execute(command) do |type, data|
            result << data if type == :stdout
          end

          result.chomp.split("\n").first
        end

        def self.read_gid(machine)
          command = "id -g"
          result  = ""
          machine.communicate.execute(command) do |type, data|
            result << data if type == :stdout
          end

          result.chomp.split("\n").first
        end

      end
    end
  end
end
