#!/bin/sh
#
# Download the bootstrap script and execute it.

# Move an existing bootstrap-salt.sh out of the way, if present.
rename_old_bootstrap()
{
    if [ -s "${BOOTSTRAP_LOCAL}" -a -e "${BOOTSTRAP_LOCAL_OLD}" ]
    then
        mv -f "${BOOTSTRAP_LOCAL}" "${BOOTSTRAP_LOCAL_OLD}"
        echo "${BOOTSTRAP_LOCAL_OLD}"
        return 0
    fi
    # We didn't end up needing the temp file.
    rm -f "${BOOTSTRAP_LOCAL_OLD}"
    return 1
}

# Remove bad/old bootstrap script(s) and temp CA file.
cleanup()
{
    if [ -s "${BOOTSTRAP_LOCAL}" ]
    then
        # Remove the old version.
        rm -f "${BOOTSTRAP_LOCAL_OLD}"
    elif [ -s "${BOOTSTRAP_LOCAL_OLD}" ]
    then
        # Since only the old version exists, restore it.
        # This shouldn't happen (see old_ver).
        mv -f "${BOOTSTRAP_LOCAL_OLD}" "${BOOTSTRAP_LOCAL}"
    else
        # Both old and new are missing or empty. Remove both.
        rm -f "${BOOTSTRAP_LOCAL_OLD}" "${BOOTSTRAP_LOCAL}"
    fi

    if [ ${KEEP_BOOTSTRAP} -eq 0 ]
    then
        rm -f "${BOOTSTRAP_LOCAL}"
    fi

    # Remove the CA certificate and this script from the guest
    # unconditionally.
    rm -f "${GITHUB_CA_FILE}" "${0}"
}

# Restore a valid old copy of the bootstrap script, if present.
old_ver()
{
    if [ -s "${BOOTSTRAP_LOCAL_OLD}" ]
    then
        echo "Notice: Failed fetching ${BOOTSTRAP_LOCAL##*/}"
        echo "Old version located locally. Using that instead."
        mv -f "${BOOTSTRAP_LOCAL_OLD}" "${BOOTSTRAP_LOCAL}"
    else
        return 1
    fi
}

# Generate and execute a requested download command.
get_dl_cmd()
{
    dl_util="${1}"
    use_cert=${2}
    cert_args=""

    case "${dl_util}" in
        curl)
            if [ ${use_cert} -ne 0 ]
            then
                cert_args="--cacert ${GITHUB_CA_FILE}"
            fi
            ${dl_util} ${cert_args} -s -L -o "${BOOTSTRAP_LOCAL}" \
                       "${BOOTSTRAP_URL}"
            ;;
        fetch)
            if [ ${use_cert} -ne 0 ]
            then
                cert_args="--ca-cert=${GITHUB_CA_FILE}"
            fi
            ${dl_util} ${cert_args} -o "${BOOTSTRAP_LOCAL}" \
                        "${BOOTSTRAP_URL}"
            ;;
        old_ver)
            if [ ${use_cert} -ne 0 ]
            then
                # Certificate check not applicable here.
                return 1
            else
                old_ver
            fi
            ;;
        python)
            if [ ${use_cert} -ne 0 ]
            then
                # Python version currently unimplemented.
                return 1
            fi
            ${dl_util} -c \
                       "import urllib; urllib.urlretrieve('${BOOTSTRAP_URL}', '${BOOTSTRAP_LOCAL}')" \
                       2>/dev/null
            ;;
        wget)
            if [ ${use_cert} -ne 0 ]
            then
                cert_args="--ca-certificate=${GITHUB_CA_FILE}"
            fi
            ${dl_util} ${cert_args} -q -O "${BOOTSTRAP_LOCAL}" \
                        "${BOOTSTRAP_URL}"
            ;;
        *)
            {
                echo "Unhandled download command"
                exit 1
            } 1>&2
            ;;
    esac
}

# Trigger download command calls.
exec_dl_cmd()
{
    dl_util="${1}"
    use_cert=${2-0}
    dl_cmd_result=0

    get_dl_cmd "${dl_util}" ${use_cert}
    dl_cmd_result=${?}

    if [ ${dl_cmd_result} -eq 0 -a -s "${BOOTSTRAP_LOCAL}" ]
    then
        return 0
    fi

    if [ ${dl_cmd_result} -ne 0 -a ${use_cert} -eq 0 ]
    then
        # The dl_util command exists but failed. Let's try
        # again, this time using the GITHUB_CA cert.
        exec_dl_cmd ${dl_util} 1
        return ${?}
    fi

    return 1
}

# Fetch the required Salt bootstrap script.
fetch_bootstrap_sh()
{
    for dl_util in "${@}"
    do
        if [ -n "$(which ${dl_util})" ] || [ "${dl_util}" = "old_ver" ]
        then
            exec_dl_cmd ${dl_util}
            if [ ${?} -eq 0 ]
            then
                break
            fi
        fi
    done

    if [ ! -s "${BOOTSTRAP_LOCAL}" ]
    then
        {
            echo "Failed to locate a command to download ${BOOTSTRAP_LOCAL##*/}."
            echo "Try adding curl, fetch or wget to your \$PATH and try again."
            exit 1
        } 1>&2
    fi
}

# Execute the Salt bootstrap script.
run_bootstrap_sh()
{
    if [ -s "${BOOTSTRAP_LOCAL}" ]
    then
        sh "${BOOTSTRAP_LOCAL}" "$@" || { KEEP_BOOTSTRAP=1 && exit 1 ; }
    else
        exit 1
    fi
}

# Begin execution.

BOOTSTRAP_URL="https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh"
BOOTSTRAP_LOCAL="${HOME}/bootstrap-salt.sh"
BOOTSTRAP_LOCAL_OLD="$(mktemp /tmp/bootstrap-salt-old.XXXXXXXX)"
GITHUB_CA_FILE="$(mktemp /tmp/bootstrap-salt-ca.XXXXXXXX)"
KEEP_BOOTSTRAP=0
cat <<EOF >>"${GITHUB_CA_FILE}"
-----BEGIN CERTIFICATE-----
MIIDxTCCAq2gAwIBAgIQAqxcJmoLQJuPC3nyrkYldzANBgkqhkiG9w0BAQUFADBs
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5j
ZSBFViBSb290IENBMB4XDTA2MTExMDAwMDAwMFoXDTMxMTExMDAwMDAwMFowbDEL
MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3
LmRpZ2ljZXJ0LmNvbTErMCkGA1UEAxMiRGlnaUNlcnQgSGlnaCBBc3N1cmFuY2Ug
RVYgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMbM5XPm
+9S75S0tMqbf5YE/yc0lSbZxKsPVlDRnogocsF9ppkCxxLeyj9CYpKlBWTrT3JTW
PNt0OKRKzE0lgvdKpVMSOO7zSW1xkX5jtqumX8OkhPhPYlG++MXs2ziS4wblCJEM
xChBVfvLWokVfnHoNb9Ncgk9vjo4UFt3MRuNs8ckRZqnrG0AFFoEt7oT61EKmEFB
Ik5lYYeBQVCmeVyJ3hlKV9Uu5l0cUyx+mM0aBhakaHPQNAQTXKFx01p8VdteZOE3
hzBWBOURtCmAEvF5OYiiAhF8J2a3iLd48soKqDirCmTCv2ZdlYTBoSUeh10aUAsg
EsxBu24LUTi4S8sCAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQF
MAMBAf8wHQYDVR0OBBYEFLE+w2kD+L9HAdSYJhoIAu9jZCvDMB8GA1UdIwQYMBaA
FLE+w2kD+L9HAdSYJhoIAu9jZCvDMA0GCSqGSIb3DQEBBQUAA4IBAQAcGgaX3Nec
nzyIZgYIVyHbIUf4KmeqvxgydkAQV8GK83rZEWWONfqe/EW1ntlMMUu4kehDLI6z
eM7b41N5cdblIZQB2lWHmiRk9opmzN6cN82oNLFpmyPInngiK3BD41VHMWEZ71jF
hS9OMPagMRYjyOfiZRYzy78aG6A9+MpeizGLYAiJLQwGXFK3xPkKmNEVX58Svnw2
Yzi9RKR/5CYrCsSXaQ3pjOLAEFe4yHYSkVXySGnYvCoCWw9E1CAx2/S6cCZdkGCe
vEsXCS+0yx5DaMkHJ8HSXPfqIbloEpw8nL+e/IBcm2PN7EeqJSdnoDfzAIJ9VNep
+OkuE6N36B9K
-----END CERTIFICATE-----
EOF

trap cleanup EXIT

rename_old_bootstrap
fetch_bootstrap_sh curl fetch python wget old_ver
run_bootstrap_sh "${@}"
