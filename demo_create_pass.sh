#!/bin/bash

#Random number using RANDOM shell function
PASSWORD="${RANDOM}"
echo $PASSWORD

#With Muliple RANDOM

PASSWORD="${RANDOM}${RANDOM}${RANDOM}"
echo "${PASSWORD}"

#Using date 
PASSWORD="$(date +%s%N)"
echo "${PASSWORD}"

#Using date and RANDOM
PASSWORD="$(date +%s%N${RANDOM})"
echo "${PASSWORD}"

#Using checksum

PASSWORD="$(date +%s%N${RANDOM}|sha256sum|head -c 32)"
echo "${PASSWORD}"

#Using special chars

SPECIAL_CHAR='!@#$%^&*()_+{}[]'
SPECIAL_CHAR_STRING=$(echo $SPECIAL_CHAR|fold -w2|shuf|head -n 1)
# echo "${SPECIAL_CHAR_STRING}"


PASSWORD="$(date +%s%N${RANDOM}|sha256sum|head -c 32)${SPECIAL_CHAR_STRING}"
echo "${PASSWORD}"

