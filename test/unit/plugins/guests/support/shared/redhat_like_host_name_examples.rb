shared_examples 'a partial redhat-like host name change' do
  shared_examples 'shared between newhostname styles' do

    it 'sets dhcp_hostname with the provided short hostname' do
      communicator.expect_command(%q(sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1"newhostname"/' /etc/sysconfig/network-scripts/ifcfg-*))
      described_class.change_host_name(machine, new_hostname)
    end

    it 'restarts networking' do
      communicator.expect_command(%q(service network restart))
      described_class.change_host_name(machine, new_hostname)
    end
  end

  context 'when newhostname is qualified' do
    let(:new_hostname) {'newhostname.newdomain.tld'}

    include_examples 'shared between newhostname styles'

    it 'updates sysconfig with the provided full hostname' do
      communicator.expect_command(%q(sed -i 's/\\(HOSTNAME=\\).*/\\1newhostname.newdomain.tld/' /etc/sysconfig/network))
      described_class.change_host_name(machine, new_hostname)
    end

    it 'updates hostname on the machine with the new hostname' do
      communicator.expect_command(%q(hostname newhostname.newdomain.tld))
      described_class.change_host_name(machine, new_hostname)
    end
  end

  context 'when newhostname is simple' do
    let(:new_hostname) {'newhostname'}

    include_examples 'shared between newhostname styles'

    it 'updates sysconfig with as much hostname as is available' do
      communicator.expect_command(%q(sed -i 's/\\(HOSTNAME=\\).*/\\1newhostname/' /etc/sysconfig/network))
      described_class.change_host_name(machine, new_hostname)
    end

    it 'updates hostname on the machine with the new hostname' do
      communicator.expect_command(%q(hostname newhostname))
      described_class.change_host_name(machine, new_hostname)
    end

  end
end

shared_examples 'a full redhat-like host name change' do
  include_examples 'a partial redhat-like host name change'

  it "does nothing when the provided hostname is not different" do
    described_class.change_host_name(machine, old_hostname)
    expect(communicator.received_commands.to_set).to eq(communicator.expected_commands.keys.to_set)
  end

  it "does more when the provided hostname is a similar version" do
    described_class.change_host_name(machine, similar_hostname)
    expect(communicator.received_commands.to_set).not_to eq(communicator.expected_commands.keys.to_set)
  end
end

shared_examples 'mutating /etc/hosts helpers' do
  let(:sed_command) do
    # Here we run the change_host_name through and extract the recorded sed
    # command from the dummy communicator
    described_class.change_host_name(machine, new_hostname)
    communicator.received_commands.find { |cmd| cmd =~ %r(^sed .* /etc/hosts$) }
  end

  # Now we extract the regexp from that sed command so we can do some
  # verification on it
  let(:expression) { sed_command.sub(%r{^sed -i '\(.*\)' /etc/hosts$}, "\1") }
  let(:search)     { Regexp.new(expression.split('@')[1].gsub(/\\/,'')) }
  let(:replace)    { expression.split('@')[2] }
end

shared_examples 'inserting hostname in /etc/hosts' do
  include_examples 'mutating /etc/hosts helpers'

  context 'when target hostname is qualified' do
    let(:new_hostname) {'newhostname.newdomain.tld'}

    it 'works with a basic file' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname.newdomain.tld newhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end
  end

  context 'when target hostname is simple' do
    let(:new_hostname) {'newhostname'}

    it 'works with a basic file' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end
  end
end

shared_examples 'swapping simple hostname in /etc/hosts' do
  include_examples 'mutating /etc/hosts helpers'

  context 'when target hostname is qualified' do
    let(:new_hostname) {'newhostname.newdomain.tld'}

    it 'works with a basic file' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   oldhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname.newdomain.tld newhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end

    it 'does not touch suffixed hosts' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   oldhostname oldhostname.nope localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname.newdomain.tld newhostname oldhostname.nope localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end
  end

  context 'when target hostname is simple' do
    let(:new_hostname) {'newhostname'}

    it 'works with a basic file' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   oldhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end

    it 'does not touch suffixed hosts' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   oldhostname oldhostname.nope localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname oldhostname.nope localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end
  end
end

shared_examples 'swapping qualified hostname in /etc/hosts' do
  include_examples 'mutating /etc/hosts helpers'

  context 'when target hostname is qualified' do
    let(:new_hostname) {'newhostname.newdomain.tld'}

    it 'works with a basic file' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   oldhostname.olddomain.tld oldhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname.newdomain.tld newhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end

    it 'does not touch suffixed hosts' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   oldhostname.olddomain.tld oldhostname oldhostname.nope localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname.newdomain.tld newhostname oldhostname.nope localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end
  end

  context 'when target hostname is simple' do
    let(:new_hostname) {'newhostname'}

    it 'works with a basic file' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   oldhostname.olddomain.tld oldhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end

    it 'does not touch suffixed hosts' do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1   oldhostname.olddomain.tld oldhostname oldhostname.nope localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1   newhostname oldhostname.nope localhost.localdomain localhost
        ::1     localhost6.localdomain6 localhost6
      RESULT
    end
  end
end
