require "vagrant/machine/thick"
require "vagrant/machine/thin"

module Vagrant
  # This represents a machine that Vagrant manages. This provides a singular
  # API for querying the state and making state changes to the machine, which
  # is backed by any sort of provider (VirtualBox, VMware, etc.).
  class Machine
    autoload :Thick, "vagrant/machine/thick"
    autoload :Thin, "vagrant/machine/thin"

    extend Vagrant::Action::Builtin::MixinSyncedFolders

    ATTR_READERS = [
      :data_dir, :env, :id, :name, :provider, :provider_name,
      :provider_options, :triggers, :ui, :vagrantfile
    ]
    ATTR_ACCESSORS = [
      :box, :config, :provider_config
    ]
    METHODS = [
      :action, :action_raw, :communicate, :guest, :id=, :index_uuid,
      :inspect, :reload, :ssh_info, :state, :recover_machine, :uid
    ]

    ATTR_READERS.each do |attr_name|
      define_method(attr_name) { raise NotImplementedError,
          "`#{self.class.name}##{attr_name}` has not been implemented" }
    end

    ATTR_ACCESSORS.each do |attr_name|
      define_method(attr_name) { raise NotImplementedError,
          "`#{self.class.name}##{attr_name}` has not been implemented" }
      define_method("#{attr_name}=") { |_| raise NotImplementedError,
          "`#{self.class.name}##{attr_name}=` has not been implemented" }
    end

    METHODS.each do |m_name|
      define_method(m_name) { |*_| raise NotImplementedError,
          "`#{self.class.name}##{m_name}` has not been implemented" }
    end

    class << self

      alias_method :real_new, :new

      # Creates a new machine instance based on the mode Vagrant is currently operating
      def new(*args)
        from_subclass = caller.detect do |line|
          line.start_with?(__FILE__)
        end
        if from_subclass
          real_new(*args)
        else
          if Vagrant.server_mode?
            Thin.new(*args)
          else
            Thick.new(*args)
          end
        end
      end
    end

    # Temporarily changes the machine UI. This is useful if you want
    # to execute an {#action} with a different UI.
    def with_ui(ui)
      @ui_mutex.synchronize do
        begin
          old_ui = @ui
          @ui    = ui
          yield
        ensure
          @ui = old_ui
        end
      end
    end

    # This returns the set of shared folders that should be done for
    # this machine. It returns the folders in a hash keyed by the
    # implementation class for the synced folders.
    #
    # @return [Hash<Symbol, Hash<String, Hash>>]
    def synced_folders
      self.class.synced_folders(self)
    end
  end
end
