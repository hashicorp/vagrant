module Vagrant
  module Provisioners
    class Shell < Base
      register :shell

      class Config < Vagrant::Config::Base
        attr_accessor :path
        attr_accessor :upload_path

        def initialize
          @upload_path = "/tmp/vagrant-shell"
        end

        def expanded_path
          Pathname.new(path).expand_path(env.root_path) if path
        end

        def validate(errors)
          super

          if !path
            errors.add(I18n.t("vagrant.provisioners.shell.path_not_set"))
          elsif !expanded_path.file?
            errors.add(I18n.t("vagrant.provisioners.shell.path_invalid", :path => expanded_path))
          end

          if !upload_path
            errors.add(I18n.t("vagrant.provisioners.shell.upload_path_not_set"))
          end
        end
      end

      def provision!
        # Upload the script to the VM
        vm.ssh.upload!(config.expanded_path.to_s, config.upload_path)

        # Execute it with sudo
        vm.ssh.execute do |ssh|
          ssh.sudo!("chmod +x #{config.upload_path}")
          ssh.sudo!(config.upload_path)
        end
      end
    end
  end
end
