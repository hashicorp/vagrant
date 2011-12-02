module Vagrant
  class Action
    module VM
      module NFSHelpers
        def clear_nfs_exports(env, output=nil)
          env["host"].nfs_cleanup(output) if env["host"]
        end
      end
    end
  end
end
