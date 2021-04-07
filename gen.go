package main

// NOTE: This file is here as a nicety for being able to run `go generate` at
//       the root of the repository and have all the required protos generated
//       and installed in the correct locations

// Builds the Vagrant server Go GRPC
//go:generate sh -c "protoc -I`go list -m -f \"{{.Dir}}\" github.com/mitchellh/protostructure` -I`go list -m -f \"{{.Dir}}\" github.com/hashicorp/vagrant-plugin-sdk`/proto/vagrant_plugin_sdk -I./vendor/proto/api-common-protos -I./internal/server --go-grpc_out=./internal/server/proto/vagrant_server --go-grpc_opt=module=github.com/hashicorp/vagrant/internal/server/proto/vagrant_server --go_out=./internal/server/proto/vagrant_server --go_opt=module=github.com/hashicorp/vagrant/internal/server/proto/vagrant_server internal/server/proto/vagrant_server/*.proto"

// Builds the Ruby Vagrant Go GRPC for legacy Vagrant interactions
//go:generate sh -c "protoc -I./vendor/proto/api-common-protos -I./internal/server --go-grpc_out=./internal/server/proto/ruby_vagrant --go-grpc_opt=module=github.com/hashicorp/vagrant/internal/server/proto/ruby_vagrant --go_out=./internal/server/proto/ruby_vagrant --go_opt=module=github.com/hashicorp/vagrant/internal/server/proto/ruby_vagrant internal/server/proto/ruby_vagrant/*.proto"

// Builds the Ruby GRPC for the Vagrant server and Ruby Vagrant interactions
//go:generate sh -c "grpc_tools_ruby_protoc -I`go list -m -f \"{{.Dir}}\" github.com/mitchellh/protostructure` -I`go list -m -f \"{{.Dir}}\" github.com/hashicorp/vagrant-plugin-sdk`/proto/vagrant_plugin_sdk -I./vendor/proto/api-common-protos -I./internal/server --grpc_out=./lib/vagrant/protobufs/ --ruby_out=./lib/vagrant/protobufs/ internal/server/proto/vagrant_server/*.proto internal/server/proto/ruby_vagrant/*.proto"

// Builds the Ruby GRPC for the Vagrant Plugin SDK
//go:generate sh -c "grpc_tools_ruby_protoc -I`go list -m -f \"{{.Dir}}\" github.com/hashicorp/vagrant-plugin-sdk`/proto -I`go list -m -f \"{{.Dir}}\" github.com/mitchellh/protostructure` -I`go list -m -f \"{{.Dir}}\" github.com/hashicorp/vagrant-plugin-sdk`/3rdparty/proto/api-common-protos --grpc_out=./lib/vagrant/protobufs/proto/ --ruby_out=./lib/vagrant/protobufs/proto/ vagrant_plugin_sdk/plugin.proto protostructure.proto"
