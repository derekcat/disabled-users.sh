#!/bin/bash
# Script written by Derek DeMoss for Dark Horse Comics, Inc. 2015
# This is designed to create a list of users who have been disabled from loging in
# Most of the logic is stolen from my Nagios plugin:
# https://github.com/derekcat/check_od_lock.sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "" ]; then
	echo "disabled-users.sh"
	echo "Generates a list of disabled OD users and either emails or prints to STDOUT\n"
	echo "Usage: disabled-users.sh -e [email-to address]"
	echo "Usage: disabled-users.sh -p"
	echo "Options"
	echo "-h, --help			Display this help message"
	echo "-e [email-to address], --email	Email the results to [email-to address]"
	echo "-p, --print			Print to STDOUT instead of emailing the list"
	exit
fi

# Make a list of OpenDirectory Users
ODUSERS="$(dscl /LDAPv3/127.0.0.1 -list /Users | grep -v vpn | grep -v ldap)"

# Cleanly initialize our list of disabled users
DISABLEDUSERS=""

if [ $1 = "-p" ] || [ $1 = "--print" ]; then # If we're printing to STDOUT
	echo "Now checking for disabled users, please wait..."

	for USER in $ODUSERS # Step through our list of users
	do
		# If they're disabled, then add them to the list
		YESDISABLED="$(pwpolicy -u $USER -getpolicy | awk '{print $1}' | grep isDisabled=1)"
		if [ $YESDISABLED ]; then
			DISABLEDUSERS+="$USER "
		fi
	done
	
	if [[ -n "$DISABLEDUSERS" ]]; then #if $DISABLEDUSERS is not empty, print them
		echo "Disabled user[s]:$DISABLEDUSERS"
		exit
	else
		echo "No one is disabled, yay!"
		exit
	fi
fi


if [ $1 = "-e" ] || [ $1 = "--email" ]; then # If we're emailing the list
	EMAILADDRESS=$2 # Let's give that a nice name

	for USER in $ODUSERS # Step through our list of users
	do
		# If they're disabled, then add them to the list
		YESDISABLED="$(pwpolicy -u $USER -getpolicy | awk '{print $1}' | grep isDisabled=1)"
		if [ $YESDISABLED ]; then
			DISABLEDUSERS+="$USER "
		fi
	done
	
	if [[ -n "$DISABLEDUSERS" ]]; then #if $DISABLEDUSERS is not empty, email the list
		echo "Disabled user[s]:$DISABLEDUSERS" | mail -s "Subject: Pan has disabled users" "$EMAILADDRESS"
		exit
	else
		echo "No one is disabled, yay!  Let's not bother sending an email."
		exit
	fi
fi
