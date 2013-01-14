module VagrantPlugins
  module Puppet
    module Provisioner
      class PuppetServerError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.provisioners.puppet_server")
      end

      class PuppetServer < Vagrant.plugin("2", :provisioner)
        def provision
          verify_binary("puppet")
          run_puppet_agent
        end

        def verify_binary(binary)
          @machine.communicate.sudo(
            "which #{binary}",
            :error_class => PuppetServerError,
            :error_key => :not_detected,
            :binary => binary)
        end

        def run_puppet_agent
          options = config.options
          options = [options] if !options.is_a?(Array)

          # Intelligently set the puppet node cert name based on certain
          # external parameters.
          cn = nil
          if config.puppet_node
            # If a node name is given, we use that directly for the certname
            cn = config.puppet_node
          elsif @machine.config.vm.host_name
            # If a host name is given, we explicitly set the certname to
            # nil so that the hostname becomes the cert name.
            cn = nil
          else
            # Otherwise, we default to the name of the box.
            cn = @machine.config.vm.box
          end

          # Add the certname option if there is one
          options += ["--certname", cn] if cn
          options = options.join(" ")

          # Build up the custom facts if we have any
          facter = ""
          if !config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              facts << "FACTER_#{key}='#{value}'"
            end

            facter = "#{facts.join(" ")} "
          end

          command = "#{facter}puppet agent #{options} --server #{config.puppet_server} --detailed-exitcodes || [ $? -eq 2 ]"

          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet_server.running_puppetd")
          @machine.communicate.sudo(command) do |type, data|
            data.chomp!
            @machine.env.ui.info(data, :prefix => false) if !data.empty?
          end
        end
      end
    end
  end
end
