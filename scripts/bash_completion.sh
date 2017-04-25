#!/usr/bin/env bash

# bash completion for Vagrant

HELP='-h --help'

FLAGS='${HELP} -v --version'

__vagrant_generate_completion()
{
  typeset current_word
  current_word="${COMP_WORDS[COMP_CWORD]}"

  COMPREPLY=( $(compgen -W "$1" -- "${current_word}") )
  return 0
}

__vagrant_command ()
{
  typeset current_word
  current_word="${COMP_WORDS[COMP_CWORD]}"

  case "${current_word}" in
  -*) __vagrant_flags ;;
  *)  __vagrant_subcommands ;;
  esac
}
__vagrant_subcommands ()
{
  SUBCOMMANDS='\
    box destroy gem halt init\
    init package provision reload\
    resume ssh ssh-config status\
    suspend up'

    __vagrant_generate_completion "$SUBCOMMANDS $FLAGS"
}

__vagrant_flags ()
{
  __vagrant_generate_completion "$FLAGS"
}

__vagrant_box_list ()
{
  echo "`vagrant box list`"
}

__vagrant_box ()
{
  COMMANDS='add list remove repackage'

  __vagrant_generate_completion "$COMMANDS $HELP"
}

__vagrant_init ()
{
  __vagrant_generate_completion "$(__vagrant_box_list) $HELP"
}

__vagrant_up ()
{
  OPTIONS='--no-provision --provision --provision-with'

  __vagrant_generate_completion "$OPTIONS $HELP"
}

__vagrant_ssh ()
{
  OPTIONS='-c --command -p --plain'
  
  __vagrant_generate_completion "$OPTIONS $HELP"
}

__vagrant_destroy ()
{
  OPTIONS='-f --force'
  
  __vagrant_generate_completion "$OPTIONS $HELP"
}

__vagrant_halt ()
{
  OPTIONS='-f --force'
  
  __vagrant_generate_completion "$OPTIONS $HELP"
}

__vagrant_package ()
{
  OPTIONS='--base --output --include --vagrantfile'

  __vagrant_generate_completion "$OPTIONS $HELP"
}

__vagrant_reload ()
{
  OPTIONS='--no-provision --provision --provision-with'

  __vagrant_generate_completion "$OPTIONS $HELP"
}

__vagrant_ssh_config ()
{
  OPTIONS='--host'

  __vagrant_generate_completion "$OPTIONS $HELP"
}

__vagrant ()
{
  typeset previous_word
  previous_word="${COMP_WORDS[COMP_CWORD-1]}"

   case "${previous_word}" in
    box)   __vagrant_box ;;
    destroy) __vagrant_destroy ;;
    halt)    __vagrant_halt ;;
    init)  __vagrant_init ;;
    package) __vagrant_package ;;
    reload) __vagrant_reload ;;
    ssh)   __vagrant_ssh ;;
    ssh-config) __vagrant_ssh_config ;;
    up)    __vagrant_up ;;
    *)  __vagrant_command ;;
   esac

   return 0
}

complete -o default -o nospace -F __vagrant vagrant
