module Hobo
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'bin', 'hobo-ssh-expect.sh')

    class << self
      def connect(opts={})
        Kernel.exec "#{SCRIPT} #{opts[:uname] || uname_default} #{opts[:pass] || pass_default} #{opts[:host] || host_default}".strip
      end

      private
      def port_default
        Hobo.config[:ssh][:port]
      end
      
      def host_default
        Hobo.config[:ssh][:host]
      end

      def pass_default
        Hobo.config[:ssh][:pass]
      end

      def uname_default
        Hobo.config[:ssh][:uname]
      end
    end
  end
end
