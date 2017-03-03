# Setup samba honeypots to detect ransomware activity
# Kuko Armas <kuko@canarytek.com>

# This should be a name that windows finds first
honey_folder="____Secret_Data____"
# Main honeypot file (it should be THE SAME as in fail2ban samba-filter)
honey_file="____HONEYPOT_DO_NOT_TOUCH.txt"
# Get shares path from samba config
shares=`testparm -s 2>/dev/null | grep path | awk '{ print $3}'`

for share in $shares; do
	echo "Seting honeypot in $share"
	mkdir -p "/$share/$honey_folder"
	# Copy files
	echo -e "\r\n**** PLEASE DO NOT TOUCH THIS FILE ****\r\n\r\nIt is here to detect suspicious ransomware activity. If you change it,\r\nyou will be blocked from the fileserver\r\n\r\nKind regards, your BOFH\r\n\r\n" > "/$share/$honey_folder/$honey_file" 
	# Everyone needs write permissions here...
	chmod -R 777 "/$share/$honey_folder"
done
