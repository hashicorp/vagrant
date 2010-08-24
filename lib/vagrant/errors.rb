module Vagrant
  class VagrantError < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end

  class CLIMissingEnvironment < VagrantError; status_code(1); end
  class BoxNotFound < VagrantError; status_code(2); end
end
