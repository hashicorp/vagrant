module Vagrant
  module Util
    autoload :Busy,                      'vagrant/util/busy'
    autoload :Counter,                   'vagrant/util/counter'
    autoload :HashWithIndifferentAccess, 'vagrant/util/hash_with_indifferent_access'
    autoload :Platform,                  'vagrant/util/platform'
    autoload :Retryable,                 'vagrant/util/retryable'
    autoload :SafeExec,                  'vagrant/util/safe_exec'
    autoload :StackedProcRunner,         'vagrant/util/stacked_proc_runner'
    autoload :TemplateRenderer,          'vagrant/util/template_renderer'
  end
end
