#!/bin/bash
# Created by:	Liquid Web
# Enhanced by:	Phill Coxon, Will Ashworth

# Config
FILE=loadwatch.`date +%F.%H.%M.%S`

# Loadwatch log directory
DIR=/root/loadwatch
COLUMNS=512
SUBJECT="Loadwatch notification for $HOSTNAME at ".`date +%F.%H.%M`
EMAILMESSAGE="/tmp/emailmessage.txt"

# Delete when "X" days old
DELETEWHEN="5"

# Notification Email Address
EMAIL="root@localhost"

# Load Threshold for doing a dump (4 is a good number to start with)
THRESH=4

# Pull load average, log
LOAD=`cat /proc/loadavg | awk '{print $1}' | awk -F '.' '{print $1}'`

# Trip (check whether or not to run it)
#if [ $LOAD -ge $THRESH ]
#then

	# Only log triggered loads. 
	echo `date +%F.%X` - Load: $LOAD >> $DIR/checklog
        echo -e "Loadwatch Threshhold: $THRESH, Current Load: $LOAD" >> $DIR/$FILE
        
        #log 
	echo -e "Loadwatch tripped, dumping info to $DIR/$FILE \n" >> $DIR/checklog
	echo -e "\nCurrent server time: " . `date +"%c"` >> $DIR/$FILE
	echo "LoadWatch on $HOSTNAME triggered. Please Check it out." > $EMAILMESSAGE

	#email (optional, set email address to customer and uncomment below lines)
	#/bin/mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE

	#summary
	echo -e "\nSummary------------------------------------------------------------\n\n" >> $DIR/$FILE
        NUMHTTPD=`ps aux|grep httpd|wc -l`
	echo "Number of HTTPD Processes: $NUMHTTPD" >> $DIR/$FILE
	HTTPDCPU=`ps aux|grep httpd|awk '{sum+=$3} END {print sum}'`
	echo "HTTPD CPU consumption: $HTTPDCPU %" >> $DIR/$FILE 
	HTTPDMEM=`ps aux|grep httpd|awk '{sum+=$6} END {print sum}'`
	HTTPDMEMMEG=$((HTTPDMEM/1024))
	echo "HTTPD memory consumption: $HTTPDMEM Kilobytes ($HTTPDMEMMEG Megabytes)" >> $DIR/$FILE
	NUMPROCS=`grep -c processor /proc/cpuinfo`
	echo "Number of CPU Cores: $NUMPROCS" >> $DIR/$FILE
	NUMPHP=`ps aux|grep php|wc -l`
	echo "Number of PHP Processes: $NUMPHP" >> $DIR/$FILE
	PHPCPU=`ps aux|grep php|awk '{sum+=$3} END {print sum}'`
	echo "PHP CPU consumption: $PHPCPU %" >> $DIR/$FILE
	PHPMEM=`ps aux|grep php|awk '{sum+=$6} END {print sum}'`
	PHPMEMMEG=$((PHPMEM/1024))
	echo "PHP memory consumption: $PHPMEM Kilobytes ($PHPMEMMEG Megabytes)" >> $DIR/$FILE
	MYSQLCPU=`top -n 1 -S -b -U mysql|tail -n 2|head -n 1|awk {'print $9'}`
	echo "MYSQL CPU consumption: $MYSQLCPU %" >> $DIR/$FILE
	MYSQLMEM=`top -n 1 -S -b -U mysql|tail -n 2|head -n 1|awk {'print $6'}`
	echo "MYSQL RAM consumption: $MYSQLMEM" >> $DIR/$FILE

	# Uptime
	echo -e "\n######## Uptime: ########\n" >> $DIR/$FILE
	uptime >> $DIR/$FILE

	# Current Disk Usage
	echo -e "######## Current Disk Usage (df -h): ########\n" >> $DIR/$FILE
	df -h >> $DIR/$FILE
	echo " " >> $DIR/$FILE

	# Free Memory (Mb)
	echo -e "\n######## Free Memory (Mb): ########\n" >> $DIR/$FILE
	free -m >> $DIR/$FILE
	echo " " >> $DIR/$FILE

	# CPU top 20
	echo -e '\n######## CPU top 20 ########\n' >> $DIR/$FILE
        top -bcn1 | head -n 26 >> $DIR/$FILE
	echo " " >> $DIR/$FILE

	# Memory top 20
	echo -e '\n######## Mem top 20 ########\n' >> $DIR/$FILE
        top -bmcn1 | head -n 26 >> $DIR/$FILE
	echo " " >> $DIR/$FILE

	# -- NOTE:  WHM/cPanel Only by default (requires sar) ---


	# Historical CPU Usage
	echo -e "######## Historical CPU Usage (sar -p): ########\n" >> $DIR/$FILE
	sar -p >> $DIR/$FILE
	echo " " >> $DIR/$FILE

	# Historical Memory Usage
	# Note - should be -S on newer versions of sar.  At the moment WHM/cPanel seems to be running sar V9.0.4
	echo -e "######## Historical Memory Usage (sar -r): ########\n" >> $DIR/$FILE
	sar -r >> $DIR/$FILE
	echo " " >> $DIR/$FILE

	# Historical Disk IO
	echo -e "######## Historical Disk I/O Usage (sar -d): ########\n" >> $DIR/$FILE
	sar -d >> $DIR/$FILE
	echo " " >> $DIR/$FILE

	# Sites with traffic in the last 60 seconds
	echo -e "######## Sites with traffic in the last 60 seconds: ########\n" >> $DIR/$FILE
	find /usr/local/apache/domlogs/ -maxdepth 1 -type f -mmin -1 | egrep -v 'offset|_log$' >> $DIR/$FILE

	# -- End:  WHM/cPanel Only by default (requires sar) ---


	# MySQL
	echo -e "\n\nMySQL:------------------------------------------------------------\n\n" >> $DIR/$FILE
	mysqladmin stat >> $DIR/$FILE
	mysqladmin proc >> $DIR/$FILE

	# Apache
	echo -e "\n\nApache Full Status------------------------------------------------\n\n" >> $DIR/$FILE
	/sbin/service httpd fullstatus >> $DIR/$FILE

	# Network
	echo -e "\n\nNetwork------------------------------------------------------------\n\n" >> $DIR/$FILE
	netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head >> $DIR/$FILE
	echo -e "\n\nNetwork 2----------------------------------------------------------\n\n" >> $DIR/$FILE
	netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f4 | sort | uniq -c | sort -nr | head >> $DIR/$FILE

	# Email
	echo -e "\n\nEmail------------------------------------------------------------\n\n" >> $DIR/$FILE
	#EXIMQUEUE=`exim -bpc`
	#echo "Exim Queue: $EXIMQUEUE " >> $DIR/$FILE 
	/usr/sbin/exiwhat >> $DIR/$FILE

	# Process List
	echo -e "\n\nProcesses------------------------------------------------------------\n\n" >> $DIR/$FILE
	ps auxf >> $DIR/$FILE

 	# Email the notification + summary
    /bin/mail -s "$SUBJECT" "$EMAIL" < $DIR/$FILE

#fi

# Clean up to remove files older than x days
find $DIR/loadwatch.* -mtime +$DELETEWHEN -exec rm {} \;