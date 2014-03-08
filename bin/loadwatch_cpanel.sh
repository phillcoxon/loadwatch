#!/bin/bash
# Created by:	Liquid Web
# Enhanced by:	Phill Coxon, Will Ashworth

# Make sure this script isn't already running (we wouldn't want that!)
if [[ "$(pidof -x "$(basename "$0")" -o %PPID)" ]]; then exit; fi



# Include our config file if it exists
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPTDIR/../config.sh" ]; then
	source "$SCRIPTDIR/../config.sh";
fi

# Verify we can find binaries to use at paths specified in configuration
# Do not let the script proceed if they are missing something essential !!

	# get those path vars
	paths=$(set | grep ^_path_*)

	for item in ${paths[*]}
	do
	    printf "   %s\n" $item
	done

	# verify those paths
	for p in $paths
	do
		type -P ${p##*=} &>/dev/null || { echo  "${p##*=} not found"; exit 1; }
	done

# Configure file name
FILE=loadwatch.$(date +%F.%H.%M.%S)

# Get needed binaries and their paths
PERL=$(which perl)

######################################################################################################
################################# PLEASE DO NOT EDIT BELOW THIS LINE #################################
######################################################################################################

# Other Variables
FORCE=0

# Include MySQL Tuner results
MYSQL_TUNER="$DIR/bin/thirdparty/mysqltuner.pl"

# Useful functions to help with organization
function usage
{
    echo "usage: loadwatch.sh [-d | --dir] [-e | --email] [-f | --file] [-r | --remove] [-t | --threshold] [-x | --force]  [--init] [-h | --help]"
}

# Get parameters so we can tailor use of the script on the fly without editing
while [ "$1" != "" ]; do
    case $1 in
        -d | --dir )            shift
                                DIR=$1
                                ;;
        -e | --email )          shift
                                EMAIL=$1
                                ;;
        -f | --file )           shift
                                FILE=$1
                                ;;
        -r | --remove )         shift
                                REMOVE=$1
                                ;;
        -t | --threshold )      shift
                                THRESH=$1
                                ;;
        --init )                INIT=1
                                ;;
        -x | --force )          FORCE=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

# If INIT is triggered, we'll handle the basic setup for you
if [[ $INIT = 1 ]];
then

	echo "Setting things up...";

	# If config.sh doesn't exist yet, let's create it!
	if [ ! -f "$SCRIPTDIR/../config.sh" ]; then
		echo "Copy our config file to something usable..."; cp -p "$SCRIPTDIR/../sample.config.sh" "$SCRIPTDIR/../config.sh";
	fi
	
	echo "Going into loadwatch bin directory..."; cd "$DIR/bin";
	echo "Copying cPanel script to safe, usable, file..."; cp -p "$DIR/bin/loadwatch_cpanel.sh" "$DIR/bin/loadwatch.sh";
	echo "Setting permissions on config file..."; chmod u+x "$DIR/config.sh";
	echo "Setting permissions on Loadwatch script..."; chmod u+x "$DIR/bin/loadwatch.sh";
	echo "Setting permissions on MySQL Tuner script..."; chmod u+x "$DIR/bin/thirdparty/mysqltuner.pl";
	echo "Going back to the loadwatch directory..."; cd "$DIR";

	echo "Okay. All done! :)";

	exit
fi

# Pull load average, log
LOAD=$(cat /proc/loadavg | awk '{print $1}' | awk -F '.' '{print $1}')

# Trip (check whether or not to run it)
if [[ $LOAD -eq $THRESH ]] || [[ $FORCE = 1 ]];
then

	# Only log triggered loads. 
	echo "$(date +%F.%X) - Load: $LOAD" >> "$DIR/checklog"
        echo -e "Loadwatch Threshhold: $THRESH, Current Load: $LOAD" >> "$DIR/$FILE"
        
    # Log our actions 
	echo -e "Loadwatch tripped, dumping info to $DIR/$FILE \n\n" >> "$DIR/checklog"
	echo -e "Current server time: " . "$(date +"%c")" >> "$DIR/$FILE"
	echo "LoadWatch on $HOSTNAME triggered. Please Check it out. \n" > "$EMAILMESSAGE"

	# not exactly sure what this is...pending deletion !!
	# email (optional, set email address to customer and uncomment below lines)
	# /bin/mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE

	# Summary
	echo -e "Summary------------------------------------------------------------ \n\n" >> "$DIR/$FILE"
    
    UNAME_A=$(uname -a)
	echo -e "Generic Server Info:\n$UNAME_A\n" >> "$DIR/$FILE"

    NUMHTTPD=$(ps aux|grep httpd|wc -l)
	echo "Number of HTTPD Processes: $NUMHTTPD" >> "$DIR/$FILE"
	
	HTTPDCPU=$(ps aux|grep httpd|awk '{sum+=$3} END {print sum}')
	echo "HTTPD CPU consumption: $HTTPDCPU %" >> "$DIR/$FILE" 
	
	HTTPDMEM=$(ps aux|grep httpd|awk '{sum+=$6} END {print sum}')
	HTTPDMEMMEG=$((HTTPDMEM/1024))
	echo "HTTPD memory consumption: $HTTPDMEM Kilobytes ($HTTPDMEMMEG Megabytes)" >> "$DIR/$FILE"
	
	NUMPROCS=$(grep -c processor /proc/cpuinfo)
	echo "Number of CPU Cores: $NUMPROCS" >> "$DIR/$FILE"
	
	NUMPHP=$(ps aux|grep php|wc -l)
	echo "Number of PHP Processes: $NUMPHP" >> "$DIR/$FILE"
	
	PHPCPU=$(ps aux|grep php|awk '{sum+=$3} END {print sum}')
	echo "PHP CPU consumption: $PHPCPU %" >> "$DIR/$FILE"
	
	PHPMEM=$(ps aux|grep php|awk '{sum+=$6} END {print sum}')
	PHPMEMMEG=$((PHPMEM/1024))
	echo "PHP memory consumption: $PHPMEM Kilobytes ($PHPMEMMEG Megabytes)" >> "$DIR/$FILE"
	
	MYSQLCPU=$(top -n 1 -S -b -U mysql|tail -n 2|head -n 1|awk {'print $9'})
	echo "MYSQL CPU consumption: $MYSQLCPU %" >> "$DIR/$FILE"
	
	MYSQLMEM=$(top -n 1 -S -b -U mysql|tail -n 2|head -n 1|awk {'print $6'})
	echo "MYSQL RAM consumption: $MYSQLMEM" >> "$DIR/$FILE"
	echo -e "\n" >> "$DIR/$FILE"

	# Uptime
	echo -e "######## Uptime: ######## \n" >> "$DIR/$FILE"
	uptime >> "$DIR/$FILE"
	echo -e "\n" >> "$DIR/$FILE"

	# Current Disk Usage
	echo -e "######## Current Disk Usage (df -h): ######## \n" >> "$DIR/$FILE"
	df -h >> "$DIR/$FILE"
	echo -e "\n" >> "$DIR/$FILE"

	# Free Memory (Mb)
	echo -e "######## Free Memory (Mb): ######## \n" >> "$DIR/$FILE"
	free -k >> "$DIR/$FILE"
	echo -e "\n" >> "$DIR/$FILE"

	# CPU top 20
	echo -e "######## CPU top 20 ######## \n" >> "$DIR/$FILE"
        top -bcn1 | head -n 26 >> "$DIR/$FILE"
	echo -e "\n" >> "$DIR/$FILE"

	# Memory top 20
	echo -e "######## Mem top 20 ######## \n" >> "$DIR/$FILE"
        top -bmcn1 | head -n 26 >> "$DIR/$FILE"
	echo " " >> "$DIR/$FILE"

	# -- NOTE:  WHM/cPanel Only by default (requires sar) ---


	# Historical CPU Usage
	echo -e "######## Historical CPU Usage (sar -p): ######## \n" >> "$DIR/$FILE"
	sar -p >> "$DIR/$FILE"
	echo " " >> "$DIR/$FILE"

	# Historical Memory Usage
	# Note - should be -S on newer versions of sar.  At the moment WHM/cPanel seems to be running sar V9.0.4
	echo -e "######## Historical Memory Usage (sar -r): ######## \n" >> "$DIR/$FILE"
	sar -r >> "$DIR/$FILE"
	echo " " >> "$DIR/$FILE"

	# Historical Disk IO
	echo -e "######## Historical Disk I/O Usage (sar -d): ######## \n" >> "$DIR/$FILE"
	sar -d >> "$DIR/$FILE"
	echo " " >> "$DIR/$FILE"

	# Iostat – Input/Output Statistics
	echo -e "######## Iostat – Input/Output Statistics (iostat): ######## \n" >> "$DIR/$FILE"
	iostat >> "$DIR/$FILE"
	echo " " >> "$DIR/$FILE"

	# Real time Disk I/O and processes
	echo -e "######## Real time Disk I/O and processes (iotop -n 1 -b): ######## \n" >> "$DIR/$FILE"
	iotop -n 1 -b >> "$DIR/$FILE"
	echo " " >> "$DIR/$FILE"

	# Sites with traffic in the last 60 seconds
	echo -e "######## Sites with traffic in the last 60 seconds: ######## \n" >> "$DIR/$FILE"
	find /usr/local/apache/domlogs/ -maxdepth 1 -type f -mmin -1 | egrep -v 'offset|_log$' >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"

	# -- End:  WHM/cPanel Only by default (requires sar) ---



	# MySQL
	echo -e "MySQL:------------------------------------------------------------ \n\n" >> "$DIR/$FILE"
	mysqladmin stat >> "$DIR/$FILE"
	mysqladmin proc >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"

	# MySQL Tuner
	echo -e "MySQL Tuner Output:------------------------------------------------------------ \n\n" >> "$DIR/$FILE"
	$PERL "$MYSQL_TUNER" >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"

	# Apache
	echo -e "Apache Full Status------------------------------------------------ \n\n" >> "$DIR/$FILE"
	/sbin/service httpd fullstatus >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"

	# Network
	echo -e "Number of HTTP connections by connecting ip address ----- \n\n" >> "$DIR/$FILE"
	netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"
	
	echo -e "Total number of HTTP connections ---------------------- \n\n" >> "$DIR/$FILE"
	netstat -an | grep :80 | wc -l >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"

	# Check this line - not sure if it's correct as no field 4 for cut. Counting blank lines?
	# netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f4 | sort | uniq -c | sort -nr | head >> "$DIR/$FILE"

	echo -e "Network Connection States ---------------------- \n\n" >> "$DIR/$FILE"
	netstat -ant | awk '{print $6}' | sort | uniq -c | sort -n >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"

	echo -e "Statistics for All Ports ---------------------- \n\n" >> "$DIR/$FILE"
	netstat -s >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"
	
	echo -e "ifconfig (ethernet setup) ----- \n\n" >> "$DIR/$FILE"
	ifconfig >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"
	
	# Socket Information
	echo -e "Socket Information ----- \n\n" >> "$DIR/$FILE"
	ss -s >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"

	# Network Interface Statistics
	echo -e "Network Interface Statistics ----- \n\n" >> "$DIR/$FILE"
	ip -s link >> "$DIR/$FILE"
	echo -e "\n\n" >> "$DIR/$FILE"

	
	# Email
	echo -e "Email--------------------------------------------------------------- \n\n" >> "$DIR/$FILE"
	
		# EXIMQUEUE=`exim -bpc`
		# echo "Exim Queue: $EXIMQUEUE " >> "$DIR/$FILE" 
		/usr/sbin/exiwhat >> "$DIR/$FILE"
		echo -e "\n\n" >> "$DIR/$FILE"

		# Count of the messages in the queue
		echo -e "Count of the messages in the queue ----- \n\n" >> "$DIR/$FILE"
		exim -bpc >> "$DIR/$FILE"
		echo -e "\n\n" >> "$DIR/$FILE"

		# Summary of messages in the queue (count, volume, oldest, newest, domain, and totals)
		echo -e "Summary of messages in the queue ----- \n\n" >> "$DIR/$FILE"
		exim -bp | exiqsumm >> "$DIR/$FILE"
		echo -e "\n\n" >> "$DIR/$FILE"
		
		# Exim's configuration settings
		echo -e "Exim's configuration settings ----- \n\n" >> "$DIR/$FILE"
		exim -bP >> "$DIR/$FILE"
		echo -e "\n\n" >> "$DIR/$FILE"

	# Process List
	echo -e "Processes------------------------------------------------------------ \n\n" >> "$DIR/$FILE"
	ps auxf >> "$DIR/$FILE"

 	# Email the notification + summary
	/bin/mail -s "$SUBJECT" "$EMAIL" < "$DIR/$FILE"

fi

# Clean up to remove files older than x days
find "$DIR"/loadwatch.* -mtime +$REMOVE -exec rm {} \;
