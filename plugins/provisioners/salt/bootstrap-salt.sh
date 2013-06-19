#!/bin/sh -
#===============================================================================
# vim: softtabstop=4 shiftwidth=4 expandtab fenc=utf-8 spell spelllang=en
#===============================================================================
#
#          FILE: bootstrap-salt.sh
#
#   DESCRIPTION: Bootstrap salt installation for various systems/distributions
#
#          BUGS: https://github.com/saltstack/salty-vagrant/issues
#        AUTHOR: Pedro Algarvio (s0undt3ch), pedro@algarvio.me
#                Alec Koumjian (akoumjian), akoumjian@gmail.com
#                Geoff Garside (geoffgarside), geoff@geoffgarside.co.uk
#       LICENSE: Apache 2.0
#  ORGANIZATION: Salt Stack (saltstack.org)
#       CREATED: 10/15/2012 09:49:37 PM WEST
#===============================================================================
set -o nounset                              # Treat unset variables as an error
ScriptVersion="1.5.5"
ScriptName="bootstrap-salt.sh"

#===============================================================================
#  Environment variables taken into account.
#-------------------------------------------------------------------------------
#   * BS_COLORS:          If 0 disables colour support
#   * BS_PIP_ALLOWED:     If 1 enable pip based installations(if needed)
#   * BS_ECHO_DEBUG:      If 1 enable debug echo which can also be set by -D
#   * BS_SALT_ETC_DIR:    Defaults to /etc/salt
#   * BS_FORCE_OVERWRITE: Force overriding copied files(config, init.d, etc)
#===============================================================================


#===============================================================================
#  LET THE BLACK MAGIC BEGIN!!!!
#===============================================================================


# Bootstrap script truth values
BS_TRUE=1
BS_FALSE=0

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __detect_color_support
#   DESCRIPTION:  Try to detect color support.
#-------------------------------------------------------------------------------
COLORS=${BS_COLORS:-$(tput colors 2>/dev/null || echo 0)}
__detect_color_support() {
    if [ $? -eq 0 ] && [ "$COLORS" -gt 2 ]; then
        RC="\033[1;31m"
        GC="\033[1;32m"
        BC="\033[1;34m"
        YC="\033[1;33m"
        EC="\033[0m"
    else
        RC=""
        GC=""
        BC=""
        YC=""
        EC=""
    fi
}
__detect_color_support


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  echoerr
#   DESCRIPTION:  Echo errors to stderr.
#-------------------------------------------------------------------------------
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  echoinfo
#   DESCRIPTION:  Echo information to stdout.
#-------------------------------------------------------------------------------
echoinfo() {
    printf "${GC} *  INFO${EC}: %s\n" "$@";
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  echowarn
#   DESCRIPTION:  Echo warning informations to stdout.
#-------------------------------------------------------------------------------
echowarn() {
    printf "${YC} *  WARN${EC}: %s\n" "$@";
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  echodebug
#   DESCRIPTION:  Echo debug information to stdout.
#-------------------------------------------------------------------------------
echodebug() {
    if [ $ECHO_DEBUG -eq $BS_TRUE ]; then
        printf "${BC} * DEBUG${EC}: %s\n" "$@";
    fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_pip_allowed
#   DESCRIPTION:  Simple function to let the users know that -P needs to be
#                 used.
#-------------------------------------------------------------------------------
check_pip_allowed() {
    if [ $PIP_ALLOWED -eq $BS_FALSE ]; then
        echoerror "pip based installations were not allowed. Retry using '-P'"
        usage
        exit 1
    fi
}

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
usage() {
    cat << EOT

  Usage :  ${ScriptName} [options] <install-type> <install-type-args>

  Installation types:
    - stable (default)
    - daily  (ubuntu specific)
    - git

  Examples:
    $ ${ScriptName}
    $ ${ScriptName} stable
    $ ${ScriptName} daily
    $ ${ScriptName} git
    $ ${ScriptName} git develop
    $ ${ScriptName} git 8c3fadf15ec183e5ce8c63739850d543617e4357

  Options:
  -h  Display this message
  -v  Display script version
  -n  No colours.
  -D  Show debug output.
  -c  Temporary configuration directory
  -k  Temporary directory holding the minion keys which will pre-seed
      the master.
  -M  Also install salt-master
  -S  Also install salt-syndic
  -N  Do not install salt-minion
  -C  Only run the configuration function. This option automaticaly
      bypasses any installation.
  -P  Allow pip based installations. On some distributions the required salt
      packages or its dependencies are not available as a package for that
      distribution. Using this flag allows the script to use pip as a last
      resort method. NOTE: This works for functions which actually implement
      pip based installations.
  -F  Allow copied files to overwrite existing(config, init.d, etc)

EOT
}   # ----------  end of function usage  ----------

#===  FUNCTION  ================================================================
#         NAME:  __fetch_url
#  DESCRIPTION:  Retrieves a URL and writes it to a given path
#===============================================================================
__fetch_url() {
    curl --insecure -s -o "$1" "$2" >/dev/null 2>&1 ||
        wget --no-check-certificate -q -O "$1" "$2" >/dev/null 2>&1 ||
            fetch -q -o "$1" "$2" >/dev/null 2>&1
}

#===  FUNCTION  ================================================================
#         NAME:  __check_config_dir
#  DESCRIPTION:  Checks the config directory, retrieves URLs if provided.
#===============================================================================
__check_config_dir() {
    CC_DIR_NAME="$1"
    CC_DIR_BASE=$(basename "${CC_DIR_NAME}")

    case "$CC_DIR_NAME" in
        http://*|https://*)
            __fetch_url "/tmp/${CC_DIR_BASE}" "${CC_DIR_NAME}"
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
        ftp://*)
            __fetch_url "/tmp/${CC_DIR_BASE}" "${CC_DIR_NAME}"
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
        *)
            if [ ! -e "${CC_DIR_NAME}" ]; then
                echo "null"
                return 0
            fi
            ;;
    esac

    case "$CC_DIR_NAME" in
        *.tgz|*.tar.gz)
            tar -zxf "${CC_DIR_NAME}" -C /tmp
            CC_DIR_BASE=$(basename ${CC_DIR_BASE} ".tgz")
            CC_DIR_BASE=$(basename ${CC_DIR_BASE} ".tar.gz")
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
        *.tbz|*.tar.bz2)
            tar -xjf "${CC_DIR_NAME}" -C /tmp
            CC_DIR_BASE=$(basename ${CC_DIR_BASE} ".tbz")
            CC_DIR_BASE=$(basename ${CC_DIR_BASE} ".tar.bz2")
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
        *.txz|*.tar.xz)
            tar -xJf "${CC_DIR_NAME}" -C /tmp
            CC_DIR_BASE=$(basename ${CC_DIR_BASE} ".txz")
            CC_DIR_BASE=$(basename ${CC_DIR_BASE} ".tar.xz")
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
    esac

    echo "${CC_DIR_NAME}"
}

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------
TEMP_CONFIG_DIR="null"
TEMP_KEYS_DIR="null"
INSTALL_MASTER=$BS_FALSE
INSTALL_SYNDIC=$BS_FALSE
INSTALL_MINION=$BS_TRUE
ECHO_DEBUG=${BS_ECHO_DEBUG:-$BS_FALSE}
CONFIG_ONLY=$BS_FALSE
PIP_ALLOWED=${BS_PIP_ALLOWED:-$BS_FALSE}
SALT_ETC_DIR=${BS_SALT_ETC_DIR:-/etc/salt}
FORCE_OVERWRITE=${BS_FORCE_OVERWRITE:-$BS_FALSE}

while getopts ":hvnDc:k:MSNCP" opt
do
  case "${opt}" in

    h )  usage; exit 0                                  ;;

    v )  echo "$0 -- Version $ScriptVersion"; exit 0    ;;
    n )  COLORS=0; __detect_color_support               ;;
    D )  ECHO_DEBUG=$BS_TRUE                            ;;
    c )  TEMP_CONFIG_DIR=$(__check_config_dir "$OPTARG")
         # If the configuration directory does not exist, error out
         if [ "$TEMP_CONFIG_DIR" = "null" ]; then
             echoerror "Unsupported URI scheme for $OPTARG"
             exit 1
         fi
         if [ ! -d "$TEMP_CONFIG_DIR" ]; then
             echoerror "The configuration directory ${TEMP_CONFIG_DIR} does not exist."
             exit 1
         fi
         ;;
    k )  TEMP_KEYS_DIR="$OPTARG"
         # If the configuration directory does not exist, error out
         if [ ! -d "$TEMP_KEYS_DIR" ]; then
             echoerror "The pre-seed keys directory ${TEMP_KEYS_DIR} does not exist."
             exit 1
         fi
         ;;
    M )  INSTALL_MASTER=$BS_TRUE                        ;;
    S )  INSTALL_SYNDIC=$BS_TRUE                        ;;
    N )  INSTALL_MINION=$BS_FALSE                       ;;
    C )  CONFIG_ONLY=$BS_TRUE                           ;;
    P )  PIP_ALLOWED=$BS_TRUE                           ;;
    F )  FORCE_OVERWRITE=$BS_TRUE                       ;;

    \?)  echo
         echoerror "Option does not exist : $OPTARG"
         usage
         exit 1
         ;;

  esac    # --- end of case ---
done
shift $(($OPTIND-1))


__check_unparsed_options() {
    shellopts="$1"
    # grep alternative for SunOS
    if [ -f /usr/xpg4/bin/grep ]; then
        grep='/usr/xpg4/bin/grep'
    else
        grep='grep'
    fi
    unparsed_options=$( echo "$shellopts" | ${grep} -E '[-]+[[:alnum:]]' )
    if [ "x$unparsed_options" != "x" ]; then
        usage
        echo
        echoerror "options are only allowed before install arguments"
        echo
        exit 1
    fi
}


# Check that we're actually installing one of minion/master/syndic
if [ $INSTALL_MINION -eq $BS_FALSE ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && [ $CONFIG_ONLY -eq $BS_FALSE ]; then
    echowarn "Nothing to install or configure"
    exit 0
fi

if [ $CONFIG_ONLY -eq $BS_TRUE ] && [ "$TEMP_CONFIG_DIR" = "null" ]; then
    echoerror "In order to run the script in configuration only mode you also need to provide the configuration directory."
    exit 1
fi

# Define installation type
if [ "$#" -eq 0 ];then
    ITYPE="stable"
else
    __check_unparsed_options "$*"
    ITYPE=$1
    shift
fi

# Check installation type
if [ "$ITYPE" != "stable" ] && [ "$ITYPE" != "daily" ] && [ "$ITYPE" != "git" ]; then
    echoerror "Installation type \"$ITYPE\" is not known..."
    exit 1
fi

# If doing a git install, check what branch/tag/sha will be checked out
if [ $ITYPE = "git" ]; then
    if [ "$#" -eq 0 ];then
        GIT_REV="master"
    else
        __check_unparsed_options "$*"
        GIT_REV="$1"
        shift
    fi
fi

# Check for any unparsed arguments. Should be an error.
if [ "$#" -gt 0 ]; then
    __check_unparsed_options "$*"
    usage
    echo
    echoerror "Too many arguments."
    exit 1
fi
# whoami alternative for SunOS
if [ -f /usr/xpg4/bin/id ]; then
    whoami='/usr/xpg4/bin/id -un'
else
    whoami='whoami'
fi
# Root permissions are required to run this script
if [ $(${whoami}) != "root" ]; then
    echoerror "Salt requires root privileges to install. Please re-run this script as root."
    exit 1
fi

CALLER=$(echo `ps -a -o pid,args | grep $$ | grep -v grep | tr -s ' '` | cut -d ' ' -f 2)
if [ "${CALLER}x" = "${0}x" ]; then
    CALLER="PIPED THROUGH"
fi
echoinfo "${CALLER} ${0} -- Version ${ScriptVersion}"
#echowarn "Running the unstable version of ${ScriptName}"


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __exit_cleanup
#   DESCRIPTION:  Cleanup any leftovers after script has ended
#
#
#   http://www.unix.com/man-page/POSIX/1posix/trap/
#
#               Signal Number   Signal Name
#               1               SIGHUP
#               2               SIGINT
#               3               SIGQUIT
#               6               SIGABRT
#               9               SIGKILL
#              14               SIGALRM
#              15               SIGTERM
#-------------------------------------------------------------------------------
__exit_cleanup() {
    EXIT_CODE=$?

    # Remove the logging pipe when the script exits
    echodebug "Removing the logging pipe $LOGPIPE"
    rm -f $LOGPIPE

    # Kill tee when exiting, CentOS, at least requires this
    TEE_PID=$(ps ax | grep tee | grep $LOGFILE | awk '{print $1}')

    [ "x$TEE_PID" = "x" ] && exit $EXIT_CODE

    echodebug "Killing logging pipe tee's with pid(s): $TEE_PID"

    # We need to trap errors since killing tee will cause a 127 errno
    # We also do this as late as possible so we don't "mis-catch" other errors
    __trap_errors() {
        echoinfo "Errors Trapped: $EXIT_CODE"
        # Exit with the "original" exit code, not the trapped code
        exit $EXIT_CODE
    }
    trap "__trap_errors" INT QUIT ABRT KILL QUIT TERM

    # Now we're "good" to kill tee
    kill -s TERM $TEE_PID

    # In case the 127 errno is not triggered, exit with the "original" exit code
    exit $EXIT_CODE
}
trap "__exit_cleanup" EXIT INT


# Define our logging file and pipe paths
LOGFILE="/tmp/$( echo $ScriptName | sed s/.sh/.log/g )"
LOGPIPE="/tmp/$( echo $ScriptName | sed s/.sh/.logpipe/g )"

# Create our logging pipe
# On FreeBSD we have to use mkfifo instead of mknod
mknod $LOGPIPE p >/dev/null 2>&1 || mkfifo $LOGPIPE >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echoerror "Failed to create the named pipe required to log"
    exit 1
fi

# What ever is written to the logpipe gets written to the logfile
tee < $LOGPIPE $LOGFILE &

# Close STDOUT, reopen it directing it to the logpipe
exec 1>&-
exec 1>$LOGPIPE
# Close STDERR, reopen it directing it to the logpipe
exec 2>&-
exec 2>$LOGPIPE


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __gather_hardware_info
#   DESCRIPTION:  Discover hardware information
#-------------------------------------------------------------------------------
__gather_hardware_info() {
    if [ -f /proc/cpuinfo ]; then
        CPU_VENDOR_ID=$(awk '/vendor_id|Processor/ {sub(/-.*$/,"",$3); print $3; exit}' /proc/cpuinfo )
    elif [ -f /usr/bin/kstat ]; then
        # SmartOS.
        # Solaris!?
        # This has only been tested for a GenuineIntel CPU
        CPU_VENDOR_ID=$(/usr/bin/kstat -p cpu_info:0:cpu_info0:vendor_id | awk '{print $2}')
    else
        CPU_VENDOR_ID=$( sysctl -n hw.model )
    fi
    CPU_VENDOR_ID_L=$( echo $CPU_VENDOR_ID | tr '[:upper:]' '[:lower:]' )
    CPU_ARCH=$(uname -m 2>/dev/null || uname -p 2>/dev/null || echo "unknown")
    CPU_ARCH_L=$( echo $CPU_ARCH | tr '[:upper:]' '[:lower:]' )

}
__gather_hardware_info


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __gather_os_info
#   DESCRIPTION:  Discover operating system information
#-------------------------------------------------------------------------------
__gather_os_info() {
    OS_NAME=$(uname -s 2>/dev/null)
    OS_NAME_L=$( echo $OS_NAME | tr '[:upper:]' '[:lower:]' )
    OS_VERSION=$(uname -r)
    OS_VERSION_L=$( echo $OS_VERSION | tr '[:upper:]' '[:lower:]' )
}
__gather_os_info


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __parse_version_string
#   DESCRIPTION:  Parse version strings ignoring the revision.
#                 MAJOR.MINOR.REVISION becomes MAJOR.MINOR
#-------------------------------------------------------------------------------
__parse_version_string() {
    VERSION_STRING="$1"
    PARSED_VERSION=$(
        echo $VERSION_STRING |
        sed -e 's/^/#/' \
            -e 's/^#[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\)\(\.[0-9][0-9]*\).*$/\1/' \
            -e 's/^#[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*$/\1/' \
            -e 's/^#[^0-9]*\([0-9][0-9]*\).*$/\1/' \
            -e 's/^#.*$//'
    )
    echo $PARSED_VERSION
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __unquote_string
#   DESCRIPTION:  Strip single or double quotes from the provided string.
#-------------------------------------------------------------------------------
__unquote_string() {
    echo $@ | sed "s/^\([\"']\)\(.*\)\1\$/\2/g"
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __camelcase_split
#   DESCRIPTION:  Convert CamelCased strings to Camel_Cased
#-------------------------------------------------------------------------------
__camelcase_split() {
    echo $@ | sed -r 's/([^A-Z-])([A-Z])/\1 \2/g'
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __strip_duplicates
#   DESCRIPTION:  Strip duplicate strings
#-------------------------------------------------------------------------------
__strip_duplicates() {
    echo $@ | tr -s '[:space:]' '\n' | awk '!x[$0]++'
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __sort_release_files
#   DESCRIPTION:  Custom sort function. Alphabetical or numerical sort is not
#                 enough.
#-------------------------------------------------------------------------------
__sort_release_files() {
    KNOWN_RELEASE_FILES=$(echo "(arch|centos|debian|ubuntu|fedora|redhat|suse|\
        mandrake|mandriva|gentoo|slackware|turbolinux|unitedlinux|lsb|system|\
        os)(-|_)(release|version)" | sed -r 's:[[:space:]]::g')
    primary_release_files=""
    secondary_release_files=""
    # Sort know VS un-known files first
    for release_file in $(echo $@ | sed -r 's:[[:space:]]:\n:g' | sort --unique --ignore-case); do
        match=$(echo $release_file | egrep -i ${KNOWN_RELEASE_FILES})
        if [ "x${match}" != "x" ]; then
            primary_release_files="${primary_release_files} ${release_file}"
        else
            secondary_release_files="${secondary_release_files} ${release_file}"
        fi
    done

    # Now let's sort by know files importance, max important goes last in the max_prio list
    max_prio="redhat-release centos-release"
    for entry in $max_prio; do
        if [ "x$(echo ${primary_release_files} | grep $entry)" != "x" ]; then
            primary_release_files=$(echo ${primary_release_files} | sed -e "s:\(.*\)\($entry\)\(.*\):\2 \1 \3:g")
        fi
    done
    # Now, least important goes last in the min_prio list
    min_prio="lsb-release"
    for entry in $max_prio; do
        if [ "x$(echo ${primary_release_files} | grep $entry)" != "x" ]; then
            primary_release_files=$(echo ${primary_release_files} | sed -e "s:\(.*\)\($entry\)\(.*\):\1 \3 \2:g")
        fi
    done

    # Echo the results collapsing multiple white-space into a single white-space
    echo "${primary_release_files} ${secondary_release_files}" | sed -r 's:[[:space:]]:\n:g'
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __gather_linux_system_info
#   DESCRIPTION:  Discover Linux system information
#-------------------------------------------------------------------------------
__gather_linux_system_info() {
    DISTRO_NAME=""
    DISTRO_VERSION=""

    # Let's test if the lsb_release binary is available
    rv=$(lsb_release >/dev/null 2>&1)
    if [ $? -eq 0 ]; then
        DISTRO_NAME=$(lsb_release -si)
        if [ "x$(echo "$DISTRO_NAME" | grep RedHat)" != "x" ]; then
            # Let's convert CamelCase to Camel Case
            DISTRO_NAME=$(__camelcase_split "$DISTRO_NAME")
        fi
        if [ "${DISTRO_NAME}" = "openSUSE project" ]; then
            # lsb_release -si returns "openSUSE project" on openSUSE 12.3
            DISTRO_NAME="opensuse"
        fi
        rv=$(lsb_release -sr)
        [ "${rv}x" != "x" ] && DISTRO_VERSION=$(__parse_version_string "$rv")
    elif [ -f /etc/lsb-release ]; then
        # We don't have the lsb_release binary, though, we do have the file it parses
        DISTRO_NAME=$(grep DISTRIB_ID /etc/lsb-release | sed -e 's/.*=//')
        rv=$(grep DISTRIB_RELEASE /etc/lsb-release | sed -e 's/.*=//')
        [ "${rv}x" != "x" ] && DISTRO_VERSION=$(__parse_version_string "$rv")
    fi

    if [ "x$DISTRO_NAME" != "x" ] && [ "x$DISTRO_VERSION" != "x" ]; then
        # We already have the distribution name and version
        return
    fi

    for rsource in $(__sort_release_files $(
            cd /etc && /bin/ls *[_-]release *[_-]version 2>/dev/null | env -i sort | \
            sed -e '/^redhat-release$/d' -e '/^lsb-release$/d'; \
            echo redhat-release lsb-release
            )); do

        [ -L "/etc/${rsource}" ] && continue        # Don't follow symlinks
        [ ! -f "/etc/${rsource}" ] && continue      # Does not exist

        n=$(echo ${rsource} | sed -e 's/[_-]release$//' -e 's/[_-]version$//')
        rv=$( (grep VERSION /etc/${rsource}; cat /etc/${rsource}) | grep '[0-9]' | sed -e 'q' )
        [ "${rv}x" = "x" ] && continue  # There's no version information. Continue to next rsource
        v=$(__parse_version_string "$rv")
        case $(echo ${n} | tr '[:upper:]' '[:lower:]') in
            redhat             )
                if [ ".$(egrep 'CentOS' /etc/${rsource})" != . ]; then
                    n="CentOS"
                elif [ ".$(egrep 'Red Hat Enterprise Linux' /etc/${rsource})" != . ]; then
                    n="<R>ed <H>at <E>nterprise <L>inux"
                else
                    n="<R>ed <H>at <L>inux"
                fi
                ;;
            arch               ) n="Arch Linux"     ;;
            centos             ) n="CentOS"         ;;
            debian             ) n="Debian"         ;;
            ubuntu             ) n="Ubuntu"         ;;
            fedora             ) n="Fedora"         ;;
            suse               ) n="SUSE"           ;;
            mandrake*|mandriva ) n="Mandriva"       ;;
            gentoo             ) n="Gentoo"         ;;
            slackware          ) n="Slackware"      ;;
            turbolinux         ) n="TurboLinux"     ;;
            unitedlinux        ) n="UnitedLinux"    ;;
            system             )
                while read -r line; do
                    [ "${n}x" != "systemx" ] && break
                    case "$line" in
                        *Amazon*Linux*AMI*)
                            n="Amazon Linux AMI"
                            break
                    esac
                done < /etc/${rsource}
                ;;
            os                 )
                nn=$(__unquote_string $(grep '^ID=' /etc/os-release | sed -e 's/^ID=\(.*\)$/\1/g'))
                rv=$(__unquote_string $(grep '^VERSION_ID=' /etc/os-release | sed -e 's/^VERSION_ID=\(.*\)$/\1/g'))
                [ "${rv}x" != "x" ] && v=$(__parse_version_string "$rv") || v=""
                case $(echo ${nn} | tr '[:upper:]' '[:lower:]') in
                    arch        )
                        n="Arch Linux"
                        v=""  # Arch Linux does not provide a version.
                        ;;
                    debian      )
                        n="Debian"
                        if [ "${v}x" = "x" ]; then
                            if [ "$(cat /etc/debian_version)" = "wheezy/sid" ]; then
                                # I've found an EC2 wheezy image which did not tell its version
                                v=$(__parse_version_string "7.0")
                            fi
                        else
                            echowarn "Unable to parse the Debian Version"
                        fi
                        ;;
                    *           )
                        n=${nn}
                        ;;
                esac
                ;;
            *                  ) n="${n}"           ;
        esac
        DISTRO_NAME=$n
        DISTRO_VERSION=$v
        break
    done
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __gather_sunos_system_info
#   DESCRIPTION:  Discover SunOS system info
#-------------------------------------------------------------------------------
__gather_sunos_system_info() {
    if [ -f /sbin/uname ]; then
        DISTRO_VERSION=$(/sbin/uname -X | awk '/[kK][eE][rR][nN][eE][lL][iI][dD]/ { print $3}')
    fi

    DISTRO_NAME=""
    if [ -f /etc/release ]; then
        while read -r line; do
            [ "${DISTRO_NAME}x" != "x" ] && break
            case "$line" in
                *OpenIndiana*oi_[0-9]*)
                    DISTRO_NAME="OpenIndiana"
                    DISTRO_VERSION=$(echo "$line" | sed -nr "s/OpenIndiana(.*)oi_([[:digit:]]+)(.*)/\2/p")
                    break
                    ;;
                *OpenSolaris*snv_[0-9]*)
                    DISTRO_NAME="OpenSolaris"
                    DISTRO_VERSION=$(echo "$line" | sed -nr "s/OpenSolaris(.*)snv_([[:digit:]]+)(.*)/\2/p")
                    break
                    ;;
                *Oracle*Solaris*[0-9]*)
                    DISTRO_NAME="Oracle Solaris"
                    DISTRO_VERSION=$(echo "$line" | sed -nr "s/(Oracle Solaris) ([[:digit:]]+)(.*)/\2/p")
                    break
                    ;;
                *Solaris*)
                    DISTRO_NAME="Solaris"
                    break
                    ;;
                *NexentaCore*)
                    DISTRO_NAME="Nexenta Core"
                    break
                    ;;
                *SmartOS*)
                    DISTRO_NAME="SmartOS"
                    break
                    ;;
            esac
        done < /etc/release
    fi

    if [ "${DISTRO_NAME}x" = "x" ]; then
        DISTRO_NAME="Solaris"
        DISTRO_VERSION=$(
            echo "${OS_VERSION}" |
            sed -e 's;^4\.;1.;' \
                -e 's;^5\.\([0-6]\)[^0-9]*$;2.\1;' \
                -e 's;^5\.\([0-9][0-9]*\).*;\1;'
        )
    fi

    if [ "${DISTRO_NAME}" = "SmartOS" ]; then
        VIRTUAL_TYPE="smartmachine"
        if [ "$(zonename)" = "global" ]; then
            VIRTUAL_TYPE="global"
        fi
    fi
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __gather_bsd_system_info
#   DESCRIPTION:  Discover OpenBSD, NetBSD and FreeBSD systems information
#-------------------------------------------------------------------------------
__gather_bsd_system_info() {
    DISTRO_NAME=${OS_NAME}
    DISTRO_VERSION=$(echo "${OS_VERSION}" | sed -e 's;[()];;' -e 's/-.*$//')
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __gather_system_info
#   DESCRIPTION:  Discover which system and distribution we are running.
#-------------------------------------------------------------------------------
__gather_system_info() {
    case ${OS_NAME_L} in
        linux )
            __gather_linux_system_info
            ;;
        sunos )
            __gather_sunos_system_info
            ;;
        openbsd|freebsd|netbsd )
            __gather_bsd_system_info
            ;;
        * )
            echoerror "${OS_NAME} not supported.";
            exit 1
            ;;
    esac

}
__gather_system_info


echo
echoinfo "System Information:"
echoinfo "  CPU:          ${CPU_VENDOR_ID}"
echoinfo "  CPU Arch:     ${CPU_ARCH}"
echoinfo "  OS Name:      ${OS_NAME}"
echoinfo "  OS Version:   ${OS_VERSION}"
echoinfo "  Distribution: ${DISTRO_NAME} ${DISTRO_VERSION}"
echo

# Let users know what's going to be installed/configured
if [ $INSTALL_MINION -eq $BS_TRUE ]; then
    if [ $CONFIG_ONLY -eq $BS_FALSE ]; then
        echoinfo "Installing minion"
    else
        echoinfo "Configuring minion"
    fi
fi

if [ $INSTALL_MASTER -eq $BS_TRUE ]; then
    if [ $CONFIG_ONLY -eq $BS_FALSE ]; then
        echoinfo "Installing master"
    else
        echoinfo "Configuring master"
    fi
fi

if [ $INSTALL_SYNDIC -eq $BS_TRUE ]; then
    if [ $CONFIG_ONLY -eq $BS_FALSE ]; then
        echoinfo "Installing syndic"
    else
        echoinfo "Configuring syndic"
    fi
fi

# Simplify version naming on functions
if [ "x${DISTRO_VERSION}" = "x" ]; then
    DISTRO_MAJOR_VERSION=""
    DISTRO_MINOR_VERSION=""
    PREFIXED_DISTRO_MAJOR_VERSION=""
    PREFIXED_DISTRO_MINOR_VERSION=""
else
    DISTRO_MAJOR_VERSION="$(echo $DISTRO_VERSION | sed 's/^\([0-9]*\).*/\1/g')"
    DISTRO_MINOR_VERSION="$(echo $DISTRO_VERSION | sed 's/^\([0-9]*\).\([0-9]*\).*/\2/g')"
    PREFIXED_DISTRO_MAJOR_VERSION="_${DISTRO_MAJOR_VERSION}"
    if [ "${PREFIXED_DISTRO_MAJOR_VERSION}" = "_" ]; then
        PREFIXED_DISTRO_MAJOR_VERSION=""
    fi
    PREFIXED_DISTRO_MINOR_VERSION="_${DISTRO_MINOR_VERSION}"
    if [ "${PREFIXED_DISTRO_MINOR_VERSION}" = "_" ]; then
        PREFIXED_DISTRO_MINOR_VERSION=""
    fi
fi
# Simplify distro name naming on functions
DISTRO_NAME_L=$(echo $DISTRO_NAME | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9_ ]//g' | sed -re 's/([[:space:]])+/_/g')


# Only Ubuntu has daily packages, let's let users know about that
if ([ "${DISTRO_NAME_L}" != "ubuntu" ] && [ $ITYPE = "daily" ]) && \
   ([ "${DISTRO_NAME_L}" != "trisquel" ] && [ $ITYPE = "daily" ]); then
    echoerror "${DISTRO_NAME} does not have daily packages support"
    exit 1
fi

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __function_defined
#   DESCRIPTION:  Checks if a function is defined within this scripts scope
#    PARAMETERS:  function name
#       RETURNS:  0 or 1 as in defined or not defined
#-------------------------------------------------------------------------------
__function_defined() {
    FUNC_NAME=$1
    if [ "$(command -v $FUNC_NAME)x" != "x" ]; then
        echoinfo "Found function $FUNC_NAME"
        return 0
    fi
    echodebug "$FUNC_NAME not found...."
    return 1
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __git_clone_and_checkout
#   DESCRIPTION:  (DRY) Helper function to clone and checkout salt to a
#                 specific revision.
#-------------------------------------------------------------------------------
__git_clone_and_checkout() {
    SALT_GIT_CHECKOUT_DIR=/tmp/git/salt
    [ -d /tmp/git ] || mkdir /tmp/git
    cd /tmp/git
    if [ -d $SALT_GIT_CHECKOUT_DIR ]; then
        cd $SALT_GIT_CHECKOUT_DIR
        git fetch || return 1
        # Tags are needed because of salt's versioning, also fetch that
        git fetch --tags || return 1
        git reset --hard $GIT_REV || return 1

        # Just calling `git reset --hard $GIT_REV` on a branch name that has
        # already been checked out will not update that branch to the upstream
        # HEAD; instead it will simply reset to itself.  Check the ref to see
        # if it is a branch name, check out the branch, and pull in the
        # changes.
        git branch -a | grep -q ${GIT_REV}
        if [ $? -eq 0 ]; then
            git pull --rebase || return 1
        fi
    else
        git clone git://github.com/saltstack/salt.git || return 1
        cd $SALT_GIT_CHECKOUT_DIR
        git checkout $GIT_REV || return 1
    fi
    return 0
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __apt_get_noinput
#   DESCRIPTION:  (DRY) apt-get install with noinput options
#-------------------------------------------------------------------------------
__apt_get_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold $@; return $?
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  copyfile
#   DESCRIPTION:  Simple function to copy files. Overrides if asked.
#-------------------------------------------------------------------------------
copyfile() {
    overwrite=$FORCE_OVERWRITE
    if [ $# -eq 2 ]; then
        sfile=$1
        dfile=$2
    elif [ $# -eq 3 ]; then
        sfile=$1
        dfile=$2
        overwrite=$3
    else
        echoerror "Wrong number of arguments for copyfile()"
        echoinfo "USAGE: copyfile <source> <dest>  OR  copyfile <source> <dest> <overwrite>"
        exit 1
    fi

    # Does the source file exist?
    if [ ! -f "$sfile" ]; then
        echowarn "$sfile does not exist!"
        return 1
    fi

    if [ ! -f "$dfile" ]; then
        # The destination file does not exist, copy
        echodebug "Copying $sfile to $dfile"
        cp "$sfile" "$dfile" || return 1
    elif [ -f "$dfile" ] && [ $overwrite -eq $BS_TRUE ]; then
        # The destination exist and we're overwriting
        echodebug "Overriding $dfile with $sfile"
        cp -f "$sfile" "$dfile" || return 2
    elif [ -f "$dfile" ] && [ $overwrite -ne $BS_TRUE ]; then
        echodebug "Not overriding $dfile with $sfile"
    fi
    return 0
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  movefile
#   DESCRIPTION:  Simple function to move files. Overrides if asked.
#-------------------------------------------------------------------------------
movefile() {
    overwrite=$FORCE_OVERWRITE
    if [ $# -eq 2 ]; then
        sfile=$1
        dfile=$2
    elif [ $# -eq 3 ]; then
        sfile=$1
        dfile=$2
        overwrite=$3
    else
        echoerror "Wrong number of arguments for movefile()"
        echoinfo "USAGE: movefile <source> <dest>  OR  movefile <source> <dest> <overwrite>"
        exit 1
    fi

    # Does the source file exist?
    if [ ! -f "$sfile" ]; then
        echowarn "$sfile does not exist!"
        return 1
    fi

    if [ ! -f "$dfile" ]; then
        # The destination file does not exist, copy
        echodebug "Moving $sfile to $dfile"
        mv "$sfile" "$dfile" || return 1
    elif [ -f "$dfile" ] && [ $overwrite -eq $BS_TRUE ]; then
        # The destination exist and we're overwriting
        echodebug "Overriding $dfile with $sfile"
        mv -f "$sfile" "$dfile" || return 1
    elif [ -f "$dfile" ] && [ $overwrite -ne $BS_TRUE ]; then
        echodebug "Not overriding $dfile with $sfile"
    fi

    return 0
}

##############################################################################
#
#   Distribution install functions
#
#   In order to install salt for a distribution you need to define:
#
#   To Install Dependencies, which is required, one of:
#       1. install_<distro>_<major_version>_<install_type>_deps
#       2. install_<distro>_<major_version>_<minor_version>_<install_type>_deps
#       3. install_<distro>_<major_version>_deps
#       4  install_<distro>_<major_version>_<minor_version>_deps
#       5. install_<distro>_<install_type>_deps
#       6. install_<distro>_deps
#
#   Optionally, define a salt configuration function, which will be called if
#   the -c (config-dir) option is passed. One of:
#       1. config_<distro>_<major_version>_<install_type>_salt
#       2. config_<distro>_<major_version>_<minor_version>_<install_type>_salt
#       3. config_<distro>_<major_version>_salt
#       4  config_<distro>_<major_version>_<minor_version>_salt
#       5. config_<distro>_<install_type>_salt
#       6. config_<distro>_salt
#       7. config_salt [THIS ONE IS ALREADY DEFINED AS THE DEFAULT]
#
#   Optionally, define a salt master pre-seed function, which will be called if
#   the -k (pre-seed master keys) option is passed. One of:
#       1. pressed_<distro>_<major_version>_<install_type>_master
#       2. pressed_<distro>_<major_version>_<minor_version>_<install_type>_master
#       3. pressed_<distro>_<major_version>_master
#       4  pressed_<distro>_<major_version>_<minor_version>_master
#       5. pressed_<distro>_<install_type>_master
#       6. pressed_<distro>_master
#       7. pressed_master [THIS ONE IS ALREADY DEFINED AS THE DEFAULT]
#
#   To install salt, which, of course, is required, one of:
#       1. install_<distro>_<major_version>_<install_type>
#       2. install_<distro>_<major_version>_<minor_version>_<install_type>
#       3. install_<distro>_<install_type>
#
#   Optionally, define a post install function, one of:
#       1. install_<distro>_<major_version>_<install_type>_post
#       2. install_<distro>_<major_version>_<minor_version>_<install_type>_post
#       3. install_<distro>_<major_version>_post
#       4  install_<distro>_<major_version>_<minor_version>_post
#       5. install_<distro>_<install_type>_post
#       6. install_<distro>_post
#
#   Optionally, define a start daemons function, one of:
#       1. install_<distro>_<major_version>_<install_type>_restart_daemons
#       2. install_<distro>_<major_version>_<minor_version>_<install_type>_restart_daemons
#       3. install_<distro>_<major_version>_restart_daemons
#       4  install_<distro>_<major_version>_<minor_version>_restart_daemons
#       5. install_<distro>_<install_type>_restart_daemons
#       6. install_<distro>_restart_daemons
#
#       NOTE: The start daemons function should be able to restart any daemons
#             which are running, or start if they're not running.
#
##############################################################################


##############################################################################
#
#   Ubuntu Install Functions
#
install_ubuntu_deps() {
    apt-get update
    if [ $DISTRO_MAJOR_VERSION -eq 12 ] && [ $DISTRO_MINOR_VERSION -gt 04 ] || [ $DISTRO_MAJOR_VERSION -gt 12 ]; then
        # Above Ubuntu 12.04 add-apt-repository is in a different package
        __apt_get_noinput software-properties-common || return 1
    else
        __apt_get_noinput python-software-properties || return 1
    fi
    if [ $DISTRO_MAJOR_VERSION -lt 11 ] && [ $DISTRO_MINOR_VERSION -lt 10 ]; then
        add-apt-repository ppa:saltstack/salt || return 1
    else
        add-apt-repository -y ppa:saltstack/salt || return 1
    fi
    apt-get update
    return 0
}

install_ubuntu_daily_deps() {
    install_ubuntu_deps
    if [ $DISTRO_MAJOR_VERSION -eq 12 ] && [ $DISTRO_MINOR_VERSION -gt 04 ] || [ $DISTRO_MAJOR_VERSION -gt 12 ]; then
        # Above Ubuntu 12.04 add-apt-repository is in a different package
        __apt_get_noinput software-properties-common || return 1
    else
        __apt_get_noinput python-software-properties || return 1
    fi
    if [ $DISTRO_MAJOR_VERSION -lt 11 ] && [ $DISTRO_MINOR_VERSION -lt 10 ]; then
        add-apt-repository ppa:saltstack/salt-daily || return 1
    else
        add-apt-repository -y ppa:saltstack/salt-daily || return 1
    fi
    apt-get update
    return 0
}

install_ubuntu_11_10_deps() {
    apt-get update
    __apt_get_noinput python-software-properties || return 1
    add-apt-repository -y 'deb http://us.archive.ubuntu.com/ubuntu/ oneiric universe' || return 1
    add-apt-repository -y ppa:saltstack/salt || return 1
    apt-get update
    return 0
}

install_ubuntu_git_deps() {
    install_ubuntu_deps || return 1
    __apt_get_noinput git-core python-yaml python-m2crypto python-crypto \
        msgpack-python python-zmq python-jinja2 || return 1

    __git_clone_and_checkout || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_ubuntu_11_10_post() {
    add-apt-repository -y --remove 'deb http://us.archive.ubuntu.com/ubuntu/ oneiric universe' || return 1
    return 0
}

install_ubuntu_stable() {
    packages=""
    if [ $INSTALL_MINION -eq $BS_TRUE ]; then
        packages="${packages} salt-minion"
    fi
    if [ $INSTALL_MASTER -eq $BS_TRUE ]; then
        packages="${packages} salt-master"
    fi
    if [ $INSTALL_SYNDIC -eq $BS_TRUE ]; then
        packages="${packages} salt-syndic"
    fi
    __apt_get_noinput ${packages} || return 1
    return 0
}

install_ubuntu_daily() {
    install_ubuntu_stable || return 1
    return 0
}

install_ubuntu_git() {
    python setup.py install --install-layout=deb || return 1
    return 0
}

install_ubuntu_git_post() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /sbin/initctl ]; then
            # We have upstart support
            echodebug "There's upstart support"
            /sbin/initctl status salt-$fname > /dev/null 2>&1

            if [ $? -eq 1 ]; then
                # upstart does not know about our service, let's copy the proper file
                echowarn "Upstart does not apparently know anything about salt-$fname"
                echodebug "Copying ${SALT_GIT_CHECKOUT_DIR}/pkg/salt-$fname.upstart to /etc/init/salt-$fname.conf"
                copyfile ${SALT_GIT_CHECKOUT_DIR}/pkg/salt-$fname.upstart /etc/init/salt-$fname.conf
            fi
        # No upstart support in Ubuntu!?
        elif [ -f ${SALT_GIT_CHECKOUT_DIR}/debian/salt-$fname.init ]; then
            echodebug "There's NO upstart support!?"
            echodebug "Copying ${SALT_GIT_CHECKOUT_DIR}/debian/salt-$fname.init to /etc/init.d/salt-$fname"
            copyfile ${SALT_GIT_CHECKOUT_DIR}/debian/salt-$fname.init /etc/init.d/salt-$fname
            chmod +x /etc/init.d/salt-$fname
            update-rc.d salt-$fname defaults
        else
            echoerror "Neither upstart not init.d was setup for salt-$fname"
        fi
    done
}

install_ubuntu_restart_daemons() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /sbin/initctl ]; then
            echodebug "There's upstart support while checking salt-$fname"
            status salt-$fname || echowarn "Upstart does not apparently know anything about salt-$fname"
            sleep 1
            if [ $? -eq 0 ]; then
                echodebug "Upstart apparently knows about salt-$fname"
                # upstart knows about this service, let's stop and start it.
                # We could restart but earlier versions of the upstart script
                # did not support restart, so, it's safer this way

                # Is it running???
                status salt-$fname | grep -q running
                # If it is, stop it
                if [ $? -eq 0 ]; then
                    sleep 1
                    stop salt-$fname || (echodebug "Failed to stop salt-$fname" && return 1)
                fi
                # Now start it
                sleep 1
                start salt-$fname
                [ $? -eq 0 ] && continue
                # We failed to start the service, let's test the SysV code bellow
                echodebug "Failed to start salt-$fname"
            fi
        fi

        if [ ! -f /etc/init.d/salt-$fname ]; then
            echoerror "No init.d support for salt-$fname was found"
            return 1
        fi

        /etc/init.d/salt-$fname stop > /dev/null 2>&1
        /etc/init.d/salt-$fname start
    done
    return 0
}
#
#   End of Ubuntu Install Functions
#
##############################################################################

##############################################################################
#
#   Trisquel(Ubuntu) Install Functions
#
#   Trisquel 6.0 is based on Ubuntu 12.04
#
install_trisquel_6_stable_deps() {
    apt-get update
    __apt_get_noinput python-software-properties || return 1
    add-apt-repository -y ppa:saltstack/salt || return 1
    apt-get update
    return 0
}

install_trisquel_6_daily_deps() {
    apt-get update
    __apt_get_noinput python-software-properties || return 1
    add-apt-repository -y ppa:saltstack/salt-daily || return 1
    apt-get update
    return 0
}

install_trisquel_6_git_deps() {
    install_trisquel_6_stable_deps || return 1
    __apt_get_noinput git-core python-yaml python-m2crypto python-crypto \
        msgpack-python python-zmq python-jinja2 || return 1

    __git_clone_and_checkout || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_trisquel_6_stable() {
    install_ubuntu_stable || return 1
    return 0
}

install_trisquel_6_daily() {
    install_ubuntu_daily || return 1
    return 0
}

install_trisquel_6_git() {
    install_ubuntu_git || return 1
    return 0
}

install_trisquel_git_post() {
    install_ubuntu_git_post || return 1
    return 0
}

install_trisquel_restart_daemons() {
    install_ubuntu_restart_daemons || return 1
    return 0
}
#
#   End of Tristel(Ubuntu) Install Functions
#
##############################################################################

##############################################################################
#
#   Debian Install Functions
#
install_debian_deps() {
    # No user interaction, libc6 restart services for example
    export DEBIAN_FRONTEND=noninteractive

    apt-get update
}

install_debian_6_deps() {
    # No user interaction, libc6 restart services for example
    export DEBIAN_FRONTEND=noninteractive

    wget -q http://debian.saltstack.com/debian-salt-team-joehealy.gpg.key -O - | apt-key add - || return 1

    if [ $PIP_ALLOWED -eq $BS_TRUE ]; then
        echowarn "PyZMQ will be installed from PyPI in order to compile it against ZMQ3"
        echowarn "This is required for long term stable minion connections to the master."
        echowarn "YOU WILL END UP WILL QUITE A FEW PACKAGES FROM DEBIAN UNSTABLE"
        echowarn "Sleeping for 3 seconds so you can cancel..."
        sleep 3

        if [ ! -f /etc/apt/sources.list.d/debian-unstable.list ]; then
           cat <<_eof > /etc/apt/sources.list.d/debian-unstable.list
deb http://ftp.debian.org/debian unstable main
deb-src http://ftp.debian.org/debian unstable main
_eof

           cat <<_eof > /etc/apt/preferences.d/libzmq3-debian-unstable.pref
Package: libzmq3
Pin: release a=unstable
Pin-Priority: 800

Package: libzmq3-dev
Pin: release a=unstable
Pin-Priority: 800
_eof
        fi

        apt-get update
        # We NEED to install the unstable dpkg or mime-support WILL fail to install
        __apt_get_noinput -t unstable dpkg liblzma5 python mime-support || return 1
        __apt_get_noinput -t unstable libzmq3 libzmq3-dev || return 1
        __apt_get_noinput build-essential python-dev python-pip || return 1

        # Saltstack's Unstable Debian repository
        if [ "x$(grep -R 'debian.saltstack.com' /etc/apt)" = "x" ]; then
            echo "deb http://debian.saltstack.com/debian unstable main" >> \
                /etc/apt/sources.list.d/saltstack.list
        fi
        return 0
    fi

    # Debian Backports
    if [ "x$(grep -R 'backports.debian.org' /etc/apt)" = "x" ]; then
        echo "deb http://backports.debian.org/debian-backports squeeze-backports main" >> \
            /etc/apt/sources.list.d/backports.list
    fi

    # Saltstack's Stable Debian repository
    if [ "x$(grep -R 'squeeze-saltstack' /etc/apt)" = "x" ]; then
        echo "deb http://debian.saltstack.com/debian squeeze-saltstack main" >> \
            /etc/apt/sources.list.d/saltstack.list
    fi
    apt-get update || return 1
    __apt_get_noinput python-zmq || return 1
    return 0
}

install_debian_7_deps() {
    # No user interaction, libc6 restart services for example
    export DEBIAN_FRONTEND=noninteractive

    # Saltstack's Stable Debian repository
    if [ "x$(grep -R 'wheezy-saltstack' /etc/apt)" = "x" ]; then
        echo "deb http://debian.saltstack.com/debian wheezy-saltstack main" >> \
            /etc/apt/sources.list.d/saltstack.list
    fi

    wget -q http://debian.saltstack.com/debian-salt-team-joehealy.gpg.key -O - | apt-key add - || return 1

    if [ $PIP_ALLOWED -eq $BS_TRUE ]; then
        echowarn "PyZMQ will be installed from PyPI in order to compile it against ZMQ3"
        echowarn "This is required for long term stable minion connections to the master."
        echowarn "YOU WILL END UP WILL QUITE A FEW PACKAGES FROM DEBIAN UNSTABLE"
        echowarn "Sleeping for 3 seconds so you can cancel..."
        sleep 3

        if [ ! -f /etc/apt/sources.list.d/debian-unstable.list ]; then
           cat <<_eof > /etc/apt/sources.list.d/debian-unstable.list
deb http://ftp.debian.org/debian unstable main
deb-src http://ftp.debian.org/debian unstable main
_eof

           cat <<_eof > /etc/apt/preferences.d/libzmq3-debian-unstable.pref
Package: libzmq3
Pin: release a=unstable
Pin-Priority: 800

Package: libzmq3-dev
Pin: release a=unstable
Pin-Priority: 800
_eof
        fi

        apt-get update
        __apt_get_noinput -t unstable libzmq3 libzmq3-dev || return 1
        __apt_get_noinput build-essential python-dev python-pip || return 1
    else
        apt-get update || return 1
        __apt_get_noinput python-zmq || return 1
    fi
    return 0
}

install_debian_git_deps() {
    # No user interaction, libc6 restart services for example
    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    __apt_get_noinput lsb-release python python-pkg-resources python-crypto \
        python-jinja2 python-m2crypto python-yaml msgpack-python python-pip \
        git || return 1

    __git_clone_and_checkout || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_debian_6_git_deps() {
    install_debian_6_deps || return 1
    if [ $PIP_ALLOWED -eq $BS_TRUE ]; then
        easy_install -U Jinja2 || return 1
        __apt_get_noinput lsb-release python python-pkg-resources python-crypto \
            python-m2crypto python-yaml msgpack-python python-pip git || return 1

        __git_clone_and_checkout || return 1

        # Let's trigger config_salt()
        if [ "$TEMP_CONFIG_DIR" = "null" ]; then
            TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
            CONFIG_SALT_FUNC="config_salt"
        fi
    else
        install_debian_git_deps || return 1  # Grab the actual deps
    fi
    return 0
}

install_debian_7_git_deps() {
    install_debian_7_deps || return 1
    install_debian_git_deps || return 1  # Grab the actual deps
    return 0
}

__install_debian_stable() {
    packages=""
    if [ $INSTALL_MINION -eq $BS_TRUE ]; then
        packages="${packages} salt-minion"
    fi
    if [ $INSTALL_MASTER -eq $BS_TRUE ]; then
        packages="${packages} salt-master"
    fi
    if [ $INSTALL_SYNDIC -eq $BS_TRUE ]; then
        packages="${packages} salt-syndic"
    fi
    __apt_get_noinput ${packages} || return 1

    if [ $PIP_ALLOWED -eq $BS_TRUE ]; then
        # Building pyzmq from source to build it against libzmq3.
        # Should override current installation
        # Using easy_install instead of pip because at least on Debian 6,
        # there's no default virtualenv active.
        easy_install -U pyzmq || return 1
    fi

    return 0
}


install_debian_6_stable() {
    __install_debian_stable || return 1
    return 0
}

install_debian_7_stable() {
    __install_debian_stable || return 1
    return 0
}

install_debian_git() {
    if [ $PIP_ALLOWED -eq $BS_TRUE ]; then
        # Building pyzmq from source to build it against libzmq3.
        # Should override current installation
        # Using easy_install instead of pip because at least on Debian 6,
        # there's no default virtualenv active.
        easy_install -U pyzmq || return 1
    fi

    python setup.py install --install-layout=deb || return 1
}

install_debian_6_git() {
    install_debian_git || return 1
    return 0
}

install_debian_7_git() {
    install_debian_git || return 1
    return 0
}

install_debian_git_post() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f ${SALT_GIT_CHECKOUT_DIR}/debian/salt-$fname.init ]; then
            copyfile ${SALT_GIT_CHECKOUT_DIR}/debian/salt-$fname.init /etc/init.d/salt-$fname
        fi
        chmod +x /etc/init.d/salt-$fname
        update-rc.d salt-$fname defaults
    done
}

install_debian_restart_daemons() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        /etc/init.d/salt-$fname stop > /dev/null 2>&1
        /etc/init.d/salt-$fname start
    done
}
#
#   Ended Debian Install Functions
#
##############################################################################

##############################################################################
#
#   Fedora Install Functions
#
install_fedora_deps() {
    yum install -y PyYAML libyaml m2crypto python-crypto python-jinja2 \
        python-msgpack python-zmq || return 1
    return 0
}

install_fedora_stable() {
    packages=""
    if [ $INSTALL_MINION -eq $BS_TRUE ]; then
        packages="${packages} salt-minion"
    fi
    if [ $INSTALL_MASTER -eq $BS_TRUE ] || [ $INSTALL_SYNDIC -eq $BS_TRUE ]; then
        packages="${packages} salt-master"
    fi
    yum install -y ${packages} || return 1
    return 0
}

install_fedora_git_deps() {
    install_fedora_deps || return 1
    yum install -y git || return 1

    __git_clone_and_checkout || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_fedora_git() {
    python setup.py install || return 1
    return 0
}

install_fedora_git_post() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        copyfile ${SALT_GIT_CHECKOUT_DIR}/pkg/rpm/salt-$fname.service /lib/systemd/system/salt-$fname.service

        systemctl is-enabled salt-$fname.service || (systemctl preset salt-$fname.service && systemctl enable salt-$fname.service)
        sleep 0.1
        systemctl daemon-reload
    done
}

install_fedora_restart_daemons() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        systemctl stop salt-$fname > /dev/null 2>&1
        systemctl start salt-$fname.service
    done
}
#
#   Ended Fedora Install Functions
#
##############################################################################

##############################################################################
#
#   CentOS Install Functions
#
install_centos_stable_deps() {
    if [ $CPU_ARCH_L = "i686" ]; then
        EPEL_ARCH="i386"
    else
        EPEL_ARCH=$CPU_ARCH_L
    fi
    if [ $DISTRO_MAJOR_VERSION -eq 5 ]; then
        rpm -Uvh --force http://mirrors.kernel.org/fedora-epel/5/${EPEL_ARCH}/epel-release-5-4.noarch.rpm || return 1
    elif [ $DISTRO_MAJOR_VERSION -eq 6 ]; then
        rpm -Uvh --force http://mirrors.kernel.org/fedora-epel/6/${EPEL_ARCH}/epel-release-6-8.noarch.rpm || return 1
    else
        echoerror "Failed add EPEL repository support."
        return 1
    fi

    yum -y update || return 1

    if [ $DISTRO_MAJOR_VERSION -eq 5 ]; then
        yum -y install PyYAML python26-m2crypto m2crypto python26 \
            python26-crypto python26-msgpack python26-zmq \
            python26-jinja2 --enablerepo=epel || return 1
    else
        yum -y install PyYAML m2crypto python-crypto python-msgpack \
            python-zmq python-jinja2 --enablerepo=epel || return 1
    fi
    return 0
}

install_centos_stable() {
    packages=""
    if [ $INSTALL_MINION -eq $BS_TRUE ]; then
        packages="${packages} salt-minion"
    fi
    if [ $INSTALL_MASTER -eq $BS_TRUE ] || [ $INSTALL_SYNDIC -eq $BS_TRUE ]; then
        packages="${packages} salt-master"
    fi
    yum -y install ${packages} --enablerepo=epel || return 1
    return 0
}

install_centos_stable_post() {
    for fname in minion master syndic; do
        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ ! -f /sbin/initctl ] && [ -f /etc/init.d/salt-$fname ]; then
            # Still in SysV init!?
            /sbin/chkconfig salt-$fname on
        fi
    done
}

install_centos_git_deps() {
    install_centos_stable_deps || return 1
    yum -y install git --enablerepo=epel || return 1

    __git_clone_and_checkout || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_centos_git() {
    if [ $DISTRO_MAJOR_VERSION -eq 5 ]; then
        python2.6 setup.py install || return 1
    else
        python2 setup.py install || return 1
    fi
    return 0
}

install_centos_git_post() {
    for fname in master minion syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /sbin/initctl ]; then
            # We have upstart support
            /sbin/initctl status salt-$fname > /dev/null 2>&1
            if [ $? -eq 1 ]; then
                # upstart does not know about our service, let's copy the proper file
                copyfile ${SALT_GIT_CHECKOUT_DIR}/pkg/salt-$fname.upstart /etc/init/salt-$fname.conf
            fi
        # Still in SysV init?!
        elif [ ! -f /etc/init.d/salt-$fname ]; then
            copyfile ${SALT_GIT_CHECKOUT_DIR}/pkg/rpm/salt-${fname} /etc/init.d/
            chmod +x /etc/init.d/salt-${fname}
            /sbin/chkconfig salt-${fname} on
        fi
    done
}

install_centos_restart_daemons() {
    for fname in minion master syndic; do
        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /sbin/initctl ]; then
            # We have upstart support
            /sbin/initctl status salt-$fname > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                # upstart knows about this service.
                # Let's try to stop it, and then start it
                /sbin/initctl stop salt-$fname > /dev/null 2>&1
                /sbin/initctl start salt-$fname > /dev/null 2>&1
                # Restart service
                [ $? -eq 0 ] && continue
                # We failed to start the service, let's test the SysV code bellow
            fi
        fi

        if [ -f /etc/init.d/salt-$fname ]; then
            # Still in SysV init!?
            /etc/init.d/salt-$fname stop > /dev/null 2>&1
            /etc/init.d/salt-$fname start
        fi
    done
}
#
#   Ended CentOS Install Functions
#
##############################################################################

##############################################################################
#
#   RedHat Install Functions
#
install_red_hat_linux_stable_deps() {
    install_centos_stable_deps || return 1
    return 0
}

install_red_hat_linux_git_deps() {
    install_centos_git_deps || return 1
    return 0
}

install_red_hat_enterprise_linux_stable_deps() {
    install_red_hat_linux_stable_deps || return 1
    return 0
}

install_red_hat_enterprise_linux_git_deps() {
    install_red_hat_linux_git_deps || return 1
    return 0
}

install_red_hat_enterprise_server_stable_deps() {
    install_red_hat_linux_stable_deps || return 1
    return 0
}

install_red_hat_enterprise_server_git_deps() {
    install_red_hat_linux_git_deps || return 1
    return 0
}

install_red_hat_linux_stable() {
    install_centos_stable || return 1
    return 0
}

install_red_hat_linux_git() {
    install_centos_git || return 1
    return 0
}

install_red_hat_enterprise_linux_stable() {
    install_red_hat_linux_stable || return 1
    return 0
}

install_red_hat_enterprise_linux_git() {
    install_red_hat_linux_git || return 1
    return 0
}

install_red_hat_enterprise_server_stable() {
    install_red_hat_linux_stable || return 1
    return 0
}

install_red_hat_enterprise_server_git() {
    install_red_hat_linux_git || return 1
    return 0
}

install_red_hat_linux_stable_post() {
    install_centos_stable_post || return 1
    return 0
}

install_red_hat_linux_restart_daemons() {
    install_centos_restart_daemons || return 1
    return 0
}

install_red_hat_linux_git_post() {
    install_centos_git_post || return 1
    return 0
}

install_red_hat_enterprise_linux_stable_post() {
    install_red_hat_linux_stable_post || return 1
    return 0
}

install_red_hat_enterprise_linux_restart_daemons() {
    install_red_hat_linux_restart_daemons || return 1
    return 0
}

install_red_hat_enterprise_linux_git_post() {
    install_red_hat_linux_git_post || return 1
    return 0
}

install_red_hat_enterprise_server_stable_post() {
    install_red_hat_linux_stable_post || return 1
    return 0
}

install_red_hat_enterprise_server_restart_daemons() {
    install_red_hat_linux_restart_daemons || return 1
    return 0
}

install_red_hat_enterprise_server_git_post() {
    install_red_hat_linux_git_post || return 1
    return 0
}
#
#   Ended RedHat Install Functions
#
##############################################################################

##############################################################################
#
#   Amazon Linux AMI Install Functions
#
install_amazon_linux_ami_deps() {
    # Acording to http://aws.amazon.com/amazon-linux-ami/faqs/#epel we should
    # enable the EPEL 6 repo
    if [ $CPU_ARCH_L = "i686" ]; then
        EPEL_ARCH="i386"
    else
        EPEL_ARCH=$CPU_ARCH_L
    fi
    rpm -Uvh --force http://mirrors.kernel.org/fedora-epel/6/${EPEL_ARCH}/epel-release-6-8.noarch.rpm || return 1
    yum -y update || return 1
    yum -y install PyYAML m2crypto python-crypto python-msgpack python-zmq \
        python-ordereddict python-jinja2 --enablerepo=epel || return 1
}

install_amazon_linux_ami_git_deps() {
    install_amazon_linux_ami_deps || return 1
    yum -y install git --enablerepo=epel || return 1

    __git_clone_and_checkout || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_amazon_linux_ami_stable() {
    install_centos_stable || return 1
    return 0
}

install_amazon_linux_ami_stable_post() {
    install_centos_stable_post || return 1
    return 0
}

install_amazon_linux_ami_restart_daemons() {
    install_centos_restart_daemons || return 1
    return 0
}

install_amazon_linux_ami_git() {
    install_centos_git || return 1
    return 0
}

install_amazon_linux_ami_git_post() {
    install_centos_git_post || return 1
    return 0
}
#
#   Ended Amazon Linux AMI Install Functions
#
##############################################################################

##############################################################################
#
#   Arch Install Functions
#
install_arch_linux_stable_deps() {
    grep '\[salt\]' /etc/pacman.conf >/dev/null 2>&1 || echo '[salt]
Include = /etc/pacman.d/salt.conf
' >> /etc/pacman.conf

    # Create a pacman .d directory so we can just override salt's
    # included configuration if needed
    [ -d /etc/pacman.d ] || mkdir -p /etc/pacman.d

    cat <<_eof > /etc/pacman.d/salt.conf
Server = http://intothesaltmine.org/archlinux
SigLevel = Optional TrustAll
_eof
}

install_arch_linux_git_deps() {
    install_arch_linux_stable_deps

    pacman -Sy --noconfirm pacman || return 1
    pacman -Sy --noconfirm git python2-crypto python2-distribute \
        python2-jinja python2-m2crypto python2-markupsafe python2-msgpack \
        python2-psutil python2-yaml python2-pyzmq zeromq || return 1

    __git_clone_and_checkout || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_arch_linux_stable() {
    pacman -Sy --noconfirm pacman || return 1
    pacman -Syu --noconfirm salt || return 1
    return 0
}

install_arch_linux_git() {
    python2 setup.py install || return 1
    return 0
}

install_arch_linux_post() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /usr/bin/systemctl ]; then
            # Using systemd
            /usr/bin/systemctl is-enabled salt-$fname.service > /dev/null 2>&1 || (
                /usr/bin/systemctl preset salt-$fname.service > /dev/null 2>&1 &&
                /usr/bin/systemctl enable salt-$fname.service > /dev/null 2>&1
            )
            sleep 0.1
            /usr/bin/systemctl daemon-reload
            continue
        fi

        # XXX: How do we enable old Arch init.d scripts?
    done
}

install_arch_linux_git_post() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /usr/bin/systemctl ]; then
            copyfile ${SALT_GIT_CHECKOUT_DIR}/pkg/rpm/salt-$fname.service /lib/systemd/system/salt-$fname.service

            /usr/bin/systemctl is-enabled salt-$fname.service > /dev/null 2>&1 || (
                /usr/bin/systemctl preset salt-$fname.service > /dev/null 2>&1 &&
                /usr/bin/systemctl enable salt-$fname.service > /dev/null 2>&1
            )
            sleep 0.1
            /usr/bin/systemctl daemon-reload
            continue
        fi

        # SysV init!?
        copyfile ${SALT_GIT_CHECKOUT_DIR}/pkg/rpm/salt-$fname /etc/rc.d/init.d/salt-$fname
        chmod +x /etc/rc.d/init.d/salt-$fname
    done
}

install_arch_linux_restart_daemons() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /usr/bin/systemctl ]; then
            /usr/bin/systemctl stop salt-$fname.service > /dev/null 2>&1
            /usr/bin/systemctl start salt-$fname.service
            continue
        fi
        /etc/rc.d/salt-$fname stop > /dev/null 2>&1
        /etc/rc.d/salt-$fname start
    done
}
#
#   Ended Arch Install Functions
#
##############################################################################

##############################################################################
#
#   FreeBSD Install Functions
#
__freebsd_get_packagesite() {
    if [ $CPU_ARCH_L = "amd64" ]; then
        BSD_ARCH="x86:64"
    elif [ $CPU_ARCH_L = "x86_64" ]; then
        BSD_ARCH="x86:64"
    elif [ $CPU_ARCH_L = "i386" ]; then
        BSD_ARCH="x86:32"
    elif [ $CPU_ARCH_L = "i686" ]; then
        BSD_ARCH="x86:32"
    fi

    # Since the variable might not be set, don't, momentarily treat it as a failure
    set +o nounset

    if [ "x${PACKAGESITE}" = "x" ]; then
        echowarn "The environment variable PACKAGESITE is not set."
        echowarn "The installation will, most likely fail since pkgbeta.freebsd.org does not yet contain any packages"
    fi
    BS_PACKAGESITE=${PACKAGESITE:-"http://pkgbeta.freebsd.org/freebsd:${DISTRO_MAJOR_VERSION}:${BSD_ARCH}/latest"}

    # Treat unset variables as errors once more
    set -o nounset
}

install_freebsd_9_stable_deps() {
    if [ ! -x /usr/local/sbin/pkg ]; then
        __freebsd_get_packagesite

        fetch "${BS_PACKAGESITE}/Latest/pkg.txz" || return 1
        tar xf ./pkg.txz -s ",/.*/,,g" "*/pkg-static" || return 1
        ./pkg-static add ./pkg.txz || return 1
        /usr/local/sbin/pkg2ng || return 1
        echo "PACKAGESITE: ${BS_PACKAGESITE}" > /usr/local/etc/pkg.conf
    fi

    /usr/local/sbin/pkg install -y swig || return 1

    # Lets set SALT_ETC_DIR to ports default
    SALT_ETC_DIR=${BS_SALT_ETC_DIR:-/usr/local/etc/salt}

    return 0
}

install_freebsd_git_deps() {
    if [ ! -x /usr/local/sbin/pkg ]; then
        __freebsd_get_packagesite

        fetch "${BS_PACKAGESITE}/Latest/pkg.txz" || return 1
        tar xf ./pkg.txz -s ",/.*/,,g" "*/pkg-static" || return 1
        ./pkg-static add ./pkg.txz || return 1
        /usr/local/sbin/pkg2ng || return 1
        echo "PACKAGESITE: ${BS_PACKAGESITE}" > /usr/local/etc/pkg.conf
    fi

    /usr/local/sbin/pkg install -y swig git || return 1

    __git_clone_and_checkout || return 1
    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_freebsd_9_stable() {
    /usr/local/sbin/pkg install -y sysutils/py-salt || return 1
    return 0
}

install_freebsd_git() {
    /usr/local/sbin/pkg install -y sysutils/py-salt || return 1
    /usr/local/sbin/pkg delete -y sysutils/py-salt || return 1

    /usr/local/bin/python setup.py install || return 1
    return 0
}

install_freebsd_9_stable_post() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        enable_string="salt_${fname}_enable=\"YES\""
        grep "$enable_string" /etc/rc.conf >/dev/null 2>&1
        [ $? -eq 1 ] && echo "$enable_string" >> /etc/rc.conf

        [ -f /usr/local/etc/salt/${fname}.sample ] && copyfile /usr/local/etc/salt/${fname}.sample /usr/local/etc/salt/${fname}

        if [ $fname = "minion" ] ; then
            grep "salt_minion_paths" /etc/rc.conf >/dev/null 2>&1
            [ $? -eq 1 ] && echo "salt_minion_paths=\"/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\"" >> /etc/rc.conf
        fi

    done
}

install_freebsd_git_post() {
    install_freebsd_9_stable_post || return 1
    return 0
}

install_freebsd_restart_daemons() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        service salt_$fname stop > /dev/null 2>&1
        service salt_$fname start
    done
}
#
#   Ended FreeBSD Install Functions
#
##############################################################################

##############################################################################
#
#   SmartOS Install Functions
#
install_smartos_deps() {
    check_pip_allowed
    echowarn "PyZMQ will be installed using pip"

    ZEROMQ_VERSION='3.2.2'
    pkgin -y in libtool-base autoconf automake libuuid gcc-compiler gmake \
        python27 py27-pip py27-setuptools py27-yaml py27-crypto swig || return 1
    [ -d zeromq-${ZEROMQ_VERSION} ] || (
        wget http://download.zeromq.org/zeromq-${ZEROMQ_VERSION}.tar.gz &&
        tar -xvf zeromq-${ZEROMQ_VERSION}.tar.gz
    )
    cd zeromq-${ZEROMQ_VERSION}
    ./configure || return 1
    make || return 1
    make install || return 1

    pip-2.7 install pyzmq || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        # Let's set the configuration directory to /tmp
        TEMP_CONFIG_DIR="/tmp"
        CONFIG_SALT_FUNC="config_salt"

        # Let's download, since they were not provided, the default configuration files
        if [ ! -f $SALT_ETC_DIR/minion ] && [ ! -f $TEMP_CONFIG_DIR/minion ]; then
            curl -sk -o $TEMP_CONFIG_DIR/minion -L \
                https://raw.github.com/saltstack/salt/develop/conf/minion || return 1
        fi
        if [ ! -f $SALT_ETC_DIR/master ] && [ ! -f $TEMP_CONFIG_DIR/master ]; then
            curl -sk -o $TEMP_CONFIG_DIR/master -L \
                https://raw.github.com/saltstack/salt/develop/conf/master || return 1
        fi
    fi

    return 0

}

install_smartos_git_deps() {
    install_smartos_deps || return 1
    pkgin -y in scmgit || return 1

    __git_clone_and_checkout || return 1
    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_smartos_stable() {
    USE_SETUPTOOLS=1 pip-2.7 install salt || return 1
    return 0
}

install_smartos_git() {
    # Use setuptools in order to also install dependencies
    USE_SETUPTOOLS=1 /opt/local/bin/python setup.py install || return 1
    return 0
}

install_smartos_post() {
    smf_dir="/opt/custom/smf"
    # Install manifest files if needed.
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        svcs network/salt-$fname > /dev/null 2>&1
        if [ $? -eq 1 ]; then
            if [ ! -f $TEMP_CONFIG_DIR/salt-$fname.xml ]; then
                curl -sk -o $TEMP_CONFIG_DIR/salt-$fname.xml -L https://raw.github.com/saltstack/salt/develop/pkg/smartos/salt-$fname.xml
            fi
            svccfg import $TEMP_CONFIG_DIR/salt-$fname.xml
            if [ "${VIRTUAL_TYPE}" = "global" ]; then
                if [ ! -d $smf_dir ]; then
                    mkdir -p $smf_dir && cp $TEMP_CONFIG_DIR/salt-$fname.xml $smf_dir/
                fi
                if [ ! -f $smf_dir/salt-$fname.xml ]; then
                    cp $TEMP_CONFIG_DIR/salt-$fname.xml $smf_dir/
                fi
            fi
        fi
    done
}

install_smartos_git_post() {
    smf_dir="/opt/custom/smf"
    # Install manifest files if needed.
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        svcs network/salt-$fname > /dev/null 2>&1
        if [ $? -eq 1 ]; then
            svccfg import ${SALT_GIT_CHECKOUT_DIR}/pkg/smartos/salt-$fname.xml
            if [ "${VIRTUAL_TYPE}" = "global" ]; then
                if [ ! -d $smf_dir ]; then
                    mkdir -p $smf_dir && cp ${SALT_GIT_CHECKOUT_DIR}/pkg/smartos/salt-$fname.xml $smf_dir/
                fi
                if [ ! -f $smf_dir/salt-$fname.xml ]; then
                    cp ${SALT_GIT_CHECKOUT_DIR}/pkg/smartos/salt-$fname.xml $smf_dir/
                fi
            fi
        fi
    done
}

install_smartos_restart_daemons() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        # Stop if running && Start service
        svcadm disable salt-$fname > /dev/null 2>&1
        svcadm enable salt-$fname
    done
}
#
#   Ended SmartOS Install Functions
#
##############################################################################

##############################################################################
#
#    openSUSE Install Functions.
#
install_opensuse_stable_deps() {
    DISTRO_REPO="openSUSE_${DISTRO_MAJOR_VERSION}.${DISTRO_MINOR_VERSION}"

    # Is the repository already known
    $(zypper repos | grep devel_languages_python >/dev/null 2>&1)
    if [ $? -eq 1 ]; then
        # zypper does not yet know nothing about devel_languages_python
        zypper --non-interactive addrepo --refresh \
            http://download.opensuse.org/repositories/devel:/languages:/python/${DISTRO_REPO}/devel:languages:python.repo || return 1
    fi

    zypper --gpg-auto-import-keys --non-interactive refresh
    exitcode=$?
    if [ $? -ne 0 ] && [ $? -ne 4 ]; then
        # If the exit code is not 0, and it's not 4(failed to update a
        # repository) return a failure. Otherwise continue.
        return 1
    fi
    zypper --non-interactive install --auto-agree-with-licenses libzmq3 python \
        python-Jinja2 python-M2Crypto python-PyYAML python-msgpack-python \
        python-pycrypto python-pyzmq || return 1
    return 0
}

install_opensuse_git_deps() {
    install_opensuse_stable_deps || return 1
    zypper --non-interactive install --auto-agree-with-licenses git || return 1

    __git_clone_and_checkout || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_opensuse_stable() {
    packages=""
    if [ $INSTALL_MINION -eq $BS_TRUE ]; then
        packages="${packages} salt-minion"
    fi
    if [ $INSTALL_MASTER -eq $BS_TRUE ]; then
        packages="${packages} salt-master"
    fi
    if [ $INSTALL_SYNDIC -eq $BS_TRUE ]; then
        packages="${packages} salt-syndic"
    fi
    zypper --non-interactive install --auto-agree-with-licenses $packages || return 1
    return 0
}

install_opensuse_git() {
    python setup.py install --prefix=/usr || return 1
    return 0
}

install_opensuse_stable_post() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /bin/systemctl ]; then
            systemctl is-enabled salt-$fname.service || (systemctl preset salt-$fname.service && systemctl enable salt-$fname.service)
            sleep 0.1
            systemctl daemon-reload
            continue
        fi

        /sbin/chkconfig --add salt-$fname
        /sbin/chkconfig salt-$fname on

    done
}

install_opensuse_git_post() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /bin/systemctl ]; then
            copyfile ${SALT_GIT_CHECKOUT_DIR}/pkg/salt-$fname.service /lib/systemd/system/salt-$fname.service
            continue
        fi

        copyfile ${SALT_GIT_CHECKOUT_DIR}/pkg/rpm/salt-$fname /etc/init.d/salt-$fname
        chmod +x /etc/init.d/salt-$fname

    done

    install_opensuse_stable_post
}

install_opensuse_restart_daemons() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ -f /bin/systemctl ]; then
            systemctl stop salt-$fname > /dev/null 2>&1
            systemctl start salt-$fname.service
            continue
        fi

        service salt-$fname stop > /dev/null 2>&1
        service salt-$fname start

    done
}
#
#   End of openSUSE Install Functions.
#
##############################################################################

##############################################################################
#
#    SuSE Install Functions.
#
install_suse_11_stable_deps() {
    SUSE_PATCHLEVEL=$(awk '/PATCHLEVEL/ {print $3}' /etc/SuSE-release )
    if [ "x${SUSE_PATCHLEVEL}" != "x" ]; then
        DISTRO_PATCHLEVEL="_SP${SUSE_PATCHLEVEL}"
    fi
    DISTRO_REPO="SLE_${DISTRO_MAJOR_VERSION}${DISTRO_PATCHLEVEL}"

    # Is the repository already known
    $(zypper repos | grep devel_languages_python >/dev/null 2>&1)
    if [ $? -eq 1 ]; then
        # zypper does not yet know nothing about devel_languages_python
        zypper --non-interactive addrepo --refresh \
            http://download.opensuse.org/repositories/devel:/languages:/python/${DISTRO_REPO}/devel:languages:python.repo || return 1
    fi

    zypper --gpg-auto-import-keys --non-interactive refresh || return 1
    if [ $SUSE_PATCHLEVEL -eq 1 ]; then
        check_pip_allowed
        echowarn "PyYaml will be installed using pip"
        zypper --non-interactive install --auto-agree-with-licenses libzmq3 python \
        python-Jinja2 'python-M2Crypto>=0.21' python-msgpack-python \
        python-pycrypto python-pyzmq python-pip || return 1
        # There's no python-PyYaml in SP1, let's install it using pip
        pip install PyYaml || return 1
    else
        zypper --non-interactive install --auto-agree-with-licenses libzmq3 python \
        python-Jinja2 'python-M2Crypto>=0.21' python-PyYAML python-msgpack-python \
        python-pycrypto python-pyzmq || return 1
    fi

    # PIP based installs need to copy configuration files "by hand".
    if [ $SUSE_PATCHLEVEL -eq 1 ]; then
        # Let's trigger config_salt()
        if [ "$TEMP_CONFIG_DIR" = "null" ]; then
            # Let's set the configuration directory to /tmp
            TEMP_CONFIG_DIR="/tmp"
            CONFIG_SALT_FUNC="config_salt"

            for fname in minion master syndic; do

                # Skip if not meant to be installed
                [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
                [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
                [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

                # Syndic uses the same configuration file as the master
                [ $fname = "syndic" ] && fname=master

                # Let's download, since they were not provided, the default configuration files
                if [ ! -f $SALT_ETC_DIR/$fname ] && [ ! -f $TEMP_CONFIG_DIR/$fname ]; then
                    curl -sk -o $TEMP_CONFIG_DIR/$fname -L \
                        https://raw.github.com/saltstack/salt/develop/conf/$fname || return 1
                fi
            done
        fi
    fi
    return 0
}

install_suse_11_git_deps() {
    install_suse_11_stable_deps || return 1
    zypper --non-interactive install --auto-agree-with-licenses git || return 1

    __git_clone_and_checkout || return 1

    # Let's trigger config_salt()
    if [ "$TEMP_CONFIG_DIR" = "null" ]; then
        TEMP_CONFIG_DIR="${SALT_GIT_CHECKOUT_DIR}/conf/"
        CONFIG_SALT_FUNC="config_salt"
    fi

    return 0
}

install_suse_11_stable() {
    if [ $SUSE_PATCHLEVEL -gt 1 ]; then
        install_opensuse_stable || return 1
    else
        # USE_SETUPTOOLS=1 To work around
        # error: option --single-version-externally-managed not recognized
        USE_SETUPTOOLS=1 pip install salt || return 1
    fi
    return 0
}

install_suse_11_git() {
    install_opensuse_git || return 1
    return 0
}

install_suse_11_stable_post() {
    if [ $SUSE_PATCHLEVEL -gt 1 ]; then
        install_opensuse_stable_post || return 1
    else
        for fname in minion master syndic; do

            # Skip if not meant to be installed
            [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
            [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
            [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

            if [ -f /bin/systemctl ]; then
                curl -k -L https://github.com/saltstack/salt/raw/develop/pkg/salt-$fname.service \
                    -o /lib/systemd/system/salt-$fname.service || return 1
                continue
            fi

            curl -k -L https://github.com/saltstack/salt/raw/develop/pkg/rpm/salt-$fname \
                -o /etc/init.d/salt-$fname || return 1
            chmod +x /etc/init.d/salt-$fname

        done
    fi
    return 0
}

install_suse_11_git_post() {
    install_opensuse_git_post || return 1
    return 0
}

install_suse_11_restart_daemons() {
    install_opensuse_restart_daemons || return 1
    return 0
}
#
#   End of SuSE Install Functions.
#
##############################################################################

##############################################################################
#
#    Gentoo Install Functions.
#

__gentoo_set_ackeys() {
    GENTOO_ACKEYS=""
    if [ ! -e /etc/portage/package.accept_keywords ]; then
        # This is technically bad, but probably for the best.
        # We'll assume that they want a file, as that's the default behaviour of portage.
        # If they really want a folder they'll need to handle that themselves.
        # We could use the ACCEPT_KEYWORDS environment variable, but that exceeds the minimum requires.
        GENTOO_ACKEYS="/etc/portage/package.accept_keywords"
    else
        if [ -f /etc/portage/package.accept_keywords ]; then
            GENTOO_ACKEYS="/etc/portage/package.accept_keywords"
        elif [ -d /etc/portage/package.accept_keywords ]; then
            GENTOO_ACKEYS="/etc/portage/package.accept_keywords/salt"
        else
            # We could use accept_keywords env, but this likely indicates a bigger problem.
            echo "Error: /etc/portage/package.accept_keywords is neither directory nor file."
            return 1
        fi
    fi
    return 0
}

__gentoo_pre_dep() {
    emerge --sync
    if [ ! -d /etc/portage ]; then
        mkdir /etc/portage
    fi
    __gentoo_set_ackeys || return 1
    cat >> ${GENTOO_ACKEYS} << _EOT
# Keywords added by bootstrap-salt
# required by salt, based on the 0.15.1 ebuild
>=dev-python/pycryptopp-0.6.0
>=dev-python/m2crypto-0.21.1-r1
>=dev-python/pyyaml-3.10-r1
>=dev-python/pyzmq-13.1.0
>=dev-python/msgpack-0.3.0
_EOT
}
__gentoo_post_dep() {
    cat >> ${GENTOO_ACKEYS} << _EOT
# End of bootstrap-salt keywords.
_EOT
    # the -o option asks it to emerge the deps but not the package.
    emerge -vo salt
}

install_gentoo_deps() {
    __gentoo_pre_dep || return 1
    echo "app-admin/salt" >> ${GENTOO_ACKEYS}
    __gentoo_post_dep
}

install_gentoo_git_deps() {
    emerge git
    __gentoo_pre_dep || return 1
    echo "=app-admin/salt-9999 **" >> ${GENTOO_ACKEYS}
    __gentoo_post_dep
}

install_gentoo_stable() {
    emerge -v salt || return 1
}

install_gentoo_git() {
    install_gentoo_stable || return 1
}

install_gentoo_post() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        rc-update add salt-$fname default
        /etc/init.d/salt-$fname start
    done
}

install_gentoo_restart_daemons() {
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        /etc/init.d/salt-$fname stop > /dev/null 2>&1
        /etc/init.d/salt-$fname start
    done
}

#
#   End of Gentoo Install Functions.
#
##############################################################################


##############################################################################
#
#   Default minion configuration function. Matches ANY distribution as long as
#   the -c options is passed.
#
config_salt() {
    # If the configuration directory is not passed, return
    [ "$TEMP_CONFIG_DIR" = "null" ] && return

    CONFIGURED_ANYTHING=$BS_FALSE

    PKI_DIR=$SALT_ETC_DIR/pki

    # Let's create the necessary directories
    [ -d $SALT_ETC_DIR ] || mkdir $SALT_ETC_DIR || return 1
    [ -d $PKI_DIR ] || mkdir -p $PKI_DIR && chmod 700 $PKI_DIR || return 1

    if [ $INSTALL_MINION -eq $BS_TRUE ]; then
        # Create the PKI directory
        [ -d $PKI_DIR/minion ] || mkdir -p $PKI_DIR/minion && chmod 700 $PKI_DIR/minion || return 1

        # Copy the minions configuration if found
        if [ -f "$TEMP_CONFIG_DIR/minion" ]; then
            mv "$TEMP_CONFIG_DIR/minion" $SALT_ETC_DIR || return 1
            CONFIGURED_ANYTHING=$BS_TRUE
        fi

        # Copy the minion's keys if found
        if [ -f "$TEMP_CONFIG_DIR/minion.pem" ]; then
            mv "$TEMP_CONFIG_DIR/minion.pem" $PKI_DIR/minion/ || return 1
            chmod 400 $PKI_DIR/minion/minion.pem || return 1
            CONFIGURED_ANYTHING=$BS_TRUE
        fi
        if [ -f "$TEMP_CONFIG_DIR/minion.pub" ]; then
            mv "$TEMP_CONFIG_DIR/minion.pub" $PKI_DIR/minion/ || return 1
            chmod 664 $PKI_DIR/minion/minion.pub || return 1
            CONFIGURED_ANYTHING=$BS_TRUE
        fi
    fi


    if [ $INSTALL_MASTER -eq $BS_TRUE ] || [ $INSTALL_SYNDIC -eq $BS_TRUE ]; then
        # Create the PKI directory
        [ -d $PKI_DIR/master ] || mkdir -p $PKI_DIR/master && chmod 700 $PKI_DIR/master || return 1

        # Copy the masters configuration if found
        if [ -f "$TEMP_CONFIG_DIR/master" ]; then
            mv "$TEMP_CONFIG_DIR/master" $SALT_ETC_DIR || return 1
            CONFIGURED_ANYTHING=$BS_TRUE
        fi

        # Copy the master's keys if found
        if [ -f "$TEMP_CONFIG_DIR/master.pem" ]; then
            mv "$TEMP_CONFIG_DIR/master.pem" $PKI_DIR/master/ || return 1
            chmod 400 $PKI_DIR/master/master.pem || return 1
            CONFIGURED_ANYTHING=$BS_TRUE
        fi
        if [ -f "$TEMP_CONFIG_DIR/master.pub" ]; then
            mv "$TEMP_CONFIG_DIR/master.pub" $PKI_DIR/master/ || return 1
            chmod 664 $PKI_DIR/master/master.pub || return 1
            CONFIGURED_ANYTHING=$BS_TRUE
        fi
    fi

    if [ $CONFIG_ONLY -eq $BS_TRUE ] && [ $CONFIGURED_ANYTHING -eq $BS_FALSE ]; then
        echowarn "No configuration or keys were copied over. No configuration was done!"
        exit 0
    fi
    return 0
}
#
#  Ended Default Configuration function
#
##############################################################################


##############################################################################
#
#   Default salt master minion keys pre-seed function. Matches ANY distribution
#   as long as the -k option is passed.
#
preseed_master() {
    # Create the PKI directory

    if [ $(ls $TEMP_KEYS_DIR | wc -l) -lt 1 ]; then
        echoerror "No minion keys were uploaded. Unable to pre-seed master"
        return 1
    fi

    SEED_DEST="$PKI_DIR/master/minions"
    [ -d $SEED_DEST ] || mkdir -p $SEED_DEST && chmod 700 $SEED_DEST || return 1

    for keyfile in $(ls $TEMP_KEYS_DIR); do
        src_keyfile="${TEMP_KEYS_DIR}/${keyfile}"
        dst_keyfile="${SEED_DEST}/${keyfile}"

        # If it's not a file, skip to the next
        [ ! -f $src_keyfile ] && continue

        movefile "$src_keyfile" "$dst_keyfile" || return 1
        chmod 664 $dst_keyfile || return 1
    done

    return 0
}
#
#  Ended Default Salt Master Pre-Seed minion keys function
#
##############################################################################


##############################################################################
#
#   This function checks if all of the installed daemons are running or not.
#
daemons_running() {
    FAILED_DAEMONS=0
    for fname in minion master syndic; do

        # Skip if not meant to be installed
        [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
        [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
        [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

        if [ "${DISTRO_NAME}" = "SmartOS" ]; then
            if [ "$(svcs -Ho STA salt-$fname)" != "ON" ]; then
                echoerror "salt-$fname was not found running"
                FAILED_DAEMONS=$(expr $FAILED_DAEMONS + 1)
            fi
        elif [ "x$(ps wwwaux | grep -v grep | grep salt-$fname)" = "x" ]; then
            echoerror "salt-$fname was not found running"
            FAILED_DAEMONS=$(expr $FAILED_DAEMONS + 1)
        fi
    done
    return $FAILED_DAEMONS
}
#
#  Ended daemons running check function
#
##############################################################################


#=============================================================================
# LET'S PROCEED WITH OUR INSTALLATION
#=============================================================================
# Let's get the dependencies install function
DEP_FUNC_NAMES="install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_${ITYPE}_deps"
DEP_FUNC_NAMES="$DEP_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_${ITYPE}_deps"
DEP_FUNC_NAMES="$DEP_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_deps"
DEP_FUNC_NAMES="$DEP_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_deps"
DEP_FUNC_NAMES="$DEP_FUNC_NAMES install_${DISTRO_NAME_L}_${ITYPE}_deps"
DEP_FUNC_NAMES="$DEP_FUNC_NAMES install_${DISTRO_NAME_L}_deps"

DEPS_INSTALL_FUNC="null"
for DEP_FUNC_NAME in $(__strip_duplicates $DEP_FUNC_NAMES); do
    if __function_defined $DEP_FUNC_NAME; then
        DEPS_INSTALL_FUNC=$DEP_FUNC_NAME
        break
    fi
done


# Let's get the minion config function
CONFIG_SALT_FUNC="null"
if [ "$TEMP_CONFIG_DIR" != "null" ]; then

    CONFIG_FUNC_NAMES="config_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_${ITYPE}_salt"
    CONFIG_FUNC_NAMES="$CONFIG_FUNC_NAMES config_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_${ITYPE}_salt"
    CONFIG_FUNC_NAMES="$CONFIG_FUNC_NAMES config_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_salt"
    CONFIG_FUNC_NAMES="$CONFIG_FUNC_NAMES config_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_salt"
    CONFIG_FUNC_NAMES="$CONFIG_FUNC_NAMES config_${DISTRO_NAME_L}_${ITYPE}_salt"
    CONFIG_FUNC_NAMES="$CONFIG_FUNC_NAMES config_${DISTRO_NAME_L}_salt"
    CONFIG_FUNC_NAMES="$CONFIG_FUNC_NAMES config_salt"

    for FUNC_NAME in $(__strip_duplicates $CONFIG_FUNC_NAMES); do
        if __function_defined $FUNC_NAME; then
            CONFIG_SALT_FUNC=$FUNC_NAME
            break
        fi
    done
fi


# Let's get the pre-seed master function
PRESEED_MASTER_FUNC="null"
if [ "$TEMP_CONFIG_DIR" != "null" ]; then

    PRESEED_FUNC_NAMES="preseed_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_${ITYPE}_master"
    PRESEED_FUNC_NAMES="$PRESEED_FUNC_NAMES preseed_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_${ITYPE}_master"
    PRESEED_FUNC_NAMES="$PRESEED_FUNC_NAMES preseed_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_master"
    PRESEED_FUNC_NAMES="$PRESEED_FUNC_NAMES preseed_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_master"
    PRESEED_FUNC_NAMES="$PRESEED_FUNC_NAMES preseed_${DISTRO_NAME_L}_${ITYPE}_master"
    PRESEED_FUNC_NAMES="$PRESEED_FUNC_NAMES preseed_${DISTRO_NAME_L}_master"
    PRESEED_FUNC_NAMES="$PRESEED_FUNC_NAMES preseed_master"

    for FUNC_NAME in $(__strip_duplicates $PRESEED_FUNC_NAMES); do
        if __function_defined $FUNC_NAME; then
            PRESEED_MASTER_FUNC=$FUNC_NAME
            break
        fi
    done
fi


# Let's get the install function
INSTALL_FUNC_NAMES="install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_${ITYPE}"
INSTALL_FUNC_NAMES="$INSTALL_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_${ITYPE}"
INSTALL_FUNC_NAMES="$INSTALL_FUNC_NAMES install_${DISTRO_NAME_L}_${ITYPE}"

INSTALL_FUNC="null"
for FUNC_NAME in $(__strip_duplicates $INSTALL_FUNC_NAMES); do
    if __function_defined $FUNC_NAME; then
        INSTALL_FUNC=$FUNC_NAME
        break
    fi
done


# Let's get the post install function
POST_FUNC_NAMES="install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_${ITYPE}_post"
POST_FUNC_NAMES="$POST_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_${ITYPE}_post"
POST_FUNC_NAMES="$POST_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_post"
POST_FUNC_NAMES="$POST_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_post"
POST_FUNC_NAMES="$POST_FUNC_NAMES install_${DISTRO_NAME_L}_${ITYPE}_post"
POST_FUNC_NAMES="$POST_FUNC_NAMES install_${DISTRO_NAME_L}_post"


POST_INSTALL_FUNC="null"
for FUNC_NAME in $(__strip_duplicates $POST_FUNC_NAMES); do
    if __function_defined $FUNC_NAME; then
        POST_INSTALL_FUNC=$FUNC_NAME
        break
    fi
done


# Let's get the start daemons install function
STARTDAEMONS_FUNC_NAMES="install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_${ITYPE}_restart_daemons"
STARTDAEMONS_FUNC_NAMES="$STARTDAEMONS_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_${ITYPE}_restart_daemons"
STARTDAEMONS_FUNC_NAMES="$STARTDAEMONS_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_restart_daemons"
STARTDAEMONS_FUNC_NAMES="$STARTDAEMONS_FUNC_NAMES install_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_restart_daemons"
STARTDAEMONS_FUNC_NAMES="$STARTDAEMONS_FUNC_NAMES install_${DISTRO_NAME_L}_${ITYPE}_restart_daemons"
STARTDAEMONS_FUNC_NAMES="$STARTDAEMONS_FUNC_NAMES install_${DISTRO_NAME_L}_restart_daemons"

STARTDAEMONS_INSTALL_FUNC="null"
for FUNC_NAME in $(__strip_duplicates $STARTDAEMONS_FUNC_NAMES); do
    if __function_defined $FUNC_NAME; then
        STARTDAEMONS_INSTALL_FUNC=$FUNC_NAME
        break
    fi
done


# Let's get the daemons running check function.
DAEMONS_RUNNING_FUNC="null"
DAEMONS_RUNNING_FUNC_NAMES="daemons_running_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}_${ITYPE}"
DAEMONS_RUNNING_FUNC_NAMES="$DAEMONS_RUNNING_FUNC_NAMES daemons_running_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}_${ITYPE}"
DAEMONS_RUNNING_FUNC_NAMES="$DAEMONS_RUNNING_FUNC_NAMES daemons_running_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}"
DAEMONS_RUNNING_FUNC_NAMES="$DAEMONS_RUNNING_FUNC_NAMES daemons_running_${DISTRO_NAME_L}${PREFIXED_DISTRO_MAJOR_VERSION}${PREFIXED_DISTRO_MINOR_VERSION}"
DAEMONS_RUNNING_FUNC_NAMES="$DAEMONS_RUNNING_FUNC_NAMES daemons_running_${DISTRO_NAME_L}_${ITYPE}"
DAEMONS_RUNNING_FUNC_NAMES="$DAEMONS_RUNNING_FUNC_NAMES daemons_running_${DISTRO_NAME_L}"
DAEMONS_RUNNING_FUNC_NAMES="$DAEMONS_RUNNING_FUNC_NAMES daemons_running"

for FUNC_NAME in $(__strip_duplicates $DAEMONS_RUNNING_FUNC_NAMES); do
    if __function_defined $FUNC_NAME; then
        DAEMONS_RUNNING_FUNC=$FUNC_NAME
        break
    fi
done



if [ $DEPS_INSTALL_FUNC = "null" ]; then
    echoerror "No dependencies installation function found. Exiting..."
    exit 1
fi

if [ $INSTALL_FUNC = "null" ]; then
    echoerror "No installation function found. Exiting..."
    exit 1
fi


# Install dependencies
if [ $CONFIG_ONLY -eq $BS_FALSE ]; then
    # Only execute function is not in config mode only
    echoinfo "Running ${DEPS_INSTALL_FUNC}()"
    $DEPS_INSTALL_FUNC
    if [ $? -ne 0 ]; then
        echoerror "Failed to run ${DEPS_INSTALL_FUNC}()!!!"
        exit 1
    fi
fi


# Configure Salt
if [ "$TEMP_CONFIG_DIR" != "null" ] && [ "$CONFIG_SALT_FUNC" != "null" ]; then
    echoinfo "Running ${CONFIG_SALT_FUNC}()"
    $CONFIG_SALT_FUNC
    if [ $? -ne 0 ]; then
        echoerror "Failed to run ${CONFIG_SALT_FUNC}()!!!"
        exit 1
    fi
fi


# Pre-Seed master keys
if [ "$TEMP_KEYS_DIR" != "null" ] && [ "$PRESEED_MASTER_FUNC" != "null" ]; then
    echoinfo "Running ${PRESEED_MASTER_FUNC}()"
    $PRESEED_MASTER_FUNC
    if [ $? -ne 0 ]; then
        echoerror "Failed to run ${PRESEED_MASTER_FUNC}()!!!"
        exit 1
    fi
fi


# Install Salt
if [ $CONFIG_ONLY -eq $BS_FALSE ]; then
    # Only execute function is not in config mode only
    echoinfo "Running ${INSTALL_FUNC}()"
    $INSTALL_FUNC
    if [ $? -ne 0 ]; then
        echoerror "Failed to run ${INSTALL_FUNC}()!!!"
        exit 1
    fi
fi


# Run any post install function, Only execute function is not in config mode only
if [ $CONFIG_ONLY -eq $BS_FALSE ] && [ "$POST_INSTALL_FUNC" != "null" ]; then
    echoinfo "Running ${POST_INSTALL_FUNC}()"
    $POST_INSTALL_FUNC
    if [ $? -ne 0 ]; then
        echoerror "Failed to run ${POST_INSTALL_FUNC}()!!!"
        exit 1
    fi
fi


# Run any start daemons function
if [ "$STARTDAEMONS_INSTALL_FUNC" != "null" ]; then
    echoinfo "Running ${STARTDAEMONS_INSTALL_FUNC}()"
    $STARTDAEMONS_INSTALL_FUNC
    if [ $? -ne 0 ]; then
        echoerror "Failed to run ${STARTDAEMONS_INSTALL_FUNC}()!!!"
        exit 1
    fi
fi

# Check if the installed daemons are running or not
if [ "$DAEMONS_RUNNING_FUNC" != "null" ]; then
    sleep 3  # Sleep a little bit to let daemons start
    echoinfo "Running ${DAEMONS_RUNNING_FUNC}()"
    $DAEMONS_RUNNING_FUNC
    if [ $? -ne 0 ]; then
        echoerror "Failed to run ${DAEMONS_RUNNING_FUNC}()!!!"

        for fname in minion master syndic; do
            # Skip if not meant to be installed
            [ $fname = "minion" ] && [ $INSTALL_MINION -eq $BS_FALSE ] && continue
            [ $fname = "master" ] && [ $INSTALL_MASTER -eq $BS_FALSE ] && continue
            [ $fname = "syndic" ] && [ $INSTALL_SYNDIC -eq $BS_FALSE ] && continue

            if [ $ECHO_DEBUG -eq $BS_FALSE ]; then
                echoerror "salt-$fname was not found running. Pass '-D' for additional debugging information..."
                continue
            fi


            [ ! $SALT_ETC_DIR/$fname ] && [ $fname != "syndic" ] && echodebug "$SALT_ETC_DIR/$fname does not exist"

            echodebug "Running salt-$fname by hand outputs: $(nohup salt-$fname -l debug)"

            [ ! -f /var/log/salt/$fname ] && echodebug "/var/log/salt/$fname does not exist. Can't cat its contents!" && continue

            echodebug "DEAMON LOGS for $fname:"
            echodebug "$(cat /var/log/salt/$fname)"
            echo
        done

        echodebug "Running Processes:"
        echodebug "$(ps auxwww)"

        exit 1
    fi
fi


# Done!
if [ $CONFIG_ONLY -eq $BS_FALSE ]; then
    echoinfo "Salt installed!"
else
    echoinfo "Salt configured"
fi
exit 0
