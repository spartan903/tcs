# This is a collection of various functions used in the upkeep script. Not all may be implemented.

# Test includes
test_include(){
    read -p "Hello world. What is your name? " aname 
    echo "Hello $aname."
}

# Restart Option
restart_function() {
    while true; do
        read -p "Computer requires a restart. Do you want to restart now? (Y or N): " restartchoice
            case $restartchoice in
                [Yy] )
                    echo "Restarting"
                        sudo reboot
                        break;;
                [Nn] )
                    echo "Please restart using 'sudo reboot'"
                        break;;
                *)
                    echo "Please choose Y or N.";;
            esac
    done
}

# Dock Options
## Setting Dock for all users.
set_dock () {
    sudo dockutil --remove all --allhomes
    sudo dockutil --add '/Applications/Google Chrome.app' --allhomes
    sudo dockutil --add '~/Downloads' --allhomes
    sudo dockutil --add '/Applications' --allhomes
    sudo killall Dock 
}

## Setting Dock for specific user.
set_dock_user () {
    sudo dockutil --remove all /Users/$1
    sudo dockutil --add '/Applications/Google Chrome.app' /Users/$1
    sudo dockutil --add '~/Downloads' /Users/$1
    sudo dockutil --add '/Applications' /Users/$1
                
    if [ $(whoami) == $1 ]; then
        sudo killall Dock
    fi

}

# Rename machine
rename_machine () {
    echo "Renaming this machine. Please use approved naming convention."
    read -p "What is the username? : " rename
    
    sudo scutil --set HostName $rename
    sudo scutil --set LocalHostName $rename
    sudo scutil --set ComputerName $rename
    
    echo "Laptop successfully renamed to $rename! Please restart terminal to see changes."
    echo ""
    echo "Changes are listed below:"
    echo "HostName: $(sudo scutil --get HostName)"
    echo "LocalHostName: $(sudo scutil --get LocalHostName)"
    echo "ComputerName: $(sudo scutil --get ComputerName)"
    echo ""  
}

# Main Options
main_option () {
    PS3='Main Choices: 1:Add/Remove Users 2:Setting Dock 3:Pull music 4:Pull video 5:Munki Client Setup 6:Edit Manifest 7:Rename machine 8:Add Printers 9:Uninstall Uniflow 10:Quit :'  
}

# Edit MSC Client Identifier
msc_identity () {
    sudo defaults write /Library/Preferences/ManagedInstalls.plist ClientIdentifier $1
}

# Adding a user
add_user () {
    read -p "What is the username of the user?: " ausername
    read -p "What is the real name of the user?: " arealname
    read -p "What is the password for this user?: " apassword

    usernum=$(dscl . -list /Users UniqueID | sort -nr -k 2 | head -1 | grep -oE '[0-9]+$')
    usernum=$((usernum+1))
        while true; do
            read -p "Is this user an Administrator for this laptop? [Y or N]: " adminchoice
            case $adminchoice in
                [Yy] ) echo "$ausername is set to Administrator."
                        aprimarygroupid=80
                break;;
                [Nn] ) echo "$ausername is set to Standard."
                        aprimarygroupid=20
                break;;
                * ) echo "Please select Y or N for Admin question."
            esac
        done

    sudo dscl . -create /Users/$ausername
    sudo dscl . -create /Users/$ausername UserShell /bin/bash
    sudo dscl . -create /Users/$ausername RealName "$arealname"
    sudo dscl . -create /Users/$ausername UniqueID $usernum
    sudo dscl . -create /Users/$ausername PrimaryGroupID $aprimarygroupid
    sudo dscl . -create /Users/$ausername NFSHomeDirectory /Users/$ausername
    sudo dscl . -passwd /Users/$ausername "$apassword"
    sudo dscl . -append /Groups/staff GroupMembership $ausername 
    sudo dscl . delete /Users/$ausername jpegphoto
    sudo dscl . create /Users/$ausername Picture /Library/User\ Pictures/Nature/Earth.png
    
    sudo createhomedir -c 2>&1 | grep -v "shell-init"
    sudo dseditgroup -o edit -a $ausername -t user _lpadmin

    echo "Creating user $ausername."
    echo "Creating real name $arealname."
    echo "Creating password of $apassword"
    echo "Creating Unique ID of $usernum."
    echo "$ausername can now add printers."
}

# List users allowed to be removed.
list_users () {
    echo "Users List:"
    echo "$(dscl . -list /Users | grep -v '_' | grep -v 'daemon' | grep -v 'root' | grep -v 'nobody' | grep -v '/' | grep -v 'remote')"
}

# Delete a user
delete_user () {
    read -p "What is the username to be removed?: " userdelete
    while true; do 
		read -p "You picked $userdelete. Is this right? [Y or N]" deletechoice
            case $deletechoice in 
                [Yy] )
                    echo "Checking if user exists..."
                    if [ -e /Users/$userdelete ]; then
                        echo "User $userdelete found! Removing..."
                        
                        sudo dseditgroup -o edit -d $userdelete -t user _lpadmin
                        sudo dscl . delete /Users/$userdelete
                        sudo rm -rf /Users/$userdelete
                    else
                        echo "User not found! Please try again."
                    fi
                break;;
                [Nn] ) 
                    echo "OK."
                break;;
                * ) echo "Please answer Y or N. ";;
            esac
    done
}

# Cycle delete non admin users
delete_nonadmin_users() {

# Loop through users with homes in /Users; exclude any accounts you don't want removed (i.e. local admin and current user if policy runs while someone is logged in)
for username in `ls /Users | grep -v tcstech | grep -v tcsadmin | grep -v Shared`
do
    if [[ $username == `ls -l /dev/console | awk '{print $3}'` ]]; then
        echo "Skipping user: $username (current user)"
    else
        echo "Removing user: $username"
        # Optional, removes the account
        sudo dscl . delete /Users/$username
        # Removes the user directory
        sudo rm -rf /Users/$username
    fi
done
}

# Edit User function
edit_user () {
    read -p "What is the username to be edited?: " useredit
    stringcheck=$(dscl . -read /Groups/admin GroupMembership | awk -F ':' '{print $2}')
        if [[ $stringcheck = *"$useredit"* ]]; then
            while true; do
            read -p "$useredit is an Admin. Would you like to set $useredit as a Standard User? [Y or N]: " setuseraccount
                case $setuseraccount in
                    [Yy] )
                        echo "Setting $useredit to Standard..."
                        sudo dscl . -create /Users/$useredit PrimaryGroupID 20
                        sudo dseditgroup -o edit -d $useredit -t user admin
                        echo "$useredit is now a Standard account."
                        restart_function
                        break;;
                    [Nn] )
                        break;;
                    * )
                        echo "Please select Y or N." ;;
                esac
            done
        else
            while true; do
            read -p "$useredit is not an Admin. Would you like to set $useredit as an Administrator User? [Y or N]: " setadminaccount
                case $setadminaccount in
                    [Yy] )
                        echo "Setting $useredit to Administrator..."
                        sudo dscl . -create /Users/$useredit PrimaryGroupID 80
                        sudo dseditgroup -o edit -a $useredit -t user admin
                        echo "$useredit is now an Administrator account."
                        restart_function
                        break;;
                    [Nn] )
                        echo "OK."
                        break;;
                    * )
                        echo "Please select Y or N. " ;;
                esac
            done            
        fi
}

# DNS Status Checks on Wi-Fi interface.
dns_status () {
dns_check=$(networksetup -getdnsservers Wi-Fi)
if [[ $dns_check == *"There"* ]]; then
    echo "Securly is currently DISABLED."
elif [[ $dns_check == "50"* ]]; then 
    echo "Securly is currently ENABLED."
else
    echo "DHCP or Securly settings are not set! Please double check DNS settings."
fi 
}

# Checking DockUtil prereqs the old way
dockpreqs () { 
    echo "Checking Pre-reqs"

    echo "Checking for Xcode command line tools.."
    if [ -e /usr/bin/xcode-select ]; then
    echo "Xcode command line tools already installed."
    else
    echo "No Xcode command line tools installed. Installing..."
    xcode-select --install
    wait
    echo "Xcode command line tools installed!"
    fi

    echo "Checking for Homebrew"
    if [ -e /usr/local/bin/brew ]; then
    echo "Homebrew already installed."
    else
    echo "Homebrew not found. Installing..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    wait
    echo "Homebrew installed!"
    fi

    echo "Checking for DockUtil"
    if [ -e /usr/local/bin/dockutil ]; then
    echo "DockUtil already installed."
    else
    echo "DockUtil not found. Installing..."
    brew install dockutil
    wait
    "DockUtil installed!"
    fi
}

#Checking for DockUtil the new way
dockarray () {
bold=$(tput bold)
normal=$(tput sgr0)
programsneeded=(brew dockutil xcode-select)
stuffitems=${programsneeded[*]}

for item in $stuffitems
  do
    if [ -e /usr/local/bin/$item ]; then
      echo "${bold}$item ${normal}already installed."
    else
      case $item in
        brew)
            echo "Installing Homebrew..."
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		    wait
            echo "Homebrew Installed!"
        ;;
		dockutil)
            echo "Installing DockUtil..."
	  		brew install dockutil
			wait
            echo "DockUtil Installed!"
		;;
        xcode-select)
            # Need this statement to avoid 'xcode-select: error: command line tools are already installed, use "Software Update" to install updates' line.
            if [ -e /usr/bin/xcode-select ]; then
	            echo "${bold}xcode-select ${normal}already installed."
            else
                echo "No xcode-select installed. Installing..."
                xcode-select --install
                wait
                echo "xcode-select installed!"
            fi	
        ;;
      esac
	fi
  done
}

# Checking to see if prereqs are met to be able to pull music only using youtube-dl
youtubedl_check () {
bold=$(tput bold)
normal=$(tput sgr0)
programsneeded=(brew youtube-dl xcode-select)
stuffitems=${programsneeded[*]}

for item in $stuffitems
  do
    if [ -e /usr/local/bin/$item ]; then
      echo "${bold}$item ${normal}already installed."
    else
      case $item in
        brew)
            echo "Installing Homebrew..."
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		    wait
            sudo chown -R $(whoami) $(brew --prefix)/*
            echo "Homebrew Installed!"
        ;;
		youtube-dl)
            echo "Installing Youtube-DL..."
	  		brew install youtube-dl
			wait
            echo "Youtube-DL Installed!"
            echo "Fixing Links"
            brew link youtube-dl
            brew link overwrite youtube-dl
            echo "Installing Youtube-DL dependencies"
                echo "Checking for ffmpeg"
                    if [ -e /usr/local/bin/ffmpeg ]; then
                    echo "FFMPEG Installed"
                    else
                    brew install ffmpeg
                    fi
            echo "Updating and Upgrading any Brew formulas"
                brew update && brew upgrade
            echo "Cleaning up"
            brew cleanup
            echo "Clean up Done!"
		;;
        xcode-select)
            # Need this statement to avoid 'xcode-select: error: command line tools are already installed, use "Software Update" to install updates' line.
            if [ -e /usr/bin/xcode-select ]; then
	            echo "${bold}xcode-select ${normal}already installed."
            else
                echo "No xcode-select installed. Installing..."
                xcode-select --install
                wait
                echo "xcode-select installed!"
            fi	
        ;;
      esac
	fi
  done
}

# Pull a YouTube video
youtubedl_video(){
    echo -n "Paste the Youtube URL: " 
    read videolink

    echo "Pulling video from " $videolink
    youtube-dl -o  '~/Desktop/%(title)s.%(ext)s' --quiet $videolink
    echo "Check your Desktop!"
}

# Edit MSC Client Identifier
msc_identity () {
    sudo defaults write /Library/Preferences/ManagedInstalls.plist ClientIdentifier $1
}

# Munki Installer
munki_installer(){

programsneeded=(brew wget)
stuffitems=${programsneeded[*]}

for item in $stuffitems
  do
    if [ -e /usr/local/bin/$item ]; then
      echo "$item already installed."
    else
      case $item in
        brew)
            echo "Installing Homebrew..."
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		    wait
            echo "Homebrew Installed!"
        ;;
		    wget)
            echo "Installing wget..."
	  		    brew install wget
			      wait
            echo "wget Installed!"
		    ;;
      esac
	fi
  done

echo "Changing to '/tmp' folder"
cd /tmp
read -p "Please enter the version number (Hit Enter to install 5.2.3.4295 ): " pkg_url
if [ "$pkg_url" == "" ]; then
pkg_url="5.2.3.4295"
sudo wget https://github.com/munki/munki/releases/download/v5.2.3/munkitools-5.2.3.4295.pkg
else
sudo wget https://github.com/munki/munki/releases/download/v5.2.3/munkitools-$pkg_url.pkg
fi

#Installing Munkitoolset
sudo installer -pkg /tmp/munkitools-$pkg_url.pkg -target /
sudo rm /tmp/munkit*

#Setting PATH
PATH=$PATH\:/usr/local/munki; export PATH
}

munki_client_setup(){
# Set these to correct TCS variables 
munki_url="192.168.4.188"
munki_repo_name="munki_repo"

#To save typing time
defaults_path="/Library/Preferences/ManagedInstalls"
software_repo_url="http://$munki_url/$munki_repo_name"
apple_update_flag="InstallAppleSoftwareUpdates"
#Set to either 0 for False, 1 for true
munki_apple_updates="0"

echo "#####"
echo "Setting these variables to munki client:"
echo "Munki SoftwareRepoURL: http://$munki_url/$munki_repo_name"
echo "Check Apple Software Updates (1 = Yes, 0 = No): $munki_apple_updates"
echo "Defaulting to manifest 'tcsstudents'. Please run Edit Manifest after to set correct manifest."
echo "#####"

sudo defaults write $defaults_path SoftwareRepoURL $software_repo_url
sudo defaults write $defaults_path $apple_update_flag $munki_apple_updates
sudo defaults write $defaults_path ClientIdentifier tcsstudents

# Refreshing Managed Software Center
osascript -e 'quit app "Managed Software Center"'
sudo managedsoftwareupdate

if [[ $(ls /Applications/ | grep Managed) == "" ]]; then
echo "Please open MSC to see new changes, if any."
else
open /Applications/"Managed Software Center.app"
fi
}

refresh_msc(){
# Refreshing Managed Software Center
osascript -e 'quit app "Managed Software Center"'
sudo managedsoftwareupdate

if [[ $(ls /Applications/ | grep Managed) == "" ]]; then
echo "Please open MSC to see new changes, if any."
else
open /Applications/"Managed Software Center.app"
fi
}

printers(){
: <<'END'
Version 1.0 - TCS Printer install
Created by: Carlo Reyes
Updated 2/3/20
END

# Setup printer options

#Global Vars
a_building='10.11.2.118'
b_building='10.11.1.2'
c_building='10.11.17.24'
d_building='10.11.4.50'
g_building='10.11.7.50'
j_building='10.11.9.50'

download_prefix='https://drive.google.com/uc?export=download&id='


a_building_xerox (){
# IP Address: 10.11.2.118
# Xerox WorkCentre 7225
# GDP ID: B7026

printer_name='A_Building_Xerox'
ppd=7225.ppd
download_id='1xrx9t9Bgx44nyJHNPyOy8c5tjJqb4FDu'
sudo wget -O /Users/Shared/Printers/$ppd "$download_prefix$download_id"
lpadmin -p $printer_name -v "ipp://$a_building:631" -P /Users/Shared/Printers/$ppd -E
}

b_building_xerox () {
# IP Address: 10.11.1.2
# Xerox Color 560
# GDP ID: B1630

printer_name='B_Building_Xerox'
ppd=560.ppd
download_id='1M4lZVdZLTgmefMnsUM7ErZgigm2oaO6C'
sudo wget -O /Users/Shared/Printers/$ppd "$download_prefix$download_id"
lpadmin -p $printer_name -v "ipp://$b_building:631" -P /Users/Shared/Printers/$ppd -E
}

c_building_xerox () {
# IP Address: 10.11.17.24
# Xerox WorkCentre 7225
# GDP ID: B7012

printer_name='C_Building_Xerox'
ppd=7225.ppd
download_id='1xrx9t9Bgx44nyJHNPyOy8c5tjJqb4FDu'
sudo wget -O /Users/Shared/Printers/$ppd "$download_prefix$download_id"
lpadmin -p $printer_name -v "ipp://$c_building:631" -P /Users/Shared/Printers/$ppd -E
}

g_building_xerox () {
# IP Address: 10.11.7.50
# Xerox WorkCentre 7845
# GDP ID: B4021

printer_name='G_Building_Xerox'
ppd=7845.ppd
download_id='188jeFO4yxVpA0ewdl0ZGhy2mje95w2tm'
sudo wget -O /Users/Shared/Printers/$ppd "$download_prefix$download_id"
lpadmin -p $printer_name -v "ipp://$g_building:631" -P /Users/Shared/Printers/$ppd -E
}

d_building_xerox () {
# IP Address: 10.11.4.50
# Xerox WorkCentre 7970
# GDP ID: B4022

printer_name='D_Building_Xerox'
ppd=7970.ppd
download_id='1Ywx7V7iUoxLaqYrpfwEcDmM7gU23Q1Zj'
sudo wget -O /Users/Shared/Printers/$ppd "$download_prefix$download_id"
lpadmin -p $printer_name -v "ipp://$d_building:631" -P /Users/Shared/Printers/$ppd -E
}



j_building_xerox () {
# IP Address: 10.11.9.50
# Xerox WorkCentre 7845
# GDP ID: B4023

printer_name='J_Building_Xerox'
ppd=7845.ppd
download_id='188jeFO4yxVpA0ewdl0ZGhy2mje95w2tm'
sudo wget -O /Users/Shared/Printers/$ppd "$download_prefix$download_id"
lpadmin -p $printer_name -v "ipp://$j_building:631" -P /Users/Shared/Printers/$ppd -E
}


directory_check () {
    directory='/Users/Shared/Printers'
    if [ -d "$directory" ]; then
        echo "$directory exists"
    else
        while true; do
        read -p "$directory does not exist. Would you like to create it? (Y or N): "  createdir
            case $createdir in 
                [Yy] )
                    echo "Creating directory at $directory"
                    sudo mkdir -p $directory
                    sudo chmod 755 $directory
                    break;;
                [Nn] )
                    echo "Ok."
                    break;;
                *)
                    echo "Please choose Y or N.";;
            esac
        done
    fi
}

# Printer Main Section
directory_check 
homebrew_wget

while true; do
    options=("A Building" "B Building" "C Building" "D Building" "G Building" "J Building" "All" "Quit")
    echo "Please choose a printer to install: "
    select opt in "${options[@]}"; do
        case $REPLY in
        1) a_building_xerox; break ;;
        2) b_building_xerox; break ;;
        3) c_building_xerox; break ;;
        4) d_building_xerox; break ;;
        5) g_building_xerox; break ;;
        6) j_building_xerox; break ;;
        7) a_building_xerox; b_building_xerox; c_building_xerox; d_building_xerox; g_building_xerox; j_building_xerox; break ;;
        8) break 2 ;;
        *) echo "Invalid option." >&2
        esac
    done
done

echo "Good Bye!"
}

check_OSX(){
    osx_ver=$(sw_vers -productVersion)
    if [[ $osx_ver = "10.15"* ]]; then
        echo "You are running Catalina."
    else
        echo "You are not running Catalina"
    fi

}

homebrew_wget(){
programsneeded=(brew wget)
stuffitems=${programsneeded[*]}

for item in $stuffitems
  do
    if [ -e /usr/local/bin/$item ]; then
      echo "$item already installed."
    else
      case $item in
        brew)
            echo "Installing Homebrew..."
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		    wait
            echo "Homebrew Installed!"
        ;;
		    wget)
            echo "Installing wget..."
	  		    brew install wget
			      wait
            echo "wget Installed!"
		    ;;
      esac
	fi
  done
}

uniflow_remove(){
FILE=/private/etc/smartclient/uninstall-smartclient.bash 
if [ -f "$FILE" ]; then
    echo "Uninstaller exists, continuing..."
    sudo $FILE
else
    echo "Uninstaller does not exist or not in the proper path. Please run Uniflow installer and follow default install instructions"
fi

}