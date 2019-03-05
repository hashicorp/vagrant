---
layout: "docs"
page_title: "Networking - Docker Provider"
sidebar_current: "providers-docker-networking"
description: |-
  The Vagrant Docker provider supports using the private network using the
  `docker network` commands.
---

# Networking

Vagrant uses the `docker network` command under the hood to create and manage
networks for containers. Vagrant will do its best to create and manage networks
for any containers configured inside the Vagrantfile. Each docker network is grouped
by the subnet used for a requested ip address.

For each newly unique network, Vagrant will run the `docker network create` subcommand
with the provided options from the network config inside your Vagrantfile. If multiple
networks share the same subnet, it will reuse that existing network. Once these
networks have been created, Vagrant will attach these networks to the requested
containers using the `docker network connect` for each network.

Most of the options given to `:private_network` align with the command line flags
for the [docker network create](https://docs.docker.com/engine/reference/commandline/network_create/)
command. However, if you want the container to have a specific IP instead of using
DHCP, you also will have to specify a subnet due to how docker networks behave.

It should also be noted that if you want a specific IPv6 address, your `:private_network`
option should use `ip6` rather than `ip`. If you just want to use DHCP, you can
simply say `type: "dhcp"` insetad. More examples are shared below which demonstrate
creating a few common network interfaces.

When destroying containers through Vagrant, Vagrant will clean up the network if
there are no more containers using the network.

## Docker Network Example

The following Vagrantfile will generate these networks for a container:

1. A IPv4 IP address assigned by DHCP
2. A IPv4 IP address 172.20.128.2 on a network with subnet 172.20.0.0/16
3. A IPv6 IP address assigned by DHCP on subnet 2a02:6b8:b010:9020:1::/80

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "docker"  do |docker|
    docker.vm.network :private_network, type: "dhcp"
    docker.vm.network :private_network,
        ip: "172.20.128.2", subnet: "172.20.0.0/16"
    docker.vm.network :private_network, type: "dhcp", ipv6: "true", subnet: "2a02:6b8:b010:9020:1::/80"
    docker.vm.provider "docker" do |d|
      d.build_dir = "docker_build_dir"
    end
  end
end
```

You can test that your container has the proper configured networks by looking
at the result of running `ip addr`, for example:

```
brian@localghost:vagrant-sandbox % docker ps                                                             ±[●][master]
CONTAINER ID        IMAGE                                  COMMAND                  CREATED             STATUS              PORTS                                              NAMES
370f4e5d2217        196a06ef12f5                           "tail -f /dev/null"      5 seconds ago       Up 3 seconds        80/tcp, 443/tcp                                    vagrant-sandbox_docker-1_1551810440
brian@localghost:vagrant-sandbox % docker exec 370f4e5d2217 ip addr                                      ±[●][master]
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
24: eth0@if25: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:11:00:03 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.3/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
27: eth1@if28: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:13:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.19.0.2/16 brd 172.19.255.255 scope global eth1
       valid_lft forever preferred_lft forever
30: eth2@if31: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:14:80:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.20.128.2/16 brd 172.20.255.255 scope global eth2
       valid_lft forever preferred_lft forever
33: eth3@if34: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:15:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.21.0.2/16 brd 172.21.255.255 scope global eth3
       valid_lft forever preferred_lft forever
    inet6 2a02:6b8:b010:9020:1::2/80 scope global nodad
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe15:2/64 scope link
       valid_lft forever preferred_lft forever
```

## Useful Debugging Tips

If you provide Vagrant with a faulty config option when setting up a network, Vagrant
will pass that option along to the `docker network` commands it uses. That command
line tool should give you some insight if there is something wrong with the option
you configured:

```ruby
docker.vm.network :private_network,
  ip: "172.20.128.2", subnet: "172.20.0.0/16",
  unsupported: "option"
```

```
A Docker command executed by Vagrant didn't complete successfully!
The command run along with the output from the command is shown
below.

Command: ["docker", "network", "create", "vagrant_network_172.20.0.0/16", "--subnet=172.20.0.0/16", "--unsupported=option", {:notify=>[:stdout, :stderr]}]

Stderr: unknown flag: --unsupported
See 'docker network create --help'.


Stdout:
```

The `docker network` command provides some helpful insights to what might be going
on with the networks Vagrant creates. For example, if you want to know what networks
you currently have running on your machine, you can run the `docker network ls` command:

```
brian@localghost:vagrant-sandbox % docker network ls                                                     ±[●][master]
NETWORK ID          NAME                                        DRIVER              SCOPE
a2bfc26bd876        bridge                                      bridge              local
2a2845e77550        host                                        host                local
f36682aeba68        none                                        null                local
00d4986c7dc2        vagrant_network                             bridge              local
d02420ff4c39        vagrant_network_2a02:6b8:b010:9020:1::/80   bridge              local
799ae9dbaf98        vagrant_network_172.20.0.0/16               bridge              local
```

You can also inspect any network for more information:

```
brian@localghost:vagrant-sandbox % docker network inspect vagrant_network                                ±[●][master]
[
    {
        "Name": "vagrant_network",
        "Id": "00d4986c7dc2ed7bf1961989ae1cfe98504c711f9de2f547e5dfffe2bb819fc2",
        "Created": "2019-03-05T10:27:21.558824922-08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.19.0.0/16",
                    "Gateway": "172.19.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "370f4e5d2217e698b16376583fbf051dd34018e5fd18958b604017def92fea63": {
                "Name": "vagrant-sandbox_docker-1_1551810440",
                "EndpointID": "166b7ca8960a9f20a150bb75a68d07e27e674781ed9f916e9aa58c8bc2539a61",
                "MacAddress": "02:42:ac:13:00:02",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

## Caveats

For now, Vagrant only looks at the subnet when figuring out if it should create
a new network for a guest container. If you bring up a container with a network,
and then change or add some new options (but leave the subnet the same), it will
not apply those changes or create a new network.

Because the `--link` flag for the `docker network connect` command is considered
legacy, Vagrant does not support that option when creating containers and connecting
networks.

## More Information

For more information on how docker manages its networks, please refer to their
documentation:

- https://docs.docker.com/network/
- https://docs.docker.com/engine/reference/commandline/network/
