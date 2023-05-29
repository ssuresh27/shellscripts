# Make sure the script is being executed with superuser privileges.

if [[ "${UID}" -ne 0 ]]
then
    echo "Restart the script as root or with sudo privilege to create user"
    exit 1
fi

# Get the username (login).
read -p "Enter the user name to create : " UNAME

# Get the real name (contents for the description field).
read -p "Enter the user full name : " COMMENT

# Get the password.
read -p "Enter the ${UNAME} password : " PASSWORD

# Create the user with the password.
useradd -c "${COMMENT}" ${UNAME}

# Check to see if the useradd command succeeded.
if [[ "${?}" -ne 0 ]]
then
    echo "Error in creating user ${UNAME} and status code ${?}"
    exit 1
fi

# Set the password.
echo $PASSWORD | passwd --stdin ${UNAME}

# Check to see if the passwd command succeeded.
if [[ "${?}" -ne 0 ]]
then
    echo "Error in setting user ${UNAME} password and status code ${?}"
    exit 1
fi

# Force password change on first login.
passwd -e ${UNAME}

# Display the username, password, and the host where the user was created.

echo "Following user is created in ${HOSTNAME} and type ${HOSTTYPE}"
echo "Username : ${UNAME}"
echo "Password : ${PASSWORD}"

exit 0
