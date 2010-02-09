module Hobo
  class Provisioning
    include Hobo::Util

    def initialize(vm)
      @vm = vm
      @vm.share_folder("hobo-provisioning", File.expand_path(Hobo.config.chef.cookbooks_path, Env.root_path), Hobo.config.chef.provisioning_path)
    end

    def run

    end
  end
end