module VagrantPlugins
  module CommandServe
    module Util
      autoload :Cacher, Vagrant.source_root.join("plugins/commands/serve/util/cacher").to_s
      autoload :ClientSetup, Vagrant.source_root.join("plugins/commands/serve/util/client_setup").to_s
      autoload :Connector, Vagrant.source_root.join("plugins/commands/serve/util/connector").to_s
      autoload :ExceptionLogger, Vagrant.source_root.join("plugins/commands/serve/util/exception_logger").to_s
      autoload :HasBroker, Vagrant.source_root.join("plugins/commands/serve/util/has_broker").to_s
      autoload :HasLogger, Vagrant.source_root.join("plugins/commands/serve/util/has_logger").to_s
      autoload :HasMapper, Vagrant.source_root.join("plugins/commands/serve/util/has_mapper").to_s
      autoload :HasSeeds, Vagrant.source_root.join("plugins/commands/serve/util/has_seeds").to_s
      autoload :ServiceInfo, Vagrant.source_root.join("plugins/commands/serve/util/service_info").to_s

      module WithMapper
        def mapper
          info = Thread.current.thread_variable_get(:service_info)
          if info && info[:mapper]
            return info[:mapper]
          end
          Mappers.new
        end
      end
    end
  end
end
