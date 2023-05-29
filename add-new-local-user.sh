# Make sure the script is being executed with superuser privileges.

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
COMMENTS=${2}
# Generate a password.
PASSWORD=$(date +%s%N|sha256sum|head -c 32)
# Create the user with the password.
adduser -c ${COMMENTS} -m ${USER_NAME}
# Check to see if the useradd command succeeded.
if [[ ${?} -ne 0 ]]
then
    echo "Error in creating user"
    exit 1
fi
# Set the password.
echo "${PASSWORD}"|passwd --stdin "${USER_NAME}"
# Check to see if the passwd command succeeded.
if [[ ${?} -ne 0 ]]
then
    echo "Error in setting user password"
    exit 1
fi

# Force password change on first login.
passwd -e "${USER_NAME}"
# Display the username, password, and the host where the user was created.

echo "${USER_NAME} : ${PASSWORD} created in ${HOSTNAME}"
