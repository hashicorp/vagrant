# Autocompletion for Vagrant just put this line in your ~/.profile or link this file into it like:
# source /path/to/vagrant/contrib/bash/completion.sh
_vagrant() {

    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    preprev="${COMP_WORDS[COMP_CWORD-2]}"

    commands=$(vagrant --help | awk '/^     /{print $1}')

    if [ $COMP_CWORD == 1 ] ; then
      COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
      return 0
    fi

    if [ $COMP_CWORD == 2 ] ; then
        local sub_commands=$(vagrant $prev --help | awk '/^     /{print $1}')
        COMPREPLY=( $(compgen -W "${sub_commands}" -- ${cur}) )
        return 0
    fi

    if [[ ${cur} == -* ]] ; then
        local command_opts=$(vagrant $preprev $prev --help | grep -E -o "((-\w{1}|--(\w|-)*=?)){1,2}")
        COMPREPLY=( $(compgen -W "${command_opts}" -- ${cur}) )
        return 0
    fi
}

complete -F _vagrant vagrant

# /* vim: set filetype=sh : */
