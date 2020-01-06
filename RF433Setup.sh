#!/bin/bash
#Abort installation if any of the commands fail
set -e

#Install wiringpi if not already installed and fetch the project from github
wiringpi_present=$(gpio -v > /dev/null 2>&1; echo $?)
if [[ $wiringpi_present -gt "1" ]]
then
	echo "Installing WiringPi."
	sudo apt-get install -y  wiringpi
	echo "WiringPi installed."
else
	echo "WiringPi is present. Continuing without adding."
fi

#Create the RFOutlet Directory
if [[ -d "/var/www/rfoutlet" ]]
then
	echo "/var/www/rfoutlet Directory exists. Skipping download."
else
	echo "Downloading RFOutlet source."
	git_present=$(git > /dev/null 2>&1; echo $?)
	if [[ $git_present -gt "1" ]]
	then
		echo "Installing Git."
		sudo apt-get install -y git
		echo "Git installed."
	else
		echo "Git is present. Continuing without adding."
	fi
	#Clone the RFOutlet from github
	sudo git clone git://github.com/timleland/rfoutlet.git /var/www/rfoutlet
	
	#Update the permissions
	sudo chown root.root /var/www/rfoutlet/codesend
	sudo chmod 755 /var/www/rfoutlet/codesend
	echo "Permission updated."
fi

#Run sniffer to read and save the codes
OnCodes=()
OffCodes=()
i=0
j=1
echo "Ensure PINs are connected in order { 5V | Empty | GPIO 27 | Ground } when the transmitter's non flat side is facing you."
sleep 1
cd ~
#Download the device.db file from github
wget https://raw.githubusercontent.com/piyushkumarjiit/HABridgeOnPi/master/device.db
#Add date to the file
printf -v date '%(%Y-%m-%d %H:%M:%S)T\n' -1 
echo $date >> CapturedCodes.txt
echo Point your remote towards the sensor and be ready.
echo Starting ON code capture >>  btnout.txt
while [ $i -lt 5 ]
do
  if [ $i -lt 4 ]
  then
	echo Press ON buton for $j
	#Outout saved to file
	echo ON Code captured for $j  >>  btnout.txt
	#Command that ensures unbufferd write that only captures the first line of output.
	onVal=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 | awk '/Received/ {print $2}')
	echo $onVal >> CapturedCodes.txt
	#Save in Array
	OnCodes[$i]=$onVal
	echo "Code captured."
	sed -i "s/<rfcodeon>/$onVal/" device.db
	echo "Code added to device.db"
	#Wait so that user is able to move to the next button
	sleep 3
	
	echo Press OFF buton for $j
	echo OFF Code captured for $j  >>  btnout.txt
	#Command that ensures unbufferd write that only captures the first line of output.
	offVal=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 | awk '/Received/ {print $2}')
	OffCodes[$i]=$offVal
	echo $offVal >> CapturedCodes.txt
	echo "Code captured."
	sed -i "s/<rfcodeoff>/$offVal/" device.db
	echo "Code added to device.db"
	sleep 3
	let i+=1
	let j+=1
  else
	#Different message and sleep setting for last code capture.
	echo Press ON buton for $j
	#Outout saved to file
	echo ON Code captured for $j  >>  btnout.txt
	#Command that ensures unbufferd write to file that only captures the first line of output.
	onVal=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 | awk '/Received/ {print $2}')
	$onVal >> CapturedCodes.txt
	#Save in Array
	OnCodes[$i]=$onVal
	echo $onVal >> CapturedCodes.txt
	echo "Code captured."
	sed -i "s/<rfcodeon>/$onVal/" device.db
	echo "Code added to device.db"
	#Wait so that user is able to move to the next button
	sleep 3
	
	echo Press OFF buton for $j
	echo OFF Code captured for $j  >>  btnout.txt
	#Command that ensures unbufferd write to file that only captures the first line of output.
	offVal=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 | awk '/Received/ {print $2}')
	$offVal >> CapturedCodes.txt
	#Save in Array
	OffCodes[$i]=$offVal
	echo $offVal >> CapturedCodes.txt
	echo "Code captured."
	sed -i "s/<rfcodeoff>/$offVal/" device.db
	echo "Code added to device.db"
	let i+=1
	let j+=1
  fi
done
echo "--------------------"

echo Captured codes saved in CapturedCodes.txt
sleep 1

#Testing Codes
echo "Ensure PINs are connected in order { GPIO17 | 5V | Ground } when the transmitter's non flat side is facing you."
sleep 2
echo "To test we will be tunring ON all switches and then turning them all OFF"
sleep 1
i=1
j=1
echo $date >> RFCommands.txt
echo ON commands >> RFCommands.txt
for n in "${OnCodes[@]}"
do
  echo Turning on $i
  #code=$( echo $n | awk '/Received/ {print $2}')
  code=$n
  /var/www/rfoutlet/codesend $code
  echo codesend $code >> RFCommands.txt
  let i+=1
  sleep 1
done
echo OFF commands >> RFCommands.txt
for n in "${OffCodes[@]}"
do
  echo Turning OFF $j
  #code=$( echo $n | awk '/Received/ {print $2}')
  code=$n
  /var/www/rfoutlet/codesend $code
  echo /var/www/rfoutlet/codesend $code >> RFCommands.txt
  let j+=1
  sleep 1
done

echo "RF433 related procesing done."
