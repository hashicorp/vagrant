module Hobo
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'bin', 'hobo-ssh-expect.sh')
    
    def self.connect(opts={})
      Kernel.exec "#{SCRIPT} #{uname(opts)} #{pass(opts)} #{host(opts)} #{port(opts)}".strip
    end

    private 
    module ClassMethods
      private
      [:port, :host, :pass, :uname].each do |method|
        define_method(method) do |opts|
          opts[method] || Hobo.config[:ssh][method]
        end
      end
    end

    extend ClassMethods
  end
end
