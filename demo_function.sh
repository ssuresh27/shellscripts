#!/bin/bash

log() 
{
    #This function writes the message to var/log/messages and standard output
    local MESSAGE="${@}"
    if [[ "${VERBOSE}" = 'true' ]]
    then
        echo "${MESSAGE}"
    fi
    logger -t "${0}" "${MESSAGE}" #add tag to the O/P
    #Jun  1 14:54:17 shellclass ./demo_function.sh[4526]: Hello
    #Jun  1 14:55:01 shellclass ssundararajan02[4596]: Hello
    # logger "${MESSAGE}" #add username to o/p

}

backup_file () 
{
    #This function takes the backup of given file and resturs no zero exit status on failure
    local FILE="${1}"

    #Verify the file exists

    if [[ -f "${FILE}" ]]
    then
        #basename filename resturns filename
        #dirname filename resturns path of file
        local BACKUP_FILE="${HOME}/$(basename ${FILE}).$(date +%F-%N)"
        log "Backing up ${FILE} to ${BACKUP_FILE}"

        #Exit status of function will be the exist status of below cp command.

        cp -p "${FILE}" "${BACKUP_FILE}"
    else
        # log "Error in copying file"
        #the file doesnot exist, return non-zero exit status
        return 1
    fi

}

readonly VERBOSE='true' #Constant 

log 'Hello'
backup_file "${0}"
#Check the restun code status
if [[ "${?}" -eq 0 ]]
then
    log 'File backup sccess'
else
    log 'File backup failed'
    exit 1
fi