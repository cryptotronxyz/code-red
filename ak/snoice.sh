#!/bin/bash
# For testing things and figuring out how they work
#
clear

function setup_environment() {
### add colors ###
lightred='\033[1;31m'  # light red
red='\033[0;31m'  # red
lightgreen='\033[1;32m'  # light green
green='\033[0;32m'  # green
lightblue='\033[1;34m'  # light blue
blue='\033[0;34m'  # blue
lightpurple='\033[1;35m'  # light purple
purple='\033[0;35m'  # purple
lightcyan='\033[1;36m'  # light cyan
cyan='\033[0;36m'  # cyan
lightgray='\033[0;37m'  # light gray
white='\033[1;37m'  # white
brown='\033[0;33m'  # brown
yellow='\033[1;33m'  # yellow
darkgray='\033[1;30m'  # dark gray
black='\033[0;30m'  # black
nocolor='\033[0m'    # no color

printf "${lightred}"
printf "${lightgreen}"
printf "${nocolor}"

# Set Vars
LOGFILE='/var/log/logjammin.log'
rm -rf /var/helium
mkdir /var/helium
}

function begin_log() {
# Create Log File and Begin
printf "${lightcyan}"
rm -rf $LOGFILE
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e " `date +%m.%d.%Y_%H:%M:%S` : SCRIPT STARTED SUCCESSFULLY " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e "---------- AKcryptoGUY's Testing Script ------------ " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- \n" | tee -a "$LOGFILE"
printf "${nocolor}"
# sleep 1
}

setup_environment
begin_log

# install packages over IP4
apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install figlet shellcheck

echo "/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getinfo"  | tee -a "$LOGFILE"

rm -rf /var/helium/getinfo_n1
touch /var/helium/getinfo_n1  | tee -a "$LOGFILE"
/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getinfo  | tee -a /var/helium/getinfo_n1


function get_genkeys() {
   # Create a file containing all the masternode genkeys you want
   echo -e "Saving genkey(s) to /var/helium/genkey1 \n"  | tee -a "$LOGFILE"
   touch /var/helium/genkey1  | tee -a "$LOGFILE"
   read -p "How many private keys would you like me to generate, boss?  " GENKEYS
   for ((i=1;i<=GENKEYS;i++)); 
   do 
      /usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf masternode genkey >> /var/helium/genkey1   | tee -a "$LOGFILE"
   done
   echo -e "This is the contents of your file /var/helium/genkey1:"
# cat will display the entire contents of a file
cat /var/helium/genkey1

PRIVKEY1=$(sed -n 1p /var/helium/genkey1)
PRIVKEY2=$(sed -n 2p /var/helium/genkey1)
PRIVKEY3=$(sed -n 3p /var/helium/genkey1)
PRIVKEY4=$(sed -n 4p /var/helium/genkey1)
PRIVKEY5=$(sed -n 5p /var/helium/genkey1)

	echo -e "\n"
	echo -e "First private key $PRIVKEY1"
	echo -e "Second private key $PRIVKEY2"
	echo -e "Third private key $PRIVKEY3"
	echo -e "Fourth private key $PRIVKEY4"
	echo -e "Fifth private key $PRIVKEY5"

 }

# echo "grep "blocks" /var/helium/getinfo_n1" 
BLOCKS=$(grep "blocks" /var/helium/getinfo_n1 | tr -dc '0-9')
BLOCKS2=$(grep "blocks" /var/helium/getinfo_n1 | sed 's/[^0-9]*//g')
echo -e "Masternode 1 is currently synced through block $BLOCKS.\n"


function sync_check() {
CNT=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblockcount`
# echo -e "CNT is set to $CNT"
HASH=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblockhash ${CNT}`
#echo -e "HASH is set to $HASH"
TIMELINE1=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblock ${HASH} | grep '"time"'`
TIMELINE=$(echo $TIMELINE1 | tr -dc '0-9')
BLOCKS=$(grep "blocks" /var/helium/getinfo_n1 | tr -dc '0-9')
# echo -e "TIMELINE is set to $TIMELINE"
LTRIMTIME=${TIMELINE#*time\" : }
# echo -e "LTRIMTIME is set to $LTRIMTIME"
NEWEST=${LTRIMTIME%%,*}
# echo -e "NEWEST is set to $NEWEST"
TIMEDIF=$(echo -e "$((`date +%s`-$NEWEST))")
echo -e "This masternode is $TIMEDIF seconds behind the latest block." 
   #check if current
   if (($TIMEDIF <= 60 && $TIMEDIF >= -60))
	then echo -e "The blockchain is almost certainly synced.\n"
	SYNCED="yes"
	else echo -e "That's the same as $(((`date +%s`-$NEWEST)/60)) minutes or $(((`date +%s`-$NEWEST)/3600)) hours behind.\n"
	SYNCED="no"
   fi	
}


function simple_timeloop() {
LOOPTIME=$((SECONDS+5))

while [ $SECONDS -lt $LOOPTIME ]; do
    echo -e "Time $SECONDS"
    sleep 1
    # Do what you want.
    :
done
echo -e "All done."
}


function check_blocksync() {
end=$((SECONDS+7200))

while [ $SECONDS -lt $end ]; do
    echo -e "Time $SECONDS"
    
	rm -rf /var/helium/getinfo_n1
	touch /var/helium/getinfo_n1
	/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getinfo  | tee -a /var/helium/getinfo_n1
    
    # if  masternode not running, echo masternode not running and break
    BLOCKS=$(grep "blocks" /var/helium/getinfo_n1 | tr -dc '0-9')
    echo -e "$BLOCKS is the current number of blocks"
    if [ $BLOCKS !> 1 ]; then echo "Masternode not syncing" ; break
    else sync_check
    fi
    
    if [ "$SYNCED" = "yes" ]; then echo "Masternode synced" ; break
    else echo -e "Still not synced; will check again in 5 seconds\n"
    sleep 5
    fi
done
echo -e "All done."
}



check_blocksync
#sync_check

echo -e "Log of events saved to: $LOGFILE \n"

