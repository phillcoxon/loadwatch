#LoadWatch 

### Email notification + diagnostics emailed when a preset server load is triggerd.  

* loadwatch_cpanel.sh - for WHM/cPanel servers running on Centos
* loadwatch_ubuntu.sh - ubuntu servers running nginx


### Install

**To install loadwatch.sh manually:** 

```
mkdir /root/loadwatch
mkdir /root/loadwatch/bin/
touch /root/loadwatch/bin/loadwatch.sh
chmod 700 /root/loadwatch/bin/loadwatch.sh
vim /root/loadwatch/bin/loadwatch.sh    
```
Copy and paste the contents of the correct loadwatch.sh into vim and save. 

**Using git:**

```
cd /root
git clone https://github.com/getresults/loadwatch.git
cd loadwatch/bin
cp loadwatch_cpanel.sh loadwatch.sh
chmod 700 loadwatch.sh
```
Copy loadwatch_ubuntu.sh to loadwatch.sh if on an Ubuntu based server

### Configure

Edit loadwatch.sh and set the LOAD level and EMAIL address you want to use for notifications.

For a single CPU server using '4' for the load level is fairly typical. 


### Set up Cron

Next, edit your crontab and insert the entry below which will run loadwatch.sh every 20 minutes to check server load and generate a report of the load is over the set threshold.

```
crontab -e  

*/3 * * * * /root/loadwatch/bin/loadwatch.sh > /dev/null 2>&1
```

Make sure the loadwatch script is set to 700 permissions. 

### Warning

Log files are not deleted or trimmed currently and will continue growing over time.  


### Acknowledgements

* An awesome LiquidWeb.com staff member who gave me a copy of the base script.


### Disclaimer

* Use at your own risk - no warranty or support is provided. 

### Todo

* Output error if no EMAIL is specified
* Automatic deletion of log files in /root/loadwatch after 30 days?
	* Test :  find . -name "loadwatch-log*" -type f -mtime +30 -delete
	* How? :  limit checklog to 1000 lines? Size check, head -1000 to new file, replace old file?
* Add nginx / typical ubuntu email agent debug info to loadwatch_ubuntu.sh
* Add brief info paragraphs to each section of the report so that users have a better idea of what is being displayed.
* Look for ways to expand the script to provide more relevant info
	* Here: http://forums.cpanel.net/f34/troubleshooting-high-server-loads-linux-servers-319352.html 
	* Notes stored under 'Server' in Evernote

