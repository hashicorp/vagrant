module VagrantPlugins
  module Puppet
    module Provisioner
      class PuppetServerError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.provisioners.puppet_server")
      end

      class PuppetServer < Vagrant.plugin("2", :provisioner)
        def provision
          if @machine.config.vm.communicator == :winrm
            raise Vagrant::Errors::ProvisionerWinRMUnsupported,
              name: "puppet_server"
          end

          verify_binary("puppet")
          run_puppet_agent
        end

        def verify_binary(binary)
          @machine.communicate.sudo(
            "which #{binary}",
            error_class: PuppetServerError,
            error_key: :not_detected,
            binary: binary)
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
          elsif @machine.config.vm.hostname
            # If a host name is given, we explicitly set the certname to
            # nil so that the hostname becomes the cert name.
            cn = nil
          else
            # Otherwise, we default to the name of the box.
            cn = @machine.config.vm.box
          end

          # Add the certname option if there is one
          options += ["--certname", cn] if cn

          # A shortcut to make things easier
          comm = @machine.communicate

          # If we have client certs specified, then upload them
          if config.client_cert_path && config.client_private_key_path
            @machine.ui.info(
              I18n.t("vagrant.provisioners.puppet_server.uploading_client_cert"))
            dirname = "/tmp/puppet-#{Time.now.to_i}-#{rand(1000)}"
            comm.sudo("mkdir -p #{dirname}")
            comm.sudo("mkdir -p #{dirname}/certs")
            comm.sudo("mkdir -p #{dirname}/private_keys")
            comm.sudo("chmod -R 0777 #{dirname}")
            comm.upload(config.client_cert_path, "#{dirname}/certs/#{cn}.pem")
            comm.upload(config.client_private_key_path,
              "#{dirname}/private_keys/#{cn}.pem")

            # Setup the options so that they point to our directories
            options << "--certdir=#{dirname}/certs"
            options << "--privatekeydir=#{dirname}/private_keys"
          end

          # Disable colors if we must
          if !@machine.env.ui.color?
            options << "--color=false"
          end

          # Build up the custom facts if we have any
          facter = ""
          if !config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              facts << "FACTER_#{key}='#{value}'"
            end

            facter = "#{facts.join(" ")} "
          end

          options = options.join(" ")
          command = "#{facter}puppet agent --onetime --no-daemonize #{options} " +
            "--server #{config.puppet_server} --detailed-exitcodes || [ $? -eq 2 ]"

          @machine.ui.info I18n.t("vagrant.provisioners.puppet_server.running_puppetd")
          @machine.communicate.sudo(command) do |type, data|
            if !data.chomp.empty?
              @machine.ui.info(data.chomp)
            end
          end
        end
      end
    end
  end
end
