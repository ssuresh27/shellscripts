#!/bin/bash

case "${1}" in 
    start) 
        echo "starting"
        ;;
    stop|stop?) 
        echo "Stopping" 
        ;;
    *) 
        echo "Not a valid"
        ;;
esac

# In the following description, a pattern-list is a list of one or more patterns separated by  a  |.
#        Composite patterns may be formed using one or more of the following sub-patterns:

#               ?(pattern-list)
#                      Matches zero or one occurrence of the given patterns
#               *(pattern-list)
#                      Matches zero or more occurrences of the given patterns
#               +(pattern-list)
#                      Matches one or more occurrences of the given patterns
#               @(pattern-list)
#                      Matches one of the given patterns
#               !(pattern-list)
#                      Matches anything except one of the given patterns