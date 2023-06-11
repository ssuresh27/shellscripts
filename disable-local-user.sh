#!/bin/bash

# Check the script is executed as root or sudo privilege

if [[ "${UID}" -ne 0 ]]
then
    echo 'Execute the script as root or with sudo privilege' >&2
    exit 1

fi

#Display usage on invalid output
usage()
{
    echo "Usage : ${0} [-dra] USERNAME [USERNAME]" >&2
    echo 'Delete / disable the USERNAME' >&2
    echo '  -d      delete the account instead of disable/expire the account' >&2
    echo '  -r      delete all the files in USER Home Directory ' >&2
    echo '  -a      Archive the user home directory file in /archive' >&2
    exit 1

}


log() {
    local MESSAGE="${@}"
    echo "$(date +%F-%R-%N) : ${MESSAGE}"
}


#Read user input
while getopts dra OPTIONS
do
    case ${OPTIONS} in
    d)
        log 'Delete the user'
        DELETE_USER='true'
        ;;
    a) 
        log 'Archiving the user files'
        ARCHIVE='true'
        ;;
    r) 
        log 'Deleting the user and files'
        REMOVE_OPTION='-r'
        ;;
    *) 
        log 'Invalid input'
        usage
        ;;

    esac

done

#Remove option list leaving Arguments
shift "$(( OPTIND -1 ))"

ARCHIVE_DIR='/archive'
#check the Arguments passed (USERNAME List)

if [[ "${#}" -lt 1 ]]
then
    usage
    exit 1

fi

#Read USER list and take action
for USER in "${@}"
do
    log "Processing user ${USER}"
    USERID=$(id -u ${USER})
    if [[ "${USERID}" -lt 1000 ]]
    then
        echo "Refusing to remove the ${USER} account with UID ${USERID}." >&2
        exit 1
    fi
    if [[ "${ARCHIVE}" = 'true' ]]
    then
        USER_HOME="/home/${USER}"
        ARCHIVE_FILE="${ARCHIVE_DIR}/${USER}_$(date +%F_+H%M%S).tar.gz"
        if [[ -d ${USER_HOME} ]]
        then
            echo "Archiving ${USER_HOME} to ${ARCHIVE_FILE}"
            tar -cvf "${ARCHIVE_FILE}" "${USER_HOME}" > /dev/null
            if [[ $? -ne 0 ]]
            then
                Echo 'Error in archiving' >&2
                exit 1
            fi
        else

            echo "${USER_HOME} does not exists" >&2
            exit 1

        fi
    
    fi

    if [[ "${USDELETE_USER}"='true' ]]
    then
        userdel "${REMOVE_OPTION}" "${USER}" > /dev/null

        if [[ "${?}" -ne 0 ]]
        then
            echo "User ${USER} was not deleted" >&2
            exit 1
        fi
        echo "User ${USER} deleted sccessfully"
    else
        chage -E 0 "${USER}"
        if [[ "${?}" -ne 0 ]]
        then
            echo "The account ${USER} was NOT disabled." >&2
            exit 1
        fi
        echo "The account ${USER} was disabled."
    fi

done



exit 0