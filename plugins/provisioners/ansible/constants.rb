
module VagrantPlugins
  module Ansible
    COMPATIBILITY_MODE_AUTO     = "auto".freeze
    COMPATIBILITY_MODE_V1_8     = "1.8".freeze
    COMPATIBILITY_MODE_V2_0     = "2.0".freeze
    SAFE_COMPATIBILITY_MODE     = COMPATIBILITY_MODE_V1_8
    COMPATIBILITY_MODES         = [
      COMPATIBILITY_MODE_AUTO,
      COMPATIBILITY_MODE_V1_8,
      COMPATIBILITY_MODE_V2_0,
    ].freeze
  end
end