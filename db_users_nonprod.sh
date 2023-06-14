#!/bin/bash
##################################################################
#Script Name	:   db_users_nonprod.sh 
#Description	:   Created for L1/L2 to automate Argus READ-ONLY User Creation and password reset
#Args           :   None                                                                                       
#Author       	:   Suresh Sundararajan
#Email         	:   Suresh.sundararajan@gilead.com
#Created        :   06-June-2023
#Usage          :   ./db_users_nonprod.sh [-ac] [-l PASSWORD_ENGTH] [-f USER_DDL.sql]
#Usage          :   ./db_users_nonprod.sh -a -c -l 12 -f USER_DDL.sql]
###################################################################

#Check the script is executed as oracle OS user
EXCLUDE_LIST='ARGS8PRD,ARGI8PRD,ARGM8PRD,ARGS8VAL,ARGI8VAL,ARGM8VAL'
USER_NAME='oracle'
PASSWORD_LENGTH=21
USER_DDL_SCRIPT="${HOME}/.create_user.sql"
readonly DDL_DML_LIST='create|drop|insert|update|delete'
readonly AUDIT_FILE="${HOME}/.${HOSTNAME}.${ORACLE_SID}.aud"
AUDIT='true'

if [[ "$(id -un)" != "${USER_NAME}" ]]
then
    echo "The script should be executed as OS user '${USER_NAME}'" >&2
    exit 1
fi

#Check if ORACLE_SID parameter is set and pmon is running

if [ -z "${ORACLE_SID}" ]
then
    echo 'ORACLE_SID is not, use . oraenv and set the oracle database environment variables' >&2
    exit 1

fi


if [[ "$(ps -ef|grep ora_pmon_${ORACLE_SID}|grep -v grep|wc -l)" -ne 1 ]]
then
    echo "Database instance ${ORACLE_SID} is not running " >&2
    exit 1

fi


#Writes the message to STDOUT
log()
{
    DATE=$(date +%F.%H:%M:%S)
    local MESSAGE="${*}"
    echo -e "${DATE} :-\t\t\t${MESSAGE}"
}

#audit
audit()
{
    DATE=$(date +%F.%H:%M:%S)
    local MESSAGE="${*}"
    echo -e "${DATE} : ${MESSAGE}" >> ${AUDIT_FILE}
}

#Display the usage for options
usage() 
{
    echo "Usage : ${0} [-ac][-l LENGTH ]:[-f FILENAME.sql ]" >&2
    echo 'Argus Non-PROD Read-only User Automation.' >&2
    echo '  -a                  Disable tracking of unlock,create,reset activity' >&2
    echo '  -c                  Validate user DDL script for any DDL/DML GRANTS.' >&2
    echo '  -l LENGTH           Specify the password length.' >&2
    echo '  -f FILENAME.sql     Specify the user ddl script name' >&2
    exit 1
}


#Read input option parameters
while getopts "acl:f:" arg; do
  case $arg in
    a)
        AUDIT='false'
        ;;
    c)
        VALIDE_DDL='true'
        ;;
    l)
        log ''
        log ''  
        log 'Changing default password length'
        log "From ${PASSWORD_LENGTH} to new length ${OPTARG}"
        PASSWORD_LENGTH=${OPTARG}
        ;;
    f)
        if [[ -z $(dirname "${OPTARG}"|sed '/^.$/d') ]]
        then
            FILENAME="${PWD}/${OPTARG}"
        else
            FILENAME="${OPTARG}"
        fi        
        log ''
        log ''  
        log 'Changing user creation script'
        log "From ${USER_DDL_SCRIPT} to location ${FILENAME}"
        USER_DDL_SCRIPT=${FILENAME}
      ;;
    *)
        log ''
        log ''  
        log "Invalid option"
        usage
        ;;
  esac
done

# Remove options from Arguments
shift "$(( OPTIND - 1 ))"


#Display usage of script
initial_choice()
{
    echo -e '\n\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    echo -e 'The script is indented to use only in Non-PROD Environment by DBAs'
    echo -e '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    echo -e '\nChoose from the below options'
    echo -e '\t1. Check account status \t\t2. Account Unlock'
    echo -e '\t3. Reset user password \t\t\t4. Create read-only user'
    echo -e '\t5. Check user privilege \t\t6. List Non-default DB users account status'
    echo -e '\t7. Generate SYSTEM password'
    echo -e '\t8. Press 8 or Q for quit'
    echo ''
}
choice()
{
    # echo -e '\n\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    # echo -e 'The script is indented to use only in Non-PROD Environment by DBAs'
    # echo -e '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    # echo -e '\nChoose from the below options'
    # echo -e '\t1. Check account status \t\t2. Account Unlock'
    # echo -e '\t3. Reset user password \t\t\t4. Create read-only user'
    # echo -e '\t5. Check user privilege \t\t6. List Non-default DB users account status'
    # echo -e '\t7. Press 7 or Q for quit'
    # echo ''
    echo "${HOSTNAME}@${ORACLE_SID} >"
    read -p 'Enter your choice : ' CHOICE
    echo ''

}

#Read schema name to perform the database operation
read_schema_name()
{

    echo ''
    read -p "Enter the schema name :- " NAME
    SCHEMA_NAME="${NAME^^}"
    echo ''
}

#Generate Random password for give length
random_password()
{
    PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9#[](){}=-' | fold -w ${PASSWORD_LENGTH} | head -n 1)
}

#Execute the script as per given argument
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
#Replacing with return instead of exit
# if [[ "${?}" -ne 0 ]] 
# then
#     # echo 'Error in running SQL' >&2
#     log 'Error in running SQL' >&2
#     # exit 1
#     return 1
# elif [[ $(echo "${DB_RESULT}"|grep ORA-|wc -l) -gt 0 ]]
# then
#     # echo "SQL completed with ORA- errror" >&2
#     log "SQL completed with ORA- errror" >&2
#     log "${DB_RESULT}" >&2
#     # exit 1
#     return 1
# fi

# #if success return 0
# # return ${?}


#Old with exit code
if [[ "${?}" -ne 0 ]] 
then
    # echo 'Error in running SQL' >&2
    log 'Error in running SQL' 
    exit 1
elif [[ $(echo "${DB_RESULT}"|grep ORA-|wc -l) -gt 0 ]]
then
    # echo "SQL completed with ORA- errror" >&2
    log "SQL completed with ORA- errror" 
    log "${DB_RESULT}" 
    exit 1
fi

# echo 
# echo "${DB_RESULT}"
# echo
# echo
}


#Listing all the non-default users in DB
list_all_users()
{
    log ''
    log ''
    log '-------------'
    log 'List All User'
    log '-------------'
    
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


#Check if schema/user exists in DB
check_user_exists()
{
    read_schema_name
    SQL="select username from dba_users where username='${SCHEMA_NAME}';"
    execute_sql
    if [[ -z ${DB_RESULT} ]]
    then 
        # echo "${SCHEMA_NAME} not exists in DB"
        log ''
        log "User ${SCHEMA_NAME} not exists in ${HOSTNAME}@${ORACLE_SID} DB "
        DB_RESULT=1
    else
        # echo "${SCHEMA_NAME} exists in DB"
        log ''
        log "User/Schema  ${SCHEMA_NAME} exists in ${HOSTNAME}@${ORACLE_SID} DB"
        DB_RESULT=0
    fi
}


#Check user account status
check_user_account_status()
{
    check_user_exists
    if [[ "${DB_RESULT}" -eq 1 ]]
    then
        # exit 1
        log 'User not exists, cannot be verified'
        ACCOUNT_STATUS=''
        return #replacing with return to skip breaking the script
    fi
    SQL="select username,'|',account_status,'|',lock_date,'|',last_login,'|',profile,'|',default_tablespace,'|',temporary_tablespace from dba_users where username='${SCHEMA_NAME}';"
    execute_sql
    # echo "${DB_RESULT}"
    ACCOUNT_STATUS=$(echo "${DB_RESULT}"|awk -F '|' '{print $2}'|tr -d " ")
    # echo "${ACCOUNT_STATUS}"
    log ''
    log "Account Name\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $1}')"
    log "Account Status\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $2}'|tr -d " ")"
    log "Lock Date\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $3}')"
    log "Last login\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $4}')"
    log "Profile \t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $5}')"
    log "Default Tablespace\t:\t$(echo $DB_RESULT|awk -F '|' '{print $6}')"
    log "Temp Tablespace\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $7}')"

    # echo "${SCHEMA_NAME} account is ${ACCOUNT_STATUS} state"
    # log ''
    # log "${SCHEMA_NAME}"
    # log ''
    # log "Account is ${ACCOUNT_STATUS} state"
    # log ''
    # echo "${DB_RESULT}"
    # MAX_LOOP=$(echo ${DB_RESULT}|awk '{ print NF}')
    # # echo "${MAX_LOOP}"
    # for i in $(seq ${MAX_LOOP})
    # do
    #     echo "${TEMP_SQL}" |cut -d ',' -f $i
    #     echo "${DB_RESULT}" |cut -d '|' -f $i
    # done
    
}

#Unlock user account
unlock_user()
{
    # check_user_exists
    check_user_account_status
    local STATUS=$(echo $ACCOUNT_STATUS|tr -d " ")
    if [[ "${STATUS}" = 'OPEN' ]]
    then
        # echo "${SCHEMA_NAME} account is already open"
        # echo "${DB_RESULT}"
        log ''
        log "${SCHEMA_NAME} account is already in  open state"
        log ''
        # log "${DB_RESULT}"
        # exit 0
        return #replacing with return to skip breaking the script
    else
        SQL="alter user ${SCHEMA_NAME} account unlock;"
        execute_sql
        log ''
        log "${SCHEMA_NAME}  Account unlocked"
        log ''
        audit "${SCHEMA_NAME}  Account unlocked"
        # echo "${DB_RESULT}"
        # check_user_account_status

    fi

}


#Reseting user password
reset_password()
{
    check_user_exists
    if [[ "${DB_RESULT}" -eq 1 ]]
    then
        # exit 1
        return #replacing with return to skip breaking the script
    fi
    random_password
    # echo "${PASSWORD}"
    SQL="alter user ${SCHEMA_NAME} identified by \"${PASSWORD}\" account unlock;"
    execute_sql
    # echo "${SCHEMA_NAME} account is ${ACCOUNT_STATUS} state"
    # log ''
    # log "${SCHEMA_NAME}"
    log ''
    log 'Please share the below new password with user'
    log ''
    log "Login\t\t\t:\t${SCHEMA_NAME}/${PASSWORD}"
    log ''
    log ''
    log "Hostname\t\t:\t ${HOSTNAME}"
    log "PORT\t\t\t:\t 1521"
    log "SERVICE_NAME\t\t:\t ${ORACLE_SID}"
    audit "${SCHEMA_NAME} Password reset"
    # log ''
    # log "New password is ${PASSWORD}"
    # log ''
}

#Reseting SYSTEM password
system_password()
{
    # check_user_exists
    # if [[ "${DB_RESULT}" -eq 1 ]]
    # then
    #     # exit 1
    #     return #replacing with return to skip breaking the script
    # fi
    log 'Creating new password for SYSTEM'
    random_password
    # echo "${PASSWORD}"
    SQL="alter user SYSTEM identified by \"${PASSWORD}\" account unlock;"
    execute_sql
    # echo "${SCHEMA_NAME} account is ${ACCOUNT_STATUS} state"
    # log ''
    # log "${SCHEMA_NAME}"
    log ''
    log 'Please share the below new password with user'
    log ''
    log "SYSTEM/${PASSWORD}"
    log ''
    audit "SYSTEM Password reset"
}

#List user privilges excluding ROLE Privs
list_privs()
{
    check_user_account_status
    log ''
    log 'List User Privileges'
    SQL="col GRANTEE for a20
    col owner for a15
    col table_name for a50
    col role for a30
    col granted_role for a30
    col username for a30
    select ' ' from dual;
    select '\t\t\t\t\t Role Granted :- ' from dual;
    select '\t\t\t\t\t --------------- ' from dual;
    select '\t\t\t\t',GRANTED_ROLE,ADMIN_OPTION from dba_role_privs where GRANTEE  in ('${SCHEMA_NAME}') order by 1;
    select ' ' from dual;
    select '\t\t\t\t\t SYS Privs granted to Users :- ' from dual;
    select '\t\t\t\t\t -----------------------------' from dual;
    select '\t\t\t\t',GRANTEE,PRIVILEGE,ADMIN_OPTION  from dba_sys_privs where GRANTEE in ('${SCHEMA_NAME}') and GRANTEE  not in ('SYS','SYSTEM','DBA') order by 1,2;
    select ' ' from dual;
    select '\t\t\t\t\t Tab Privs granted to User :- ' from dual;
    select '\t\t\t\t\t ---------------------------- ' from dual;
    select '\t\t\t\t',GRANTEE,OWNER,TABLE_NAME, PRIVILEGE ,GRANTABLE from dba_tab_privs where GRANTEE in ('${SCHEMA_NAME}') and GRANTEE  not in ('SYS','SYSTEM','DBA') and TABLE_NAME  not like 'BIN$%' order by 1,2,3;
        select ' ' from dual;
    select '\t\t\t\t\t Table space Quotas  :- ' from dual;
    select '\t\t\t\t\t ---------------------- ' from dual;
    select '\t\t\t\t',ts.* from dba_ts_quotas ts where username in ('${SCHEMA_NAME}');"

    execute_sql
    log ''
    echo -e "${DB_RESULT}"
    log ''

    # echo -e "${DB_RESULT}" |awk '{print $1, $2}'
    # echo "${SCHEMA_NAME} account is ${ACCOUNT_STATUS} state"
    # log ''
    # log "${SCHEMA_NAME}"
    # log ''
    # log 'Roles Granted'
    # log ''
    # # log "Schema ${SCHEMA_NAME} new password is ${PASSWORD}"
    # log "${DB_RESULT}"
    # log ''
}


#Check create script exits
check_audit_ddl_script()
{
    if [[ ! -e "${AUDIT_FILE}" ]]
    then
        touch "${AUDIT_FILE}"
        if [[ "${?}" -ne 0 ]]
        then
            log  "${AUDIT_FILE} Not exists and error in creating"
            exit 1
        fi

    fi

    if [[ "${AUDIT}" = 'true' ]]
    then
        log ''
        log "Checking if audit file ${AUDIT_FILE} exits and writable"
        if [[ ! -w "${AUDIT_FILE}" ]]
        then
            echo "Error in writing to ${AUDIT_FILE}" >&2
            echo 'Please check  the file permission or restart with -a to skip audit'
            exit 1
        fi
        log ''
        log "Audit file ${AUDIT_FILE} exits and writable"
    fi

    log ''
    log "Checking if script ${USER_DDL_SCRIPT} exits and readable"
    if [[ ! -r "${USER_DDL_SCRIPT}" ]]
    then
        log ''
        log "${USER_DDL_SCRIPT} not exists or not readable"
        log 'Please check the permission of the file'
        exit 1
    fi
    log ''
    log "Script ${USER_DDL_SCRIPT} exits and readable"
}

#Validate DDL/DML Grants
validate_script()
{
    log ''
    log "Validating if script ${USER_DDL_SCRIPT} has DDL/DML GRANTS"
    WRITE_GRANT=$(cat ${USER_DDL_SCRIPT}|grep -viE '^#|^--|CREATE USER|CREATE SESSION'|grep -Ei "${DDL_DML_LIST}"|wc -l)
    # echo ${WRITE_GRANT}
    if [[ "${WRITE_GRANT}"  -gt 0 ]]
    then
        log "The Script ${USER_DDL_SCRIPT} has DML/DDL permission, please check"
        log 'Existing the script'
        exit 1
    fi
    log ''
    log "Script ${USER_DDL_SCRIPT} has only READ-ONLY GRANTS"
    
}

#Create Read-only user with script
create_ro_user()
{
    check_user_exists
    local CREATE_USER="${USER_DDL_SCRIPT}"
    if [[ "${DB_RESULT}" -eq 0 ]]
    then
        # exit 1
        log 'User already exists, cannot be created'
        return #replacing with return to skip breaking the script
    fi
    random_password
    SQL=$(cat ${CREATE_USER}|grep -v '^#\|^--'|sed "s/USER_NAME/${SCHEMA_NAME}/g"|sed "s/PASSWD/${PASSWORD}/g")
    log ''
    log ''
    echo -e "${SQL}"
    log ''
    execute_sql
    SQL="select username,'|',account_status,'|',lock_date,'|',last_login,'|',profile,'|',default_tablespace,'|',temporary_tablespace from dba_users where username='${SCHEMA_NAME}';"
    execute_sql
    # echo "${DB_RESULT}"
    ACCOUNT_STATUS=$(echo "${DB_RESULT}"|awk -F '|' '{print $2}'|tr -d " ")
    # echo "${ACCOUNT_STATUS}"
    log ''
    log "Account Name\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $1}')"
    log "Account Status\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $2}'|tr -d " ")"
    log "Lock Date\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $3}')"
    log "Last login\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $4}')"
    log "Profile \t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $5}')"
    log "Default Tablespace\t:\t$(echo $DB_RESULT|awk -F '|' '{print $6}')"
    log "Temp Tablespace\t\t:\t$(echo $DB_RESULT|awk -F '|' '{print $7}')"
    log ''
    log 'Please share the below new password with user'
    log ''
    log "Login\t\t\t:\t${SCHEMA_NAME}/${PASSWORD}"
    log ''
    log ''
    log "Hostname\t\t:\t ${HOSTNAME}"
    log "PORT\t\t\t:\t 1521"
    log "SERVICE_NAME\t\t:\t ${ORACLE_SID}"
    audit "${SCHEMA_NAME} Created"
}


#Main
#Check if this script executed in VAL & PROD

if [[ $(echo "${EXCLUDE_LIST}" |grep "${ORACLE_SID}"|wc -l) -gt 0 ]]
then
    echo 'The script is intended to execute only in Non-PROD DB, please check the DB environment'  >&2
    exit 1

fi

#Check the files exists
check_audit_ddl_script

#Validate for WRITER DML/DDL Permission
if [[ "${VALIDE_DDL}" = 'true' ]]
then
    validate_script
fi


#Listing users
list_all_users
#Run the script until QUIT=y
QUIT='n'

#Ask for DBA choice
initial_choice
while [[ "${QUIT}"  != 'y' ]]
do
choice
# echo "${CHOICE}"
case "${CHOICE}" in
    
    1)
        log 'Check user account status'
        check_user_account_status
        ;;
    2)
        log 'Unlock user'
        unlock_user
        ;;
    3) 
        log 'Reset user password'
        reset_password
        ;;
    4) 
        log 'Create read-only user'
        create_ro_user
        ;;
    5)
        log 'Check user privileges'
        list_privs
        ;;
    6)
        list_all_users
        ;;
    7)
        log 'Generate SYSTEM password'
        system_password
        ;;
    8|q|Q)
        log 'Quiting the script'
        QUIT='y'
        ;;
    ?)
        echo 'Invalid choice, please choose from the below list' >&2
        initial_choice
        # exit 1
        ;;

esac
done