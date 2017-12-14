module Vagrant
  module Util
    autoload :Busy,                      'vagrant/util/busy'
    autoload :CommandDeprecation,        'vagrant/util/command_deprecation'
    autoload :Counter,                   'vagrant/util/counter'
    autoload :CredentialScrubber,        'vagrant/util/credential_scrubber'
    autoload :DeepMerge,                 'vagrant/util/deep_merge'
    autoload :Env,                       'vagrant/util/env'
    autoload :HashWithIndifferentAccess, 'vagrant/util/hash_with_indifferent_access'
    autoload :GuestInspection,           'vagrant/util/guest_inspection'
    autoload :LoggingFormatter,          'vagrant/util/logging_formatter'
    autoload :Platform,                  'vagrant/util/platform'
    autoload :Retryable,                 'vagrant/util/retryable'
    autoload :SafeExec,                  'vagrant/util/safe_exec'
    autoload :SilenceWarnings,           'vagrant/util/silence_warnings'
    autoload :StackedProcRunner,         'vagrant/util/stacked_proc_runner'
    autoload :StringBlockEditor,         'vagrant/util/string_block_editor'
    autoload :Subprocess,                'vagrant/util/subprocess'
    autoload :TemplateRenderer,          'vagrant/util/template_renderer'
    autoload :Which,                     'vagrant/util/which'
  end
end
