#!/bin/bash
## ======================================================
##  Manage the mongodb using mongo
##
## ======================================================

# --------------------- function (BEGIN) ----------------------

function die() {
    # call this function to exit the script
    # and print a customized message
    echo $@
    exit 1
}

function usage() {
    # print the help w/ the avaliable parameters to use.
cat << EOF

Usage: $0 [option]

Options:

    -h			    Show this message
    adduser		    Create a database credential
    dropuser		    Remove specific username from the database
    createdatabase	    Initialize a database
    dropdatabase	    Drop database and the associated files
    listdatabases           List databases per databaseinfra
    listcollections         List collections per database
    status/healthcheck	    It is a kind of healthcheck
    serverstatus	    Statistics data
    version                 MongoDB Server version

Environment variables required:
    INSTANCE_CONNECTION INSTANCE_USER INSTANCE_PASSWORD

EOF
exit 1
}

# ---------------------- function (END) ----------------------
# Global vars
# /dev/null, /dev/tty, 
LOGFILE='/dev/tty'
BASEDIR=$(dirname $0)
JSDIR="${BASEDIR}/js"
MONGO_DEFAULT_OPTS='--norc --quiet'

# mongo client exists and is executable?
mongo_client=$(which mongo)
[[ -x $mongo_client ]] || die "Mongo client ($mongo_client) does not exist in path $PATH or it is not executable."

# Check and set the required environment variables
if [[ -n $INSTANCE_CONNECTION || ${INSTANCE_USER+x} || ${INSTANCE_PASSWORD+x} ]]; then
    # if the user/password is blank, supress the user/pass parameters
    [[ -n ${INSTANCE_USER} ]] && INSTANCE_USER_OPTION="-u $INSTANCE_USER"
    [[ -n ${INSTANCE_PASSWORD+x} ]] && INSTANCE_PASSWORD_OPTION="-p $INSTANCE_PASSWORD"
else
    die "You must provide at least these environment variables:\
    INSTANCE_CONNECTION INSTANCE_USER INSTANCE_PASSWORD"
fi

# Main
exec_time=$(/bin/date "+[%d/%b/%Y %H:%M:%S]")
action=$1
case $action in
    adduser)
        [[ -z $CREDENTIAL_USER || -z $CREDENTIAL_PASSWORD || -z $DATABASE_NAME ]] && die "Missing the env variables: DATABASE_NAME CREDENTIAL_USER CREDENTIAL_PASSWORD"
        log_msg="Trying to add user $CREDENTIAL_USER on $INSTANCE_NAME/$DATABASE_NAME by $INSTANCE_USER."
        my_params="var db_name='$DATABASE_NAME', user_to_create='$CREDENTIAL_USER', user_password='$CREDENTIAL_PASSWORD'"
        my_js='addUser.js';;
    dropuser)
        [[ -z $CREDENTIAL_USER || -z $DATABASE_NAME ]] && die "Missing the env variable: DATABASE_NAME CREDENTIAL_USER"
        log_msg="Trying to remove user $CREDENTIAL_USER from $INSTANCE_NAME/$DATABASE_NAME by $INSTANCE_USER."
        my_params="var db_name='$DATABASE_NAME', user_to_remove='$CREDENTIAL_USER'"
        my_js='removeUser.js';;
    createdatabase)
        [[ -z $DATABASE_NAME ]] && die "Missing the env variable: DATABASE_NAME"
        log_msg="Trying to create the database $INSTANCE_NAME/$DATABASE_NAME by $INSTANCE_USER."
        my_params="var db_name='$DATABASE_NAME'"
        my_js='createDatabase.js';;
    dropdatabase)
        [[ -z $DATABASE_NAME ]] && die "Missing the env variable: DATABASE_NAME"
        log_msg="Trying to drop the database $INSTANCE_NAME/$DATABASE_NAME by $INSTANCE_USER."
        my_params="var db_name='$DATABASE_NAME'"
        my_js='dropDatabase.js';;
    status|healthcheck)
        log_msg="Checking the $INSTANCE_NAME healthy."
        my_js='healthCheck.js';;
    serverstatus)
        log_msg="Getting the statistics data from $INSTANCE_NAME."
        my_js='serverStatus.js';;
    listcollections)
        [[ -z $DATABASE_NAME ]] && die "Missing the env variable: DATABASE_NAME"
        log_msg="Listing all collections at $INSTANCE_NAME/$DATABASE_NAME."
        my_js='getCollectionNames.js';;
    listdatabases)
        log_msg="Listing all databases on $INSTANCE_NAME."
        my_js='showDatabases.js';;
    version)
        log_msg="Getting the mongoDB server version"
        my_js='getServerVersion.js';;
    *)
        usage;;
esac

js_file="${JSDIR}/${my_js}"
[[ -f $js_file ]] || die "The file ${js_file} does not exist, please check it."

# Action!
#ssl
[[ $verbose -eq 1 ]] && echo "$exec_time [DEBUG] [$$] Exec: $mongo_client $MONGO_DEFAULT_OPTS $INSTANCE_USER_OPTION --eval \"$my_params\" $INSTANCE_CONNECTION/admin $js_file" >> $LOGFILE 2>&1

output_cmd=$($mongo_client $MONGO_DEFAULT_OPTS $INSTANCE_USER_OPTION $INSTANCE_PASSWORD_OPTION --eval "$my_params" $INSTANCE_CONNECTION/admin $js_file)
exit_code=$?

[[ $verbose -eq 1 ]] && echo -ne "$exec_time [DEBUG] [$$] exit code: $exit_code, output: $output_cmd\n" >> $LOGFILE 2>&1
[[ $exit_code -eq 0 ]] && severity='INFO' || severity='ERROR'
echo "$exec_time [$severity] [$$] $log_msg" >> $LOGFILE 2>&1

# output to STDOUT & exit code
echo -ne "$output_cmd"
exit $exit_code
