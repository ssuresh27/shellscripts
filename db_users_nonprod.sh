#!/bin/bash
#Script to check the users status, generate new password and create new read-only user

#Check the user is executed as oracle OS user

USER_NAME='oracle'
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


if [[ "$(ps -ef|grep ora_pmon_${ORACLE_SID}|grep -v grep|wc -l)" -ne 1 ]]
then
    echo "Database instance ${ORACLE_SID} is not running " >&2
    exit 1

fi

#Display usage of script

choice()
{
    echo -e '\n\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    echo -e 'The script is indented to use only in Non-PROD Environment by DBAs'
    echo -e '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    echo -e '\nChoose from the below options'
    echo -e '\t1. Unlock User \t\t\t\t2. Reset user password'
    echo -e '\t3. Check account status \t\t4. Create read-only user'
    echo -e '\t5. Check user privilege \t\t6. List Non-default DB users account status'
    echo -e '\t\t\t 7. Press 7 or Q for quit'
    echo ''
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
execute_sql()
{
    local SCRIPT="${SQL}"
    # echo "${SCRIPT}"
    DB_RESULT=$(sqlplus -s "/as sysdba" <<EOF
    set pages 0 lin 1000 feed off ver off head off echo off;
    set term off
    $SCRIPT
    exit
EOF
)

#Verify last step status
if [[ "${?}" -ne 0 ]] 
then
    echo 'Error in running SQL' >&2
    exit 1
elif [[ $(echo "${DB_RESULT}"|grep ORA-|wc -l) -gt 0 ]]
then
    echo "SQL completed with ORA- errror" >&2
    echo "${DB_RESULT}" >&2
    exit 1
fi

# echo 
# echo "${DB_RESULT}"
# echo
# echo
}


list_all_users()
{
    SQL="col username for a30
    col account_status for a20
    col profile for a30
    col limit for a30
    col DEFAULT_TABLESPACE for a25
    col TEMPORARY_TABLESPACE for a25
    col LAST_LOGIN for a40
    alter session set nls_date_format='DD-MON-YYYY';
    select '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++' from dual;
    select 'USERNAME                       | ACCOUNT_STATUS       |     PROFILE                    |CREATED_DATE |             |             | LAST_LOIN                    ' from dual;
    select '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++' from dual;
    select username,'|',account_status,'|',profile,'|',created,'|',lock_date,'|',expiry_date,'|',last_login from dba_users where ORACLE_MAINTAINED='N' and username not in ('ADMIN','RDSADMIN','RDS_DATAGUARD') order by 1;
    select '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++' from dual;
    "
    # SQL="select username,'|',account_status,'|',profile,'|',created,'|',lock_date,'|',expiry_date,'|',last_login,'\n' from dba_users where ORACLE_MAINTAINED='N' and username not in ('ADMIN','RDSADMIN','RDS_DATAGUARD') order by 1;"
    # local DB_RESULT=$(execute_sql)
    execute_sql
    echo -e "${DB_RESULT}"
    # while read -r line <$(echo -e "${DB_RESULT}")
    # do
    #     echo "${line}"
    # done
    # |awk -F '|'  '{print $1"\t\t"$2}'
    # for r in ${DB_RESULT}
    # do
    #     echo -e "${r}\t"
    # done
    
}

check_user_exists()
{
    SQL="select username from dba_users where username='${SCHEMA_NAME}';"
    execute_sql
    if [[ -z ${DB_RESULT} ]]
    then 
        echo "${SCHEMA_NAME} not exists in DB"
        DB_RESULT=1
    else
        echo "${SCHEMA_NAME} exists in DB"
        DB_RESULT=0
    fi
}


check_user_account_status()
{
    check_user_exists
    if [[ "${DB_RESULT}" -eq 1 ]]
    then
        # exit 1
        return #replacing with return to skip breaking the script
    fi
    SQL="select username,account_status,lock_date,last_login from dba_users where username='${SCHEMA_NAME}';"
    execute_sql
    ACCOUNT_STATUS=$(echo "${DB_RESULT}"|awk '{print $2}')
    echo "${SCHEMA_NAME} account is ${ACCOUNT_STATUS} state"

}


unlock_user()
{
    # check_user_exists
    check_user_account_status
    if [[ "${ACCOUNT_STATUS}" = 'OPEN' ]]
    then
        echo "${SCHEMA_NAME} account is already open"
        echo "${DB_RESULT}"
        # exit 0
        return #replacing with return to skip breaking the script
    else
        SQL="alter user ${SCHEMA_NAME} account unlock;"
        execute_sql
        # echo "${DB_RESULT}"
        check_user_account_status

    fi

}

QUIT='n'
list_all_users
while [[ "${QUIT}"  != 'y' ]]
do
choice
# echo "${CHOICE}"
# echo "${SSH_CLIENT}"
case "${CHOICE}" in
    
    1)
        echo -e '\nUlock user:'
        read_schema_name
        unlock_user
        ;;
    2)
        echo 'Reset user password'
        read_schema_name
        echo "${SCHEMA_NAME}"
        ;;
    3) 
        echo -e '\nCheck user account status'
        read_schema_name
        check_user_account_status
        # echo "${SCHEMA_NAME}"
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
    6)
        list_all_users
        ;;
    7|q)
        QUIT='y'
        ;;
    ?)
        echo 'Invalid chooice' >&2
        exit 1
        ;;

esac
done