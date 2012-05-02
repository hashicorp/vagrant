# Autocompletion for Vagrant just put this line in your ~/.profile or link this file into it like:
# source /path/to/vagrant/contrib/bash/completion.sh
complete -W "$(echo `vagrant --help | awk '/^     /{print $1}'`;)" vagrant
