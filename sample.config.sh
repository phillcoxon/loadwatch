#!/bin/bash
# Created by:	Liquid Web
# Enhanced by:	Phill Coxon, Will Ashworth

######################################################################################################
######################################### BASIC CONFIG FILE ##########################################
######################################################################################################

# Common paths
PATH_cp="/bin/cp"
PATH_mv="/bin/mv"
PATH_ps="/bin/ps"
PATH_grep="/bin/grep"
PATH_fake="/bin/fake"

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