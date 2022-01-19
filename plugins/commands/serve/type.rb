module VagrantPlugins
  module CommandServe
    class Type
      autoload :Boolean, Vagrant.source_root.join("plugins/commands/serve/type/boolean").to_s
      autoload :CommandArguments, Vagrant.source_root.join("plugins/commands/serve/type/command_arguments").to_s
      autoload :Direct, Vagrant.source_root.join("plugins/commands/serve/type/direct").to_s

      attr_accessor :value

      def initialize(value: nil)
        @value = value
      end
    end
  end
end
