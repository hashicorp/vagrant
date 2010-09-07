module VagrantTestHelpers
  module Objects
    # Returns a blank app (callable) and action environment with the
    # given vagrant environment.
    def action_env(v_env = nil)
      v_env ||= vagrant_env
      app = lambda { |env| }
      env = Vagrant::Action::Environment.new(v_env)
      env["vagrant.test"] = true
      [app, env]
    end
  end
end
