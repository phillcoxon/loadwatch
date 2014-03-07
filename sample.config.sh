#!/bin/bash
# Created by:	Liquid Web
# Enhanced by:	Phill Coxon, Will Ashworth

######################################################################################################
######################################### BASIC CONFIG FILE ##########################################
######################################################################################################

# Common paths
_path_cp="/bin/cp"
_path_mv="/bin/mv"
_path_ps="/bin/ps"
_path_grep="/bin/grep"
_path_fake="/bin/fake"

# Loadwatch log directory
DIR=/root/loadwatch
COLUMNS=512
SUBJECT="Loadwatch notification for $HOSTNAME at ".`date +%F.%H.%M`
EMAILMESSAGE="/tmp/emailmessage.txt"

# Delete when "X" days old
REMOVE="30"

# Notification Email Address
EMAIL="root@localhost"

# Load Threshold for doing a dump (4 is a good number to start with)
THRESH=4