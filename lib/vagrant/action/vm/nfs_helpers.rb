module Vagrant
  module Action
    module VM
      module NFSHelpers
        def clear_nfs_exports(env)
          env[:host].nfs_cleanup(env[:vm].uuid) if env[:host]
        end
      end
    end
  end
end
