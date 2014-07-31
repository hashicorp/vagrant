require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/winrm/command_filter")

describe VagrantPlugins::CommunicatorWinRM::CommandFilter, unit: true do

  describe '.command_filters' do
    it 'initializes all command filters in command filters directory' do
      expect(subject.command_filters()).not_to be_empty
    end
  end

  describe '.filter' do
    it 'filters out uname commands' do
      expect(subject.filter('uname -s stuff')).to eq('')
    end

    it 'filters out grep commands' do
      expect(subject.filter("grep 'Fedora release [12][67890]' /etc/redhat-release")).to eq("")
    end

    it 'filters out which commands' do
      expect(subject.filter('which ruby')).to include(
        '[Array](Get-Command ruby -errorAction SilentlyContinue)')
    end

    it 'filters out test -d commands' do
      expect(subject.filter('test -d /tmp/dir')).to include(
        "$p = \"/tmp/dir\"")
      expect(subject.filter('test -d /tmp/dir')).to include(
        "if ((Test-Path $p) -and (get-item $p).PSIsContainer) {")
    end

    it 'filters out test -f commands' do
      expect(subject.filter('test -f /tmp/file.txt')).to include(
        "$p = \"/tmp/file.txt\"")
      expect(subject.filter('test -f /tmp/file.txt')).to include(
        "if ((Test-Path $p) -and (!(get-item $p).PSIsContainer)) {")
    end

    it 'filters out test -x commands' do
      expect(subject.filter('test -x /tmp/file.txt')).to include(
        "$p = \"/tmp/file.txt\"")
      expect(subject.filter('test -x /tmp/file.txt')).to include(
        "if ((Test-Path $p) -and (!(get-item $p).PSIsContainer)) {")
    end

    it 'filters out other test commands' do
      expect(subject.filter('test -L /tmp/file.txt')).to include(
        "$p = \"/tmp/file.txt\"")
      expect(subject.filter('test -L /tmp/file.txt')).to include(
        "if (Test-Path $p) {")
    end

    it 'filters out rm recurse commands' do
      expect(subject.filter('rm -Rf /some/dir')).to eq(
        "rm /some/dir -recurse -force")
      expect(subject.filter('rm -fr /some/dir')).to eq(
        "rm /some/dir -recurse -force")
      expect(subject.filter('rm -r /some/dir')).to eq(
        "rm /some/dir -recurse -force")
    end

    it 'filters out rm commands' do
      expect(subject.filter('rm /some/dir')).to eq(
        "rm /some/dir -force")
      expect(subject.filter('rm -f /some/dir')).to eq(
        "rm /some/dir -force")
    end

    it 'filters out mkdir commands' do
      expect(subject.filter('mkdir /some/dir')).to eq(
        "mkdir /some/dir -force")
      expect(subject.filter('mkdir -p /some/dir')).to eq(
        "mkdir /some/dir -force")
    end

    it 'filters out chown commands' do
      expect(subject.filter("chown -R root '/tmp/dir'")).to eq('')
    end

    it 'filters out chmod commands' do
      expect(subject.filter("chmod 0600 ~/.ssh/authorized_keys")).to eq('')
    end

    it 'filters out certain cat commands' do
      expect(subject.filter("cat /etc/release | grep -i OmniOS")).to eq('')
    end

    it 'should not filter out other cat commands' do
      expect(subject.filter("cat /tmp/somefile")).to eq('cat /tmp/somefile')
    end
  end

end
