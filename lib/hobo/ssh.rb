module Hobo
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'script', 'hobo-ssh-expect.sh')

    class <<self
      def connect(opts={})
        options = {}
        [:port, :host, :pass, :uname].each do |param|
          options[param] = opts[param] || Hobo.config[:ssh][param]
        end

        Kernel.exec "#{SCRIPT} #{options[:uname]} #{options[:pass]} #{options[:host]} #{options[:port]}".strip
      end

      def execute
        Net::SSH.start("localhost", Hobo.config[:ssh][:uname], :port => Hobo.config[:ssh][:port], :password => Hobo.config[:ssh][:pass]) do |ssh|
          yield ssh
        end
      end
    end
  end
end
