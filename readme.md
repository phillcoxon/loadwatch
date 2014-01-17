#LoadWatch 

### Email notification + diagnostics emailed when a preset server load is triggerd.  

* loadwatch.sh - for WHM/cPanel servers running on Centos
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
Copy and paste the contents of loadwatch.sh into vim and save. 

**Using git:**

```
cd /root
git clone https://github.com/getresults/loadwatch.git
cd loadwatch/bin
chmod 700 loadwatch.sh
```
Rename loadwatch_ubuntu.sh to loadwatch.sh if on an Ubuntu based server

### Configure

Edit loadwatch.sh and set the LOAD level and EMAIL address you want to use for notifications.

For a single CPU server using '4' for the load level is fairly typical. 


### Set up Cron

Next, edit your crontab and insert the entry below which will run loadwatch.sh every 3 minutes to check server load and generate a report of the load is over the set threshold.

```
crontab -e  

*/3 * * * * /root/loadwatch/bin/loadwatch.sh > /dev/null 2>&1
```

Make sure the loadwatch script is set to 700 permissions. 


### Todo

* Output error if no EMAIL is specified
* Add nginx / typical ubuntu email agent debug info to loadwatch_ubuntu.sh
* Add brief info paragraphs to each section of the report so that users have a better idea of what is being displayed.
* Look for ways to expand the script to provide more relevant info


### Acknowledgements

* An awesome LiquidWeb.com staff member who gave me a copy of the base script.