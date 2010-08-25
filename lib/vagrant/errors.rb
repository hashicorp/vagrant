module Vagrant
  class VagrantError < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end

  class CLIMissingEnvironment < VagrantError; status_code(1); end
  class BoxNotFound < VagrantError; status_code(2); end
  class NoEnvironmentError < VagrantError; status_code(3); end
  class VMNotFoundError < VagrantError; status_code(4); end
  class MultiVMEnvironmentRequired < VagrantError; status_code(5); end
  class VMNotCreatedError < VagrantError; status_code(6); end
  class MultiVMTargetRequired < VagrantError; status_code(7); end
end
