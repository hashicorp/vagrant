require File.expand_path("../base", __FILE__)
require 'i18n/tasks'
require 'i18n/tasks/base_task'
require 'vagrant/util/i18n_scanner'

describe 'translation keys'  do
  let(:i18n) { I18n::Tasks::BaseTask.new }

  it 'are all used' do
    expect(i18n.unused_keys).to have(0).keys
  end

  it 'are all present' do
    expect(i18n.untranslated_keys).to have(0).keys
  end
end
