#!/bin/bash
# version 3.0
###########################################################################################
# Jamf Default Parameters:                                                                #
# Parameters 1-3 are predefined as Mount Point, Computer name, and Username respectively   #
# Jamf Assignable Parameters start at 4 and go on to 10                                   #
# ======================================================================================= #
##########################################  HOW TO USE ####################################
# 1. Create a new policy in Jamf Pro                                                      #
# 2. Attach this script to the policy                                                     #
# 3. Add the following parameters to the policy                                           #
#      Parameter 4: Array of ID's                                                         #
#      Parameter 5: Include Notify StatusBar?                                             #
################################### Start Param Assignment ################################

# Jamf Policy Chainer. This script will run a policy from another policy, and you can order it after or before other actions.
# If you want to run a bunch of policies in a row, this is an easy way to connect them in a single policy.
# Jamf Binary
JAMF_BINARY="/usr/local/jamf/bin/jamf"
NOTIFY_LOG="/var/tmp/depnotify.log"
OUTPUT_YELLOW="\033[1;33m"
NC='\033[0m'
# Jamf Policy Trigger
# Jamf Policy ID Array
JAMF_POLICY_ID="$4"
# Flag for DEPNOTIFY or JamfNotify Progress bar.
JAMF_NOTIFY_FLAGS="$5"
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi
DETERMINATE_COUNTER=0
# NOTE: HAVE TO REMEMBER TO VALIDATE THAT A SINGLE POLICY CAN INCLUDE A WORD AND A NUMBER.
## Test Flags ##
# JAMF_POLICY_ID="94,  https://COMPANY.jamfcloud.com/policies.html?id=94&O=l"

# ======================================================================================= #
if [[ -z $4 ]]; then
    if [[ -z "$JAMF_POLICY_ID" ]]; then
        echo "Error: No policy ID's provided, please check your configuration"
        # exit 1
    fi
fi
if [[ -z "$5" ]]; then
    if [[ -z "$JAMF_NOTIFY_FLAGS" ]]; then
        JAMF_NOTIFY_FLAGS="false"
    fi
fi

## TEST DATA.

# ======================================================================================= #
case $5 in
"true" | "TRUE" | "True" | "yes" | "YES" | "Yes" | "y" | "Y")
    JAMF_NOTIFY_FLAGS="true"
    ;;
"false" | "FALSE" | "False" | "" | "no" | "NO" | "No" | "n" | "N")
    JAMF_NOTIFY_FLAGS="false"
    ;;
*)
    echo "Error: Invalid parameter for JAMF_NOTIFY_FLAGS, please check your configuration"
    exit 1
    ;;
esac

################################### End Param Assignment ##################################
# ======================================================================================= #
################################### Start Function Assignment #############################
# A function to check if variable is a number id or a string id
############################################################################################
# function IS_URL(){
#     if [[ $JAMF_POLICY_ID == "https://"* ]]; then
#         echo "URL Detected"
#         JAMF_POLICY_ID
#         echo "Policy ID: $JAMF_POLICY_ID"
#     fi
# }
function EXTRACT_ID_FROM_URL() {
    POLICY_ID_URL=$POLICY
    POLICY=$(echo "$POLICY" | awk -F'=' '{print $2}' | awk -F'&' '{print $1}')
}

##############################################################
function CHECK_POLICY_TYPE() {
    ##### Check if Policy ID is a string or number #####
    if [[ $POLICY == "https://"* ]]; then
        JAMF_POLICY_TYPE="URL"
    elif [[ $POLICY =~ [0-9] ]] && [[ ! $POLICY =~ [a-zA-Z] ]]; then
        JAMF_POLICY_TYPE="NUMBER"
    elif [[ $POLICY =~ [a-zA-Z0-9] ]]; then
        JAMF_POLICY_TYPE="STRING"
    else
        echo "Policy ID is not a string, url or number"
        echo "Error: Invalid policy, please check your configuration"
        exit 1
    fi
}

############################################################################################
# A function to convert the policy ID string to an array
############################################################################################
function CONVERT_TO_ARRAY() {
    IFS=',' read -r -a POLICY_ID_ARRAY <<<"$JAMF_POLICY_ID"
    # Remove all dead space on both sides with awk
    POLICY_ID_ARRAY=($(echo "${POLICY_ID_ARRAY[@]}" | awk '{$1=$1};1'))
    ARRAY_LENGTH=${#POLICY_ID_ARRAY[@]}
}

############################################################################################
# A function to check if variable is a single policy or an array
# by looking for a comma delmiter in the string
############################################################################################
function CHECK_IF_ARRAY() {
    if [[ $JAMF_POLICY_ID == *","* ]]; then
        CONVERT_TO_ARRAY
        if [[ $ARRAY_LENGTH == 0 ]]; then
            echo "Error: No policy ID's provided, please check your configuration"
            exit 1
        elif [[ $ARRAY_LENGTH == 1 ]]; then
            echo "Error: Only one policy ID provided"
            IS_ARRAY=false
            # Repeat the contents of the array to verify visually
        else
            IS_ARRAY=true
        fi
    else
        IS_ARRAY=false
    fi
}
function CALL_POLICY() {
    CHECK_POLICY_TYPE
    if [[ "$JAMF_POLICY_TYPE" == "NUMBER" ]]; then
        $JAMF_BINARY policy -id "$POLICY"
        POLICY_ID_URL="https://COMPANY.jamfcloud.com/policies.html?id=$POLICY&O=l"
        echo "full policy  can be found at $POLICY_ID_URL"
        sleep 3
    elif [[ "$JAMF_POLICY_TYPE" == "STRING" ]]; then
        $JAMF_BINARY policy -trigger "$POLICY"
        sleep 3
    elif [[ "$JAMF_POLICY_TYPE" == "URL" ]]; then
        EXTRACT_ID_FROM_URL
        $JAMF_BINARY policy -id "$POLICY"
        echo "full policy  can be found at $POLICY_ID_URL"
        sleep 3
    else
        echo "Error: Invalid policy, please check your configuration"
        exit 1
    fi
}
##############################
# A function to run the policy
############################################################################################
function RUN_POLICY() {
    CHECK_IF_ARRAY
    if [[ ! $IS_ARRAY = true ]]; then
        POLICY=$JAMF_POLICY_ID
        echo "policy id is $POLICY"
        CALL_POLICY
    else

        while [[ $DETERMINATE_COUNTER -lt $ARRAY_LENGTH ]]; do
            POLICY=${POLICY_ID_ARRAY[$DETERMINATE_COUNTER]}
            if [[ "$JAMF_NOTIFY_FLAGS" == "true" ]]; then
                echo "Command: DeterminateManualStep: $DETERMINATE_COUNTER" >>$NOTIFY_LOG
                echo "Command: DeterminateManualStep: $DETERMINATE_COUNTER"
            fi
            CALL_POLICY

            ((DETERMINATE_COUNTER++))

        done
    fi
}

### And here we run the policy itself.
RUN_POLICY
