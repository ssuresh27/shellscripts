#!/bin/bash
#Script to check the users status, generate new password and create new read-only user

#Check the user is executed as oracle OS user

USER_NAME='ssundararajan02'
PASSWORD_LENGTH=21

if [[ "$(id -un)" != "${USER_NAME}" ]]
then
    echo "The script should be executed as OS user '${USER_NAME}'" >&2
    exit 1
fi

#Check if ORACLE_SID parameter is set and pmon is running

if [ -z "${ORACLE_SID}" ]
then
    echo 'ORACLE_SID is not, use . oraenv and set the oracle datbase envrionment variables' >&2
    exit 1

fi


# if [[ "$(ps -ef|grep ${ORACLE_SID}|grep -v grep|wc -l)" -ne 1 ]]
# then
#     echo "Database instance ${ORACLE_SID} is not running " >&2
#     exit 1

# fi

#Display usage of script

choice()
{
    echo -e '\n\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    echo -e 'The script is indented to use only in Non-PROD Environment by DBAs'
    echo -e '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    echo -e '\nChoose from the below options'
    echo -e '\t1. Unlock User \t\t\t\t2. Reset user password'
    echo -e '\t3. Check account status \t\t4. Create read-only user'
    echo -e '\t5. Check user privilege'
    read -p 'Enter your choice : ' CHOICE

}

#Read schema name to perform the database operation
read_schema_name()
{
    read -p "Enter the schema name :- " SCHEMA_NAME
}

#Generate Random password
random_password()
{
    PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9#[](){}=-' | fold -w ${PASSWORD_LENGTH} | head -n 1)
}

#Unlock a database user
unlock_user()
{
    sqlplus -s "/as sysdba" << EOF >>/dev/null
    select "${USERNAME}" from dba_users;
}

choice
# echo "${CHOICE}"
# echo "${SSH_CLIENT}"
case "${CHOICE}" in
    
    1)
        echo 'Ulock user:'
        read_schema_name
        random_password
        echo -e "${SCHEMA_NAME} \t ${PASSWORD}"
        ;;
    2)
        echo 'Reset user password'
        read_schema_name
        echo "${SCHEMA_NAME}"
        ;;
    3) 
        echo 'Check user account status'
        read_schema_name
        echo "${SCHEMA_NAME}"
        ;;
    4) 
        echo 'Create read-only user'
        read_schema_name
        echo "${SCHEMA_NAME}"
        ;;
    5)
        echo 'Check user privilege'
        echo "${SCHEMA_NAME}"
        ;;
    ?)
        echo 'Invalid chooice' >&2
        exit 1
        ;;


esac