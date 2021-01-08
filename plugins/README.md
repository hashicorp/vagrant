# Vagrant Core Plugins

These are plugins that ship with Vagrant. Vagrant core uses its own
plugin system to power a lot of the core pieces that ship with Vagrant.
Each plugin will have its own README which explains its specific role.

## Generate proto

```
grpc_tools_ruby_protoc -I . --ruby_out=gen/plugin --grpc_out=gen/plugin ./plugin_server.proto
```
