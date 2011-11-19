#!/bin/sh
#
# This shell script deploys the buildmaster by downloading an
# up-to-date tar.gz from GitHub and setting up the proper environment.

#----------------------------------------------------------------------
# Update the source
#----------------------------------------------------------------------
# Download the Vagrant source, extract it
cd /tmp
rm -rf vagrant
rm -rf mitchellh-vagrant-*
wget https://github.com/mitchellh/vagrant/tarball/master -O vagrant.tar.gz
tar xvzf vagrant.tar.gz
mv mitchellh-vagrant-* vagrant

# Move the code into place
cp -R vagrant/test/buildbot/* /srv/buildmaster/

# Setup the virtualenv
cd /srv/buildmaster
virtualenv --no-site-packages env

# Activate the environment
. env/bin/activate

# Install dependencies
pip install -r requirements.txt

#----------------------------------------------------------------------
# Update the buildmaster
#----------------------------------------------------------------------
# Setup environmental variables that are required
export BUILDBOT_CONFIG=/etc/buildmaster/master.cfg
export PYTHONPATH=/srv/buildmaster

# Restart the buildmaster
buildbot restart master/
