#!/bin/bash

###########################################################################################
# Policy Playlist V3.2
# version 3.2
#
# This script will run a policy from another policy, and you can order it like a playlist
# Jamfs default behaviour is to run policies under the same trigger in an alphanumeric order.
# This is not beneficial when things are dependent on other things
# If you want to run a bunch of policies in a row, this is an easy way to connect them in a single policy.
# Jamf Binary
JAMF_BINARY="/usr/local/bin/jamf"

# Jamf Policy Trigger
# Jamf Policy ID Array
JAMF_POLICY_ID="$4"
LOG_FILE=$5
TEST_POLICY_ID="inventory &,dock365 "
# Log location Vars
if [[ -z ${10} ]]; then
    LOG_FILE="/usr/local/JamfConnectAssets/policy_playlist.log"
    # if folder doesn't exist, create folder
    if [[ ! -d "/usr/local/JamfConnectAssets" ]]; then
        mkdir "/usr/local/JamfConnectAssets"
    fi
fi
# If log file doesn't yet exist, create it
if [[ ! -f $LOG_FILE ]]; then
    touch "$LOG_FILE"
fi
# Logging functions
function RUN_LOG() {
    echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - ${1}" | tee -a "${LOG_FILE}"
}

# Policy Call functions
function JAMF_CALL() {
    $JAMF_BINARY policy -$2 $1 $3
    echo "executing $JAMF_BINARY policy -$2 $1 $3 "
}

# TEST_POLICY_ID="https://COMPANY.jamfcloud.com/policies.html?id=94&O=l"

# Vars for Setting up the policy chain and running it, or using the test id's when not provided
if [[ -z $4 ]]; then
    RUN_LOG "Checking for policy ID's in the script"
    if [[ -z "$TEST_POLICY_ID" ]]; then
        RUN_LOG "Error: No policy ID's provided, please check your configuration"
        exit 1
    else
        RUN_LOG "Policy ID's found in the script"
        JAMF_POLICY_ID="$TEST_POLICY_ID"
    fi
fi

function GET_TYPES {
    RUN_LOG "getting types for ${1}"
    if [[ ${1} = "" ]]; then
        TYPE="EMPTY"
    elif [[ ${1} == [0-9]* ]] && [[ ! $1 == *"&"* ]]; then
        TYPE="ID"
    elif [[ ${1} == [0-9]* ]] && [[ ${1} == *"&"* ]] && [[ ! ${1} == "https://"* ]]; then
        TYPE="ID_AMP"
    elif [[ ${1} == [A-Za-z0-9]* ]] && [[ ${1} == *"&"* ]] && [[ ! ${1} == "https://"* ]]; then
        TYPE="STRING_AMP"
    elif [[ ${1} == [A-Za-z0-9]* ]] && [[ ! ${1} == "https://"* ]]; then
        TYPE="STRING"
    elif [[ ${1} == "https://"* ]] && [[ $1 == *"&" ]]; then
        TYPE="URL_AMP"
    elif [[ ${1} == "https://"* ]]; then
        TYPE="URL"
    else
        RUN_LOG "ERRROR, no type found"
        exit 1
    fi
}
function EXTRACT_ID_FROM_URL() {
    CURRENT_URL="${1}"
    CURRENT_POLICY_ID=$(echo "$CURRENT_URL" | awk -F'=' '{print $2}' | awk -F'&' '{print $1}')
    echo "extracted ID: $CURRENT_POLICY_ID"
}
function CALL_POLICY {
    CURRENT_POLICY_ID=${1}
    case $TYPE in
    "ID")
        RUN_LOG "Running Policy ID: $CURRENT_POLICY_ID"
        JAMF_CALL "$CURRENT_POLICY_ID" "id"
        RUN_LOG "You can check the logs for the status at:$POLICY_ID_URL"
        ;;
    "ID_AMP")
        CURRENT_POLICY_ID=${CURRENT_POLICY_ID//&/ }
        RUN_LOG "Running Policy ID: $CURRENT_POLICY_ID"
        EXTRACT_ID_FROM_URL "$CURRENT_POLICY_ID"
        JAMF_CALL "$CURRENT_POLICY_ID" "id" "&"
        POLICY_ID_URL="https://COMPANY.jamfcloud.com/policies.html?id=$CURRENT_POLICY_ID&O=l"
        RUN_LOG "Policy is running in the background and you can check the logs for the status at:$POLICY_ID_URL"
        ;;
    "STRING_AMP")
        CURRENT_POLICY_ID=${CURRENT_POLICY_ID//&/ }
        RUN_LOG "Running Policy event : $CURRENT_POLICY_ID"
        JAMF_CALL "$CURRENT_POLICY_ID" "event" "&"
        ;;
    "STRING")
        RUN_LOG "Running Policy ID: $CURRENT_POLICY_ID"
        JAMF_CALL "$CURRENT_POLICY_ID" "event"
        ;;
    "URL_AMP")
        RUN_LOG "extracting ID from $CURRENT_POLICY_ID"
        EXTRACT_ID_FROM_URL $CURRENT_POLICY_ID
        RUN_LOG "Running Policy ID: $CURRENT_POLICY_ID"
        JAMF_CALL "$CURRENT_POLICY_ID" "id" "&"
        ;;
    "URL")
        RUN_LOG "Extracting ID from $CURRENT_POLICY_ID"
        EXTRACT_ID_FROM_URL $CURRENT_POLICY_ID
        RUN_LOG "Running Policy ID: $CURRENT_POLICY_ID"
        JAMF_CALL "$CURRENT_POLICY_ID" "id"
        ;;
    *)
        RUN_LOG "ERROR: No type found"
        exit 1
        ;;
    esac
}
function SPLIT_AT_COMMAS_INTO_ARRAY {
    if [[ ${1} == *","* ]]; then
        IFS=',' read -r -a JAMF_POLICY_ID_ARRAY <<<"${1}"
        RUN_LOG "Jamf Policy ID Array: ${JAMF_POLICY_ID_ARRAY[@]}"
        for i in "${JAMF_POLICY_ID_ARRAY[@]}"; do
            RUN_LOG "Policy ID: $i"
            GET_TYPES $i
            RUN_LOG "Type: $TYPE \n"
            CALL_POLICY $i
        done
    else
        RUN_LOG "Jamf Policy ID Array: ${1}"
        GET_TYPES $1
        RUN_LOG "Type: $TYPE"
        CALL_POLICY $1
    fi
}

function GENERAL_LOGIC {
    if [[ $JAMF_POLICY_ID == *" "* ]]; then
        RUN_LOG "Jamf Policy ID before Cleanp $JAMF_POLICY_ID"
        RUN_LOG "Negative space found, removin it"
        JAMF_POLICY_ID=${JAMF_POLICY_ID// /}
    fi
    RUN_LOG "Jamf Policy ID's: $JAMF_POLICY_ID"
    # Split the string into an array
    RUN_LOG "Splitting into an array"
    SPLIT_AT_COMMAS_INTO_ARRAY $JAMF_POLICY_ID
}
GENERAL_LOGIC
