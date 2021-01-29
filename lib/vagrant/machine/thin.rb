module Vagrant
  class Machine
    class Thin < Machine
      def initialize(name, provider_name, provider_cls, provider_config, provider_options, config, data_dir, box, env, vagrantfile, base=false)
        @client = VagrantPlugins::CommandServe::Client::Machine.new(name: name)
      end
    end
  end
end
