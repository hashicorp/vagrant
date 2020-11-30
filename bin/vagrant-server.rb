#!/Users/sophia/miniconda3/envs/vagrant/bin/ruby

require_relative '../proto/gen/ruby-server_pb'
require_relative '../proto/gen/ruby-server_services_pb'

require 'grpc'
require 'grpc/health/checker'
require 'grpc/health/v1/health_services_pb'

class PluginService < Hashicorp::Vagrant::RubyVagrant::Service
  def get_plugins(req, _unused_call)
    
    plugins = [Hashicorp::Vagrant::Plugin.new(name: "test")]
    Hashicorp::Vagrant::GetPluginsResponse.new(
      plugins: plugins
    )
  end
end

def main
  s = GRPC::RpcServer.new
  # Listen on port 24000 on all interfaces. Update for production use.
  s.add_http2_port('[::]:10001', :this_port_is_insecure)

  s.handle(PluginService.new)

  health_checker = Grpc::Health::Checker.new
  health_checker.add_status(
    "Hashicorp::Vagrant::RubyVagrant::Service::PluginService",
    Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)
  s.handle(health_checker)

  STDOUT.puts "1|1|tcp|127.0.0.1:10001|grpc"
  STDOUT.flush
  s.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT', 'SIGINT'])
end

main()
