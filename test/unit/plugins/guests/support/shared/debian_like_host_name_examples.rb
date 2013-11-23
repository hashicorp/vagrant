shared_examples "a debian-like host name change" do
  it "updates /etc/hostname on the machine" do
    communicator.expect_command(%q(echo 'newhostname' > /etc/hostname))
    described_class.change_host_name(machine, 'newhostname.newdomain.tld')
  end

  it "flips out the old hostname in /etc/hosts" do
    sed_find = '^(([0-9]{1,3}\.){3}[0-9]{1,3})\s+oldhostname.olddomain.tld\b.*$'
    sed_replace = '\1\tnewhostname.newdomain.tld newhostname'
    communicator.expect_command(
      %Q(sed -ri 's@#{sed_find}@#{sed_replace}@g' /etc/hosts)
    )
    described_class.change_host_name(machine, 'newhostname.newdomain.tld')
  end

  it "updates mailname to prevent problems with the default mailer" do
    communicator.expect_command(%q(hostname --fqdn > /etc/mailname))
    described_class.change_host_name(machine, 'newhostname.newdomain.tld')
  end

  it "does nothing when the provided hostname is not different" do
    described_class.change_host_name(machine, 'oldhostname.olddomain.tld')
    communicator.received_commands.should == ['hostname -f']
  end
end
