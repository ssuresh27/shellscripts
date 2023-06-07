#!/bin/bash

#Script using getopts shell options #getopts: getopts optstring name [arg ...]
#Generating password

usage() {
    echo "Usage : ${0} [-vs]:[-l LENGTH ]" >&2
    echo 'Generate a random password.' >&2
    echo '  -l LENGTH  Specify the password length.' >&2
    echo '  -s         Append a special character to the password.' >&2
    echo '  -v         Increase verbosity.' >&2
    exit 1
}

log() {
    local MESSAGE="${@}"
    echo "$(date +%F-%R-%N) : ${MESSAGE}"
}

#Set default length for password
LENGTH=32

#Read input arguments using getopts
while getopts vl:s OPTIONS #l: requires argument 
do
    case ${OPTIONS} in
    v) 
        VERBOSE='true' 
        log 'Verbose mode ON.'
        ;;
    l)
        LENGTH="${OPTARG}"
        ;;
    s)
        USE_SPECIAL_CHAR='true'
        ;;
    ?)
        usage
        ;;
    esac
done

display_input() {
    echo
    echo "No of inputs ${#}"
    echo "All the input arguments ${@}"
    echo "Argument Zero ${0}"
    echo "Argument One ${1}"
    echo "Argument Two ${2}"
    echo "Argument Three ${3}"
    echo
}

if [[ "${VERBOSE}" = 'true' ]]
then
    log "Generating password"
fi

PASSWORD=$(date +%s%N|sha256sum|head -c ${LENGTH})

if [[ "${USE_SPECIAL_CHAR}" = 'true' ]]
then
    SPECIAL_CHAR='!@#$%^&*()_+{}[]'
    SPECIAL_CHAR_STRING=$(echo $SPECIAL_CHAR|fold -w1|shuf|head -n 1)
    PASSWORD="${PASSWORD}${SPECIAL_CHAR_STRING}"
fi

display_input "${@}"
shift "$(( OPTIND - 1 ))"
display_input "${@}"

echo 
echo "Password is :"
echo 
echo "${PASSWORD}"

log "Done"
exit 1