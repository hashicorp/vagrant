#!/bin/sh
#
# This shell script installs and prepares all the software necessary
# to run the build master. This script is expected to be run as root.
# This script is made to be run only on Ubuntu 10.04 LTS at the moment.

# Update the source list
apt-get update

# Install the basic sysadmin stuff
apt-get install -y htop

# Fix the mountall bug in the AMI
sed -i -e 's/nobootwait,//' /etc/fstab

#----------------------------------------------------------------------
# Python Setup
#----------------------------------------------------------------------
# Install Python and pip
apt-get install -y python python-dev python-setuptools
easy_install pip

# Install virtualenv
pip install virtualenv

#----------------------------------------------------------------------
# Deploy Setup
#----------------------------------------------------------------------
# Install Git, which is used for all the deploys of the build master
apt-get install -y git-core

# Create the user/group for the buildmaster
groupadd buildmaster
useradd -d /home/buildmaster -g buildmaster -s /bin/bash buildmaster
mkdir /home/buildmaster
chown -R buildmaster:buildmaster /home/buildmaster

# Make the folder which will contain the buildmaster code
mkdir -p /srv/buildmaster
chown buildmaster:buildmaster /srv/buildmaster

# Make the folder which will contain the configuration for the
# buildmaster
mkdir -p /etc/buildmaster
chown buildmaster:buildmaster /etc/buildmaster

#----------------------------------------------------------------------
# Nginx Setup
#----------------------------------------------------------------------
# Install Nginx
apt-get install -y nginx

# Setup the basic directories
mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Setup the configuration
cat <<EOF > /etc/nginx/nginx.conf
user             www-data;
worker_processes 1;

# Raise the limit on open file descriptors
worker_rlimit_nofile 30000;

error_log /var/log/nginx/error.log;
pid       /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    include      /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log   /var/log/nginx/access.log;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    keepalive_timeout 65;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# Setup the buildbot site
cat <<EOF > /etc/nginx/sites-available/buildmaster.conf
server {
  listen 80;

  location / {
    proxy_pass http://localhost:8000;
  }
}
EOF

# Activate the buildbot site, remove the default
rm /etc/nginx/sites-enabled/default
ln -f -s /etc/nginx/sites-available/buildmaster.conf /etc/nginx/sites-enabled/buildmaster.conf

# Restart nginx
/etc/init.d/nginx restart