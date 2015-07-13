require "pathname"

require "vagrant"

module VagrantPlugins
  module HostSUSE
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        old_release_file = Pathname.new("/etc/SuSE-release")

        if old_release_file.exist?
          old_release_file.open("r") do |f|
            return true if f.gets =~ /^(openSUSE|SUSE Linux Enterprise)/
          end
        end

        new_release_file = Pathname.new("/etc/os-release")

        if new_release_file.exist?
          new_release_file.open("r") do |f|
            return true if f.gets =~ /(openSUSE|SLES)/
          end
        end

        false
      end
    end
  end
end
