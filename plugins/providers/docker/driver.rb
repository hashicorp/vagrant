require "json"

require "log4r"

module VagrantPlugins
  module DockerProvider
    class Driver
      # The executor is responsible for actually executing Docker commands.
      # This is set by the provider, but defaults to local execution.
      attr_accessor :executor

      def initialize
        @logger   = Log4r::Logger.new("vagrant::docker::driver")
        @executor = Executor::Local.new
      end

      def create(params)
        image   = params.fetch(:image)
        ports   = Array(params[:ports])
        volumes = Array(params[:volumes])
        name    = params.fetch(:name)
        cmd     = Array(params.fetch(:cmd))

        run_cmd = %W(docker run --name #{name} -d)
        run_cmd += ports.map { |p| ['-p', p.to_s] }
        run_cmd += volumes.map { |v| ['-v', v.to_s] }
        run_cmd += %W(--privileged) if params[:privileged]
        run_cmd += %W(-h #{params[:hostname]}) if params[:hostname]
        run_cmd += params[:extra_args] if params[:extra_args]
        run_cmd += [image, cmd]

        execute(*run_cmd.flatten).chomp
      end

      def state(cid)
        case
        when running?(cid)
          :running
        when created?(cid)
          :stopped
        else
          :not_created
        end
      end

      def created?(cid)
        result = execute('docker', 'ps', '-a', '-q', '--no-trunc').to_s
        result =~ /^#{Regexp.escape cid}$/
      end

      def running?(cid)
        result = execute('docker', 'ps', '-q', '--no-trunc')
        result =~ /^#{Regexp.escape cid}$/m
      end

      def privileged?(cid)
        inspect_container(cid)['HostConfig']['Privileged']
      end

      def start(cid)
        unless running?(cid)
          execute('docker', 'start', cid)
          # This resets the cached information we have around, allowing `vagrant reload`s
          # to work properly
          # TODO: Add spec to verify this behavior
          @data = nil
        end
      end

      def stop(cid)
        if running?(cid)
          execute('docker', 'stop', '-t', '1', cid)
        end
      end

      def rm(cid)
        if created?(cid)
          execute('docker', 'rm', '-v', cid)
        end
      end

      def inspect_container(cid)
        # DISCUSS: Is there a chance that this json will change after the container
        #          has been brought up?
        @data ||= JSON.parse(execute('docker', 'inspect', cid)).first
      end

      def all_containers
        execute('docker', 'ps', '-a', '-q', '--no-trunc').to_s.split
      end

      def docker_bridge_ip
        output = execute('/sbin/ip', '-4', 'addr', 'show', 'scope', 'global', 'docker0')
        if output =~ /^\s+inet ([0-9.]+)\/[0-9]+\s+/
          return $1.to_s
        else
          # TODO: Raise an user friendly message
          raise 'Unable to fetch docker bridge IP!'
        end
      end

      private

      def execute(*cmd, &block)
        @executor.execute(*cmd, &block)
      end
    end
  end
end
