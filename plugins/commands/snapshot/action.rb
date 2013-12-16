# coding: utf-8
module VagrantPlugins
  module CommandSnapshot
    module Action
      autoload :CreateSnapshot, File.expand_path('../action/create_snapshot', __FILE__)
      autoload :DeleteSnapshot, File.expand_path('../action/delete_snapshot', __FILE__)
      autoload :ListSnapshots, File.expand_path('../action/list_snapshots', __FILE__)
      autoload :RestoreSnapshot, File.expand_path('../action/restore_snapshot', __FILE__)
    end
  end
end
