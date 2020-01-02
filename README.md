# RFUtilScript
Automated script to configure RF433 outlets

This script combines and streamlines the installation/configuration of RF433 utilities on Raspberry Pi.
It uses the WiringPi and RFOutlet (courtsey: https://github.com/timleland/rfoutlet/tree/master/RFSource) to control RF 433 outlets.
I have tested them out on ETeckCity outlets and it should work on other 433s without issues.

Download the script using command wget https://raw.githubusercontent.com/piyushkumarjiit/HABridgeOnPi/master/HaBridgeOnPi.sh
update permissions using chmod 755 HaBridgeOnPi.sh
run the script ./RFCodeSniffer.sh | tee RFCodeSniffer.log
