module Vagrant
  class Config
    class SSHConfig < Base
      configures :ssh

      attr_accessor :username
      attr_accessor :host
      attr_accessor :forwarded_port_key
      attr_accessor :forwarded_port_destination
      attr_accessor :max_tries
      attr_accessor :timeout
      attr_writer :private_key_path
      attr_accessor :forward_agent
      attr_accessor :forward_x11
      attr_accessor :shell
      attr_accessor :port
      attr_accessor :shared_connections
      attr_accessor :master_connection
      attr_reader :control_master
      attr_accessor :control_path
      attr_accessor :connect_timeout
      attr_accessor :keep_alive_interval

      def initialize
        @shell = "bash"
        @port = nil
        @forward_agent = false
        @forward_x11 = false
        @control_master = 'auto'
        @control_path = get_control_path
        @connect_timeout = 60
        @keep_alive_interval = 60
        @shared_connections = true
        #if env
        #  $stdout.puts 'WE NEVER SEE THIS? '*10
        #  @control_master ||= []
        #  @control_master << ::Vagrant::SSH.new(env).execute({:command => "echo 'Vagrant SSH master connection'"})
        #end
        @distribution = nil
      end

      def get_control_path
         @control_path ||= make_control_path
      end

      def make_control_path(cp_dir = '~/.ssh')
        begin
          cmtf = nil
          FileUtils.mkdir_p cp_dir unless Dir.exist? cp_dir
          tf = Tempfile.new('vagrant-ssh-control-master', cp_dir)
          cmtf = tf.path
        rescue

        ensure
          tf.close! if tf
          cm = cmtf.nil? ? '~/.ssh/vagrant-ssh-fall-back-control-master-%r@%h:%p' : cmtf
          return cm
        end
      end

      def private_key_path
        File.expand_path(@private_key_path, env.root_path)
      end

      def validate(errors)
        [:username, :host, :forwarded_port_key, :max_tries, :timeout, :private_key_path].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end

        errors.add(I18n.t("vagrant.config.ssh.private_key_missing", :path => private_key_path)) if !File.file?(private_key_path)
      end
    end
  end
end
