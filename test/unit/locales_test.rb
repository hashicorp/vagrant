require File.expand_path("../base", __FILE__)
require 'i18n/tasks'
require 'i18n/tasks/base_task'

describe 'translation keys'  do
  let(:i18n) { I18n::Tasks::BaseTask.new }

  it 'are all used' do
    expect(i18n.unused_keys).to be_empty
  end

  it 'are all present' do
    expect(i18n.untranslated_keys).to be_empty
  end
end
