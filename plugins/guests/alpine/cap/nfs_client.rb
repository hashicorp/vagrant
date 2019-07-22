module VagrantPlugins
    module GuestAlpine
        module Cap
            class NFSClient
                def self.nfs_client_install(machine)
                    machine.communicate.sudo('apk update')
                    machine.communicate.sudo('apk add --upgrade nfs-utils')
                    machine.communicate.sudo('rc-update add rpc.statd')
                    machine.communicate.sudo('rc-service rpc.statd start')
                end
            end
        end
    end
end
