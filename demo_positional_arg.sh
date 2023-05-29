#!/bin/bash
#Display what user typed on command line #Postiton 0 represend script name
echo "You have execute the script ${0}"

#Display base and directory name of the script executed or argument
#basename - strip directory and suffix from filenames
#dirname - strip last component from file name
echo "You have executed $(basename ${0}) from path $(dirname ${0})"

#Display How many arguments are passed
NO_OF_PARAMETERS=${#}
echo "You have passed ${NO_OF_PARAMETERS} in command line"

#Make sure one username/argument is passed

if [[ "${NO_OF_PARAMETERS}" -lt 1 ]]
then
    echo "Usage : ${0} USER_NAME [USER_NAME]..."
    exit 1
fi

#For loop to display random password for users

for USER in "${@}"
do
    PASSWORD="$(date +%s%N|sha256sum|head -c16)"
    echo "${USER} : ${PASSWORD}"
done