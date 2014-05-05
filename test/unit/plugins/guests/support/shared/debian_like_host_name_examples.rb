shared_examples "a debian-like host name change" do
  it "updates /etc/hostname on the machine" do
    communicator.expect_command(%q(echo 'newhostname' > /etc/hostname))
    described_class.change_host_name(machine, 'newhostname.newdomain.tld')
  end

  it "updates mailname to prevent problems with the default mailer" do
    communicator.expect_command(%q(hostname --fqdn > /etc/mailname))
    described_class.change_host_name(machine, 'newhostname.newdomain.tld')
  end

  it "does nothing when the provided hostname is not different" do
    described_class.change_host_name(machine, 'oldhostname.olddomain.tld')
    expect(communicator.received_commands).to eq(['hostname -f'])
  end

  describe "flipping out the old hostname in /etc/hosts" do
    let(:sed_command) do
      # Here we run the change_host_name through and extract the recorded sed
      # command from the dummy communicator
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
      communicator.received_commands.find { |cmd| cmd =~ /^sed/ }
    end

    # Now we extract the regexp from that sed command so we can do some
    # verification on it
    let(:expression) { sed_command.sub(%r{^sed -ri '\(.*\)' /etc/hosts$}, "\1") }
    let(:search)     { Regexp.new(expression.split('@')[1], Regexp::EXTENDED) }
    let(:replace)    { expression.split('@')[2] }

    let(:grep_command) { "grep '#{old_hostname}' /etc/hosts" }

    before do
      communicator.stub_command(grep_command, exit_code: 0)
    end

    it "works on an simple /etc/hosts file" do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1 localhost
        127.0.1.1 oldhostname.olddomain.tld oldhostname
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1 localhost
        127.0.1.1 newhostname.newdomain.tld newhostname
      RESULT
    end

    it "does not modify lines which contain similar hostnames" do
      original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
        127.0.0.1 localhost
        127.0.1.1 oldhostname.olddomain.tld oldhostname

        # common prefix, but different fqdn
        192.168.12.34 oldhostname.olddomain.tld.different

        # different characters at the dot
        192.168.34.56 oldhostname-olddomain.tld
      ETC_HOSTS

      modified_etc_hosts = original_etc_hosts.gsub(search, replace)

      expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
        127.0.0.1 localhost
        127.0.1.1 newhostname.newdomain.tld newhostname

        # common prefix, but different fqdn
        192.168.12.34 oldhostname.olddomain.tld.different

        # different characters at the dot
        192.168.34.56 oldhostname-olddomain.tld
      RESULT
    end

    it "appends 127.0.1.1 if it isn't there" do
      communicator.stub_command(grep_command, exit_code: 1)
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')

      sed = communicator.received_commands.find { |cmd| cmd =~ /^sed/ }
      expect(sed).to be_nil

      echo = communicator.received_commands.find { |cmd| cmd =~ /^echo/ }
      expect(echo).to_not be_nil
    end

    context "when the old fqdn has a trailing dot" do
      let(:old_hostname) { 'oldhostname.withtrailing.dot.' }

      it "modifies /etc/hosts properly" do
        original_etc_hosts = <<-ETC_HOSTS.gsub(/^ */, '')
          127.0.0.1 localhost
          127.0.1.1 oldhostname.withtrailing.dot. oldhostname
        ETC_HOSTS

        modified_etc_hosts = original_etc_hosts.gsub(search, replace)

        expect(modified_etc_hosts).to eq <<-RESULT.gsub(/^ */, '')
          127.0.0.1 localhost
          127.0.1.1 newhostname.newdomain.tld newhostname
        RESULT
      end
    end
  end
end
