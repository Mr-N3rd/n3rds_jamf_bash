#!/bin/bash

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
# $4 is the file path or application to launch
# $5 Override_flags is a list of flags to add to the application.
# $6 RUN_IN_BACKGROUND .... does what it says. Non-blocking.\
# $7 = Validation path. if Specified, $8 automatically becomes validate file, and run in background is automatically true.
# Validation function will wait 300 seconds until the validation file or path exists. If it does not exist, it will kill the app.
# It is best to make this policy into it's own policy. this policy will definitely slow things down.
# $8 Extra-function - To call different modes of the same function. One to close the application, and another to open the application again after closing.
# $8 Accepted : 0 for none, 1 to kill the app then reopen (doesn't work for URL), 2 to only kill.
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
LOGGED_IN_USER=$(stat -f%Su /dev/console)
DEFAULT_FLAG="-a"
COMPANY_SELF_SERVICE=""
DEFAULT_OPEN_APP=$COMPANY_SELF_SERVICE_FLAG
REQ_OPEN=${4}
OVERRIDE_FLAGS=${5}
RUN_IN_BACKGROUND=${6}
VALIDATE_PATH=${7}
EXTRA_FUNCTION=${8}

# Adding extra functionality, like "Find and validate Folder, or Kill app if open, or Kill Before Open, or Kill After Open"

# Check run in background for Y/N
if [[ $RUN_IN_BACKGROUND =~ ^[Yy]$ ]]; then
    RUN_IN_BACKGROUND="true"
fi

if [[ -n $VALIDATE_PATH ]]; then
    EXTRA_FUNCTION=3
    echo "validate function flag passed"
    RUN_IN_BACKGROUND="true"
fi

function DELINIATE() {
    echo -e "----------------------------------------------------------------\n"
}
# Check if run in background is set to y/Y/true/TRUE/True or n/N/false/FALSE/False

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
# Validate App checks what the passed value for "Open App" likely is. Takes one parameter, which is typically the same value as $4.
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-

function VALIDATE_APP() {
    # Check the passed value whether it starts like a url or not

    if [[ -z ${1} ]]; then
        echo "Error: no value passed"
        exit 1
    fi
    if [[ ${1} == *"://"* ]]; then
        echo -e "${1} is url \n \n"
        DEFAULT_FLAG="-u"
        APP_MODE=1
        return 1 # 1 == url
    elif [[ ${1} == *"/Applications/"* ]]; then
        echo -e "${1} is application path \n \n"
        DEFAULT_FLAG="-a"
        APP_MODE=2
        return 2 # 2 == application path
    elif [[ ${1} =~ ^[A-Za-z0-9]*.()$ ]]; then
        echo "is this an app? ${1}"
        DEFAULT_FLAG="-a"
        APP_MODE=2
        return 2
    else
        echo -e "${1} is not a url or path \n Assuming Application name."
        DEFAULT_FLAG="-a"
        APP_MODE=2
        return 2 # 0 == not url or path

    fi
}

function KILL_NOT_OPEN() {
    echo "killing $REQ_OPEN"
    echo "checking if \$app mode"
    if [[ -z "$APP_MODE" ]]; then
        VALIDATE_APP "${REQ_OPEN}"
    fi
    echo "App mode is  $APP_MODE "
    case $APP_MODE in
    1)
        echo "URL passed, no need to kill"
        ;;
    2)
        echo "Application path passed, Checking for Application and killing"
        # Grab only the application name from ${REQ_OPEN}
        REQ_OPEN=$(echo "${REQ_OPEN}" | sed 's/.*\///' | sed 's/\.app//')
        echo "updated reqopen to ${REQ_OPEN}"
        if [[ $(pgrep "${REQ_OPEN}") ]]; then
            echo "Application is open, killing"
            pkill "${REQ_OPEN}"
        else
            echo "Application is not open, no need to kill"
        fi
        ;;
    3)
        echo "Application name passed, checking if open"
        if [[ "$REQ_OPEN" == $COMPANY_SELF_SERVICE ]]; then
            REQ_OPEN="Self Service"
        fi
        if [[ $(pgrep "${REQ_OPEN}") ]]; then
            echo "Application is open, killing"
            pkill "${REQ_OPEN}"
        else
            echo "Application is not open, no need to kill"
        fi
        ;;
    *)
        echo "Error: something went wrong"
        exit 1
        ;;
    esac

}

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
# Open as user runs the open command as the logged in user.
# Takes no parameters, but uses the assigned variables $FLAG and $REQ_OPEN from other steps
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-

function OPEN_AS_USER() {
    if [[ $RUN_IN_BACKGROUND == "true" ]]; then
        sudo -u "$LOGGED_IN_USER" open "$FLAG" "$REQ_OPEN" &
    else
        sudo -u "$LOGGED_IN_USER" open $FLAG "$REQ_OPEN"
    fi
}

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
# Constructs the Flags to be used in the open command. Takes no parameters, but uses the assigned variables $FLAG and $REQ_OPEN from other steps.
# Should append $OVERRIDE_FLAGS to the end of the $FLAG variable
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-

function FLAG_CONSTRUCT() {
    if [[ -n $OVERRIDE_FLAGS ]]; then
        OVERRIDE_FLAGS="${OVERRIDE_FLAGS// /}"
        OVERRIDE_FLAGS="${OVERRIDE_FLAGS//-/}"
        FLAGS=${FLAG//-/}
        #check for existing flag. remove existing letter from the override list.
        if [[ $OVERRIDE_FLAGS =~ [$FLAGS] ]]; then
            #remove one instance of the flag from the list
            OVERRIDE_FLAGS="${OVERRIDE_FLAGS//$FLAGS/}"
            echo "Updated Override list to $OVERRIDE_FLAGS"
        fi
        FLAG="-$OVERRIDE_FLAGS$FLAGS"
    fi
}
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
# RUN OPENER constructs the Open As User function by first checking if any values were passed at all, and if so, validating them by type
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
function RUN_OPENER() {
    # Check if there is a passed value at all first.

    if [[ -z $REQ_OPEN ]]; then
        REQ_OPEN="${DEFAULT_OPEN_APP}"
        FLAG=${DEFAULT_FLAG}
    else
        if [[ -z $APP_MODE ]]; then
            VALIDATE_APP "${REQ_OPEN}"
        fi
        case $? in
        1)
            echo "URL passed to script"
            FLAG="-u"
            ;;
        2)
            echo "Application path passed to script"
            FLAG="-a"
            ;;
        3)
            echo "No valid value passed to script. Using defaults"
            REQ_OPEN="${DEFAULT_OPEN_APP}"
            FLAG=${DEFAULT_FLAG}
            ;;
        esac
    fi
    if [[ -n $OVERRIDE_FLAGS ]]; then
        FLAG_CONSTRUCT
        echo "flag constructor called, Updated flag is $FLAG"
        DELINIATE
    fi
    OPEN_AS_USER

    echo "Extra functions = $EXTRA_FUNCTION "
    $EXTRA_FUNCTION
    echo "validation Completed"
}
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
# Does what the label Says
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-

function KILL_THEN_OPEN() {
    echo "Killing $REQ_OPEN"
    KILL_NOT_OPEN
    OPEN_TEST=$(pgrep "$REQ_OPEN")
    if [[ $OPEN_TEST == 0 ]] || [[ -z "$OPEN_TEST" ]]; then
        echo "kill successful"
        OPEN_TEST=""
        sleep 3
        echo "Open As User with $REQ_OPEN/app requested and $FLAG"
        OPEN_TEST=$(pgrep "$REQ_OPEN" | wc -l)
        if [[ $OPEN_TEST -ne 0 ]] || [[ -n $OPEN_TEST ]]; then
            echo "Open As User with $REQ_OPEN/app succesful"
            OPEN_TEST=""
        else
            echo "error found"
            exit 1
        fi
    fi
    APP_MODE=""
}

function VALIDATE() {
    TIMEOUT=300
    if [[ $REQ_OPEN == *"Outlook"* ]]; then
        VALIDATE_PATH="/Users/$LOGGED_IN_USER/Library/Group Containers/UBF8T346G9.Office/Outlook/Outlook 15 Profiles"
        # Grab the file-size of the profile, and store it in a variable.
        until [[ -e $VALIDATE_PATH ]]; do
            sleep 5
        done
        FILE_SIZE=$(du -s "$VALIDATE_PATH" | awk '{print $1}')
        while [[ $NEW_SIZE -le $FILE_SIZE ]]; do
            NEW_SIZE=$(du -s "$VALIDATE_PATH" | awk '{print $1}')
            # echo "file size is $NEW_SIZE"
            COUNTER=$((COUNTER + 10))
            REMAINING_TIME=$(($TIMEOUT - $COUNTER))
            echo "$REMAINING_TIME seconds remaining after $COUNTER seconds."
            if [[ $REMAINING_TIME -le 0 ]]; then
                echo "timeout reached"
                exit 1
            fi
            echo "retrying in 10"
            sleep 10
        done
        exit 0
    fi
    if [[ -n $VALIDATE_PATH ]]; then
        echo "$VALIDATE_PATH"
        until [[ -e $VALIDATE_PATH ]]; do
            COUNTER=$((COUNTER + 1))
            echo "attempt $COUNTER / 300 to validate"
            if [[ $COUNTER -ge 300 ]]; then
                echo "validation failed"
                exit 1
            fi
            sleep 1
        done
    fi
}
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
if [[ -z $EXTRA_FUNCTION ]]; then
    echo "No extra function requested"
    RUN_OPENER
else
    echo "Extra function requested"
    case $EXTRA_FUNCTION in
    0)
        echo "no add ons called."

        ;;
    1)
        echo "Killing then opening"
        EXTRA_FUNCTION="KILL_THEN_OPEN"

        ;;
    2)
        echo "Killing, no reopen"
        EXTRA_FUNCTION="KILL_NOT_OPEN"

        ;;
    3)
        echo "Running Validation"
        EXTRA_FUNCTION="VALIDATE"

        ;;
    esac
    RUN_OPENER
fi
