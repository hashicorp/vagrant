module Hobo
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'script', 'hobo-ssh-expect.sh')

    def self.connect(opts={})
      options = {}
      [:port, :host, :pass, :uname].each do |param|
        options[param] = opts[param] || Hobo.config[:ssh][param]
      end

      Kernel.exec "#{SCRIPT} #{options[:uname]} #{options[:pass]} #{options[:host]} #{options[:port]}".strip
    end
  end
end
