#!/bin/zsh
# UPDATED DATE: 2023-mar-9
#########################################################################################
# General Information
#########################################################################################
# This script itreates through an application array to see what is installed. This can be
# easily repurposed into different application installers as long as you can find a pkg
# download link for and that it runs without flags.
# This script was written by Leif Sandvar for the Tech Team at PHS Community Services.
#########################################################################################

################################################################
# JAMF Uses a standard variable Scheme for their scripting parameters.
# $1 = Mount Point
# $2 = Computer Name
# $3 = Username
# You can set your own Parameters after that.
# Please specifiy the Parameters Below:
# $4 = OFFICE_CORE_PKG URL
# $5 = OFFICE_FULL_PKG URL
# $6 = TEAMS_PKG URL
# $7 = ONEDRIVE_PKG URL
# $8 = INTUNE_PKG URL
################################################################
DOWNLOAD_LOCATION="/tmp/Apps_Installer/"
INSTALLER_LOG="/tmp/Apps_Installer/MS-INSTALL.log"
JAMF_LOG="/var/tmp/depnotify.log"
JAMF_BIN="/usr/local/bin/jamf"

# Application Paths to check for and flag if not installed
MSWORD="/Applications/Microsoft Word.app"
MSPPT="/Applications/Microsoft PowerPoint.app"
MSOUTLOOK="/Applications/Microsoft Outlook.app"
MSEXCEL="/Applications/Microsoft Excel.app"
MSINTUNE="/Applications/Company Portal.app"
MSONEDRIVE="/Applications/OneDrive.app"
MSTEAMS="/Applications/Microsoft Teams.app"
INSTALL_FLAG_ARRAY=() # OFFICE_CORE_PKG OFFICE_FULL_PKG TEAMS_PKG ONEDRIVE_PKG INTUNE_PKG)
if [[ ! -e $PRESTAGE_LOG ]]; then
    touch $PRESTAGE_LOG
fi

function RUN_LOG() {
    echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - ${1}" | tee -a "${PRESTAGE_LOG}"
}

# Download Location Check
if [ ! -d $DOWNLOAD_LOCATION ]; then
    RUN_LOG "Download location not found, Generating in $DOWNLOAD_LOCATION"
    mkdir $DOWNLOAD_LOCATION
    RUN_LOG "mkdir $DOWNLOAD_LOCATION"
    cd $DOWNLOAD_LOCATION
else
    RUN_LOG "cd'ing into $DOWNLOAD_LOCATION"
    cd $DOWNLOAD_LOCATION
fi

# Installer Log Check
RUN_LOG "Checking for installer log"
if [ ! -e $INSTALLER_LOG ]; then
    RUN_LOG "$(date) | no installer log found. Creating : $INSTALLER_LOG"
    touch $INSTALLER_LOG
    RUN_LOG " Installer log created successfully" >>$INSTALLER_LOG
else
    rm -Rv $INSTALLER_LOG
    touch $INSTALLER_LOG
    echo "$(date) | installer log recreated successfully" >>$INSTALLER_LOG
fi

# Check for Jamf Passed Variables
RUN_LOG "Checking for Jamf Passed Variables"
OFFICE_CORE_PKG=${4:-"https://go.microsoft.com/fwlink/?linkid=525133"}
OFFICE_FULL_PKG=${5:="https://go.microsoft.com/fwlink/?linkid=2009112"}
TEAMS_PKG=${6:="https://go.microsoft.com/fwlink/?linkid=869428"}
ONEDRIVE_PKG=${7:="https://go.microsoft.com/fwlink/?linkid=823060"}
INTUNE_PKG=${8:="https://go.microsoft.com/fwlink/?linkid=869655"}

function OFFICE_CHECK() {
    if [[ -z "$1" ]]; then
        echo "did you forget to pass a variable?"
    fi
    if [[ -e ${1} ]]; then
        echo ${1} is installed

    else
        echo ${1} is not installed
        echo "Installing ${1}"
        if [[ ${1} == $MSWORD ]] || [[ $1 == $MSEXCEL ]] || [[ $1 == $MSOUTLOOK ]] || [[ $1 == $MSPPT ]]; then
            echo "Adding Office Core to install list"
            INSTALL_FLAG_ARRAY+=($OFFICE_CORE_PKG)
        fi
        if [[ ${1} == $MSTEAMS ]]; then
            echo "Adding Teams to install list"
            INSTALL_FLAG_ARRAY+=($TEAMS_PKG)
        fi
        if [[ ${1} == $MSONEDRIVE ]]; then
            echo "Adding OneDrive to install list"
            INSTALL_FLAG_ARRAY+=($ONEDRIVE_PKG)
        fi
        if [[ ${1} == $MSINTUNE ]]; then
            echo "Adding Intune to install list"
            INSTALL_FLAG_ARRAY+=($INTUNE_PKG)
        fi
        # check the Install Flag Array if it contains the the $OFFICE_CORE_PKG, the $ONEDRIVE_PKG and the $TEAMS_PKG
        if { [[ ${INSTALL_FLAG_ARRAY[@]} =~ $OFFICE_CORE_PKG ]] && [[ ${INSTALL_FLAG_ARRAY[@]} =~ $ONEDRIVE_PKG ]] && [[ ${INSTALL_FLAG_ARRAY[@]} =~ $TEAMS_PKG ]]; }; then
            echo "Adding Office Full to install list"
            INSTALL_FLAG_ARRAY=($OFFICE_FULL_PKG)
            echo "Installing Office Full instead of individual packages."
        fi
    fi
}

APPLICATION_ARRAY=($MSWORD $MSPPT $MSOUTLOOK $MSEXCEL $MSINTUNE $MSONEDRIVE $MSTEAMS)

for application in ${APPLICATION_ARRAY[@]}; do
    OFFICE_CHECK $application
done

# download each of the required packages from APPLICATION_ARRAY
for package in ${INSTALL_FLAG_ARRAY[@]}; do
    echo "Downloading $package"
    curl -L -o $DOWNLOAD_LOCATION$(basename $package) $package
    echo "Downloaded $package"
    installer -pkg $DOWNLOAD_LOCATION/$package -target / >>$INSTALLER_LOG
    # Validate installer installed package correctly
    if [[ $? -eq 0 ]]; then
        echo "Installer installed $package"
    else
        echo "installer failed to install $package"
    fi
done
