require_relative '../../linux/cap/change_host_name'

module VagrantPlugins
  module GuestSUSE
    module Cap
      class ChangeHostName
        extend VagrantPlugins::GuestLinux::Cap::ChangeHostName

        def self.change_host_name?(comm, name)
          basename = name.split(".", 2)[0]
          !comm.test("test \"$(hostnamectl --static status)\" = \"#{basename}\"", sudo: false)
        end

        def self.change_name_command(name)
          basename = name.split(".", 2)[0]
          return <<-EOH.gsub(/^ {14}/, "")
          hostnamectl set-hostname '#{basename}'
          echo #{name} > /etc/HOSTNAME
          EOH
        end
      end
    end
  end
end
