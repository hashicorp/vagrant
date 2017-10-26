#!/bin/sh -

# We just download the bootstrap script by default and execute that.
if [ -x /usr/bin/fetch ]; then
    /usr/bin/fetch -o bootstrap-salt.sh https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh
elif [ -x /usr/bin/curl ]; then
    /usr/bin/curl -L -O https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh
elif [ -x /usr/bin/wget ]; then
    /usr/bin/wget -O bootstrap-salt.sh https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh
else
    python -c 'import urllib; urllib.urlretrieve("https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh", "bootstrap-salt.sh")'
fi

if [ -e bootstrap-salt.sh ]; then
  sh bootstrap-salt.sh "$@"
else
  exit 1
fi
