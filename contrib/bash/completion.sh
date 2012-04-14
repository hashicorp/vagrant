# Autocompletion for Vagrant just put this line in your ~/.profile or lik this file into it like:
# source /path/to/vagrant/contrib/bash/completion.sh
complete -W "$(echo `vagrant --help | awk '/box/,/up/ {print $1}'`;)" vagrant