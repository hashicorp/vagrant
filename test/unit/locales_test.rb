require 'i18n/tasks'
require 'i18n/tasks/base_task'

describe 'translation keys'  do
  let(:i18n) { I18n::Tasks::BaseTask.new }

  it 'are all used' do
    i18n.unused_keys.should have(0).keys
  end

  it 'are all present' do
    i18n.untranslated_keys.should have(0).keys
  end
end
