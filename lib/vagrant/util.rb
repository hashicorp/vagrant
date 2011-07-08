module Vagrant
  module Util
    autoload :Busy,                      'vagrant/util/busy'
    autoload :Counter,                   'vagrant/util/counter'
    autoload :GlobLoader,                'vagrant/util/glob_loader'
    autoload :HashWithIndifferentAccess, 'vagrant/util/hash_with_indifferent_access'
    autoload :PlainLogger,               'vagrant/util/plain_logger'
    autoload :Platform,                  'vagrant/util/platform'
    autoload :ResourceLogger,            'vagrant/util/resource_logger'
    autoload :Retryable,                 'vagrant/util/retryable'
    autoload :StackedProcRunner,         'vagrant/util/stacked_proc_runner'
    autoload :TemplateRenderer,          'vagrant/util/template_renderer'
  end
end
