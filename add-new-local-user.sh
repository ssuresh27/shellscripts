# Make sure the script is being executed with superuser privileges.
LOG_FILE="/tmp/output.log"
if [[ "${UID}" -ne 0 ]]
then
    echo "Run the script as root user :-"
    exit 1

fi

# If the user doesn't supply at least one argument, then give them help.

if [[ "${#}" -lt 1 ]]
then
    echo "Usage ${0} : USER_NAME [USER_NAME].."
    exit 1

fi

# The first parameter is the user name.
USER_NAME=${1}
# The rest of the parameters are for the account comments.
#used shift to input argument array frwd (remove arg-0)
shift
#COMMENTS=${2}
COMMENTS="${@}"
# Generate a password.
PASSWORD=$(date +%s%N|sha256sum|head -c 32)
# Create the user with the password.
adduser -c "${COMMENTS}" -m ${USER_NAME} > ${LOG_FILE} 2>&1
# Check to see if the useradd command succeeded.
if [[ ${?} -ne 0 ]]
then
    echo "Error in creating user"
    exit 1
fi
# Set the password.
echo "${PASSWORD}"|passwd --stdin "${USER_NAME}" 1> "${LOG_FILE}" 2> "${LOG_FILE}"
# Check to see if the passwd command succeeded.
if [[ ${?} -ne 0 ]]
then
    echo "Error in setting user password"
    exit 1
fi

# Force password change on first login.
passwd -e "${USER_NAME}" &>> ${LOG_FILE} 
# Display the username, password, and the host where the user was created.

echo "${USER_NAME} : ${PASSWORD} created in ${HOSTNAME}"


# Informs the user if the account was not able to be created for some reason.  If the account is not created, the script is to return an exit status of 1.  
#All messages associated with this event will be displayed on standard error.

# Displays the username, password, and host where the account was created.  This way the help desk staff can copy the output of the script in order to easily deliver the information to the new account holder.

# Suppress the output from all other commands.

sudo cat ${LOG_FILE}