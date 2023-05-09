#!/bin/bash
#Increment Version if this or functions.sh are updated.
#Version 1.21
. $(dirname "$0")/functions.sh

title="\nWelcome to the TCS Upkeep Script!\n"

printf "$title"


options=("Add/Remove Users" "Setting Dock" "Pull music" "Pull video" "Munki Client Setup" "Edit Manifest" "Rename machine" "Add Printers" "Uninstall Uniflow" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Add/Remove Users")
            echo "Adding / Removing Users"
                while true; do
                read -p "Are you trying to (A)dd, (R)emove a user, (D)elete all non-admin users? : " addremovicechoice
                    case $addremovicechoice in
                    [Aa])
                        add_user
                        restart_function
                        break;;
                    [Rr])
                        list_users
                        delete_user
                        break 2 ;;
                    [Dd])
                        delete_nonadmin_users
                        break 2 ;;
                    "")
                        echo "Nothing entered. Exiting..."
                        break 2 ;;
                    *)
                        echo "Please choose 'A' or 'R'."
                    esac
                done
            ;;
        "Setting Dock")
            dockarray
            set_dock
            ;;
        "Pull music")
            youtubedl_check
            echo -n "Paste the Youtube URL: "
            read link

            echo "Pulling audio from " $link
            youtube-dl -o '~/Desktop/%(title)s.%(ext)s' --quiet --extract-audio --audio-format mp3 $link
            echo "Check your Desktop!"
            
            if [ -e /usr/local/bin/download ]; then
            break
            else
            echo "Copying to /usr/local/bin for ease of use"
            me=`basename $0`
            DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
            sudo cp $DIR/$me /usr/local/bin/download
            echo "Next time just run 'download to start the script!'"
            fi
            ;;
        "Pull video")
            youtubedl_video
            ;;
        "Munki Client Setup")
            munki_installer
            munki_client_setup
            ;;
        "Edit Manifest")
            echo "Changing MSC Manifest"
                echo "Manifest (Client Identifier) of this pc: $(defaults read /Library/Preferences/ManagedInstalls.plist | grep 'ClientIdentifier')"           
                    while true; do
                        read -p "Would you like to change it? [Y or N] " manifestchoice
                        case $manifestchoice in
                            [Yy] ) PS3='Please choose from the following manifests: '
                            options=('tcsfaculty' 'tcsstudents' 'other')
                            select manifestopt in "${options[@]}"
                            do 
                                case $manifestopt in
                                    "tcsfaculty")
                                        echo "Changing manifest to $manifestopt"
                                        msc_identity $manifestopt
                                        refresh_msc
                                        main_option
                                        break;;
                                    "tcsstudents")
                                        echo "Changing manifest to $manifestopt"
                                        msc_identity $manifestopt
                                        refresh_msc
                                        main_option
                                        break;;
                                    "other")
                                        read -p "What is the manifest name? " custom_manifest
                                        msc_identity $custom_manifest
                                        echo "Changing manifest to $custom_manifest"
                                        refresh_msc
                                        main_option
                                        break;;
                                    *) echo "Choose a valid manifest number."
                                esac
                            done
                            break;;
                            [Nn] ) echo "OK."
                            break;;
                            * ) echo "Please answer Y or N";;
                        esac
                    done
            ;;
        "Rename machine")
            rename_machine
            break
            ;;
        "Add Printers")
            printers
            break
            ;;
        "Uninstall Uniflow")
            uniflow_remove
            break
            ;;
        "Quit")
            echo "Goodbye!"
            break
            ;;
        *) echo "Invalid option $REPLY"; continue;;
      esac
done
