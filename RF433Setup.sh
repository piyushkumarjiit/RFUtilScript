#!/bin/bash
#Abort installation if any of the commands fail
set -e

#Used existing codes
USE_EXISTING_CODES="true"

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
	#Delete files no longer needed
	sudo rm /var/www/rfoutlet/index.html
	sudo rm /var/www/rfoutlet/script.js
	sudo rm /var/www/rfoutlet/toggle.php
	sudo rm /var/www/rfoutlet/README.md
fi

#Run sniffer to read and save the codes
OnCodes=()
OffCodes=()
arr_index=0
button_count=1
echo "Ensure PINs are connected in order { 5V | Empty | GPIO 27 | Ground } when the transmitter's non flat side is facing you."
sleep 1
cd ~
echo "Current Directory: " $(pwd)
#Download the device.db file from github
wget https://raw.githubusercontent.com/piyushkumarjiit/HABridgeOnPi/master/device.db
echo "device.db file downloaded."
echo "Home Directory: " $Home
#wget -P $home https://raw.githubusercontent.com/piyushkumarjiit/HABridgeOnPi/master/device.db

#Does user want to reuse existing code values
if [[ $USE_EXISTING_CODES == "true" ]]
then
	#statements
	echo "Checking current directory for ExistingCodes.txt"
	while read line
	do
		if [[ $arr_index -lt 6 ]]
	  	then
			echo "$line" | awk '{print $NF}' | grep -E -o '^[0-9]{7}\b'
			onVal=$(echo "$line" | awk '{print $NF}' | grep -E -o '^[0-9]{7}\b')
			OnCodes[$arr_index]=$onVal
			let arr_index+=1
		else
			echo "$line" | awk '{print $NF}' | grep -E -o '^[0-9]{7}\b'
			offVal=$(echo "$line" | awk '{print $NF}' | grep -E -o '^[0-9]{7}\b')
			OffCodes[$arr_index]=$offVal
			let arr_index+=1
		fi
	done < ExistingCodes.txt
else
	echo "User selected to scan codes."

	#Add date to the file
	printf -v date '%(%Y-%m-%d %H:%M:%S)T\n' -1
	echo "Codes captured on: " $date > CapturedCodes.txt
	echo Point your remote towards the sensor and be ready.
	echo "--------------------"

	while [[ $arr_index -lt 5 ]]
	do
	  if [[ $arr_index -lt 4 ]]
	  then
		echo Press ON buton for $button_count
		#Command that ensures unbufferd write that only captures the first line of output.
		onVal=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 | awk '/Received/ {print $2}')
		#Save in Array
		OnCodes[$arr_index]=$onVal
		#Outout saved to file
		echo "On code for button "$button_count ": " $onVal >> CapturedCodes.txt
		echo "Code captured."
		sed -i "s/<rfcodeon>/$onVal/" device.db
		echo "Code added to device.db"
		#Wait so that user is able to move to the next button
		sleep 3
		
		echo Press OFF buton for $button_count
		#Command that ensures unbufferd write that only captures the first line of output.
		offVal=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 | awk '/Received/ {print $2}')
		OffCodes[$arr_index]=$offVal
		#Outout saved to file
		echo "Off code for button "$button_count ": " $offVal >> CapturedCodes.txt
		echo "Code captured."
		sed -i "s/<rfcodeoff>/$offVal/" device.db
		echo "Code added to device.db"
		sleep 3
		let arr_index+=1
		let button_count+=1
	  else
		#Different message and sleep setting for last code capture.
		echo Press ON buton for $button_count
		#Command that ensures unbufferd write to file that only captures the first line of output.
		onVal=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 | awk '/Received/ {print $2}')
		#Save in Array
		OnCodes[$arr_index]=$onVal
		#Outout saved to file
		echo "On code for button "$button_count ": " $onVal >> CapturedCodes.txt
		echo "Code captured."
		sed -i "s/<rfcodeon>/$onVal/" device.db
		echo "Code added to device.db"
		#Wait so that user is able to move to the next button
		sleep 3
		
		echo Press OFF buton for $button_count
		#Command that ensures unbufferd write to file that only captures the first line of output.
		offVal=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 | awk '/Received/ {print $2}')
		#Save in Array
		OffCodes[$arr_index]=$offVal
		#Outout saved to file
		echo "Off code for button "$button_count ": " $offVal >> CapturedCodes.txt
		echo "Code captured."
		sed -i "s/<rfcodeoff>/$offVal/" device.db
		echo "Code added to device.db"
		let arr_index+=1
		let button_count+=1
	  fi
	done
	echo "--------------------"

	echo Captured codes saved in CapturedCodes.txt
	sleep 1

fi

#Testing Codes
echo "Ensure PINs are connected in order { GPIO17 | 5V | Ground } when the transmitter's non flat side is facing you."
sleep 2
echo "To test we will be turning ON all switches and then turning them all OFF"
sleep 1

button_count=1
echo "Commands added on: "$date >> RFCommands.txt
echo ON commands >> RFCommands.txt
for n in "${OnCodes[@]}"
do
  echo Turning on $button_count
  code=$n
  /var/www/rfoutlet/codesend $code
  echo /var/www/rfoutlet/codesend $code >> RFCommands.txt
  let button_count+=1
  sleep 1
done
button_count=1
echo OFF commands >> RFCommands.txt
for n in "${OffCodes[@]}"
do
  echo Turning OFF $button_count
  code=$n
  /var/www/rfoutlet/codesend $code
  echo /var/www/rfoutlet/codesend $code >> RFCommands.txt
  let button_count+=1
  sleep 1
done

echo "RF433 related procesing done."
